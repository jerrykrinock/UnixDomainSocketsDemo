import Foundation

// MARK: Server Callback:

func SocketServerCallback(
    _ sock: CFSocket?,
    _ type: CFSocketCallBackType,
    _ address: CFData?,
    _ data: UnsafeRawPointer?,
    _ info: UnsafeMutableRawPointer?) {
    
    if let info = info {
        let server = unsafeBitCast(info, to:CommSocketServer.self)
        Logger.shared.log("Server received socket callback")
        
        if type == .acceptCallBack {
            Logger.shared.log("Type is .acceptCallBack")
            if let data = data {
                /* The CFSocketNativeHandle type is an int, which is an Int32
                 on a 64-bit macOS.  For further reading:
                 https://www.wwdcnotes.com/notes/wwdc20/10167/ */
                let handle = CFSocketNativeHandle(data.load(as: Int32.self))
                server.addConnectedClient(handle: handle)
            }
        }
    }
    Logger.shared.log("Server received socket callback but no server")
}


class CommSocketServer : CommSocket, CommSocketClientDelegate {
    enum Status {
        case unknown
        case running
        case stopped
        case starting
        case stopping
    }
    
    var sockStatus: CommSocketServer.Status = .unknown
    var sockClients = Set<CommSocketClient>() // empty set
    var delegate: CommSocketServerDelegate? = nil


    // MARK: Helper Methods:

    func socketServerCreate() throws -> Void {
        if (self.sockRef != nil) {
            throw Self.UDSErr(kind: .socketAlreadyCreated)
        }
        
        let sock = socket( AF_UNIX, SOCK_STREAM, 0 )
        var context = CFSocketContext(
            version: 0,
            info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let refSock = CFSocketCreateWithNative (
            nil,
            sock,
            UInt(CFSocketCallBackType.acceptCallBack.rawValue),
            SocketServerCallback,
            &context
        )
        
        if (refSock == nil) {
            throw Self.UDSErr(kind: .systemFailedToCreateSocket)
        }
        
        var opt = 1
        let socklen = UInt32(MemoryLayout<UInt32>.size)
        setsockopt(
            sock,
            SOL_SOCKET,
            SO_REUSEADDR,
            &opt,
            socklen
        )
        setsockopt(
            sock,
            SOL_SOCKET,
            SO_NOSIGPIPE,
            &opt,
            socklen
        )
        
        self.sockRef = refSock;
    }
    
    func socketServerBind() throws -> Void {        
        if (self.sockRef == nil) {
            throw Self.UDSErr(kind: .cannotConnectToNilSocket)
        }
        var path = [Int8](repeating: 0, count: Int(PATH_MAX))
        if let url = self.sockUrl {
            if (url.getFileSystemRepresentation(&path, maxLength: Int(PATH_MAX))) {
                unlink(path)
            }
        }
        
        if let sockAddress = self.sockAddress() {
            let success = CFSocketSetAddress(
                self.sockRef,
                sockAddress as CFData?
            )
            
            switch success {
            case .timeout:
                throw Self.UDSErr(kind: .setSockAddressTimedOut)
            case .success:
                break
            case .error:
                throw Self.UDSErr(kind: .setAddressUnspecifiedError)
            @unknown default:
                throw Self.UDSErr(kind: .setAddressKnownUnknownError)
            }
        } else {
            throw Self.UDSErr(kind: .cannotConnectToNilAddress)
        }
    }


    // MARK: Connected Clients:
    
    func disconnectClients() -> Void {
        self.sockClients.forEach { client in
            self.disconnectClient(client)
        }
    }
    
    func disconnectClient(_ client: CommSocketClient?) -> Void {
        objc_sync_enter(self) // Someday, use Swift 5.5 concurrency instead
        if let client = client {
            self.sockClients.remove(client)
            client.stop()
        }
        objc_sync_exit(self) // Someday, use Swift 5.5 concurrency instead
    }
    
    func addConnectedClient(handle: CFSocketNativeHandle) -> Void {
        objc_sync_enter(self) // Someday, use Swift 5.5 concurrency instead
        if let client = CommSocketClient(socket: handle) {
            client.delegate = self

            if ( client.isSockConnected() ) {
                self.sockClients.insert(client)
                Logger.shared.log("Added client \(client) Now have \(self.sockClients.count) clients")
            }
        }
        objc_sync_exit(self) // Someday, use Swift 5.5 concurrency instead
    }
    
    // MARK: Connected Client Protocols:

    func handleSocketClientDisconnect(_ client: CommSocketClient?) {
        self.disconnectClient(client)
    }
    
    func handleSocketClientMsgDict(
        _ aDict: [AnyHashable : Any]?,
        client: CommSocketClient?,
        error: Error?
    ) {
        self.delegate?.handleSocketServerMsgDict(
            aDict,
            from: client,
            error: error
        )
    }

    // MARK:  Start / Stop Server:
    
    func start() -> Void {
        Logger.shared.log("Attempting to start server")
        if (self.sockStatus == .running) {
            Logger.shared.log("Ooops, server is already started and running")
            return
        }
        self.sockStatus = .starting
        
        do {
            try self.socketServerCreate()
        } catch {
            Logger.shared.registerError(Self.UDSErr(kind: .nested(identifier: "strtSrvr-create",
                                  underlying: error)))
        }
        Logger.shared.log("Created server socket")

        do {
            try self.socketServerBind()
        } catch {
            Logger.shared.registerError(Self.UDSErr(kind: .nested(identifier: "strtSrvr-bind",
                                  underlying: error)))
        }
        Logger.shared.log("Bound server socket")

        let sourceRef = CFSocketCreateRunLoopSource(
            kCFAllocatorDefault,
            self.sockRef,
            0
        )
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            sourceRef,
            CFRunLoopMode.commonModes
        )
        self.sockRLSourceRef = sourceRef
        self.sockStatus = .running
        Logger.shared.log("Started server run loop")
    }

    func stop() -> Void {
        self.sockStatus = .stopping
        self.disconnectClients()
        if let sockRef = self.sockRef {
            CFSocketInvalidate(sockRef)
            self.sockRef = nil
        }

        var path = [Int8](repeating: 0, count: Int(PATH_MAX))
        if let url = self.sockUrl {
            if (url.getFileSystemRepresentation(&path, maxLength: Int(PATH_MAX))) {
                unlink(path)
            }
        }
        
        self.delegate?.handleSocketServerStopped(self)
        self.sockStatus = .stopped
    }

     // MARK: Server Validation:
    
    func isSockConnected() -> Bool {
        return ((self.sockStatus == .running) && self.isSockRefValid())
    }

    // MARK: Initialization:

    init?(socketUrl: NSURL) {
        super.init()
        
        self.sockUrl = socketUrl
        self.sockStatus = .stopped
        self.sockClients = Set<CommSocketClient>() // empty set
    }
    
    deinit {
        self.stop()
    }
}
