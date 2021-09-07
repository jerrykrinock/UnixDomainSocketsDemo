import Foundation

/**  This callback is only received when a client requests to open a
 connection; that is, only once in the life cycle of a client.  Later, when
 this client requests actual service, the *connected client* object in the
 server will receive the callback. */
func SocketServerCallback(
    _ sock: CFSocket?,
    _ type: CFSocketCallBackType,
    _ address: CFData?,
    _ data: UnsafeRawPointer?,
    _ info: UnsafeMutableRawPointer?) {
    if let info = info {
        let server = unsafeBitCast(info, to:UDSServer.self)
        
        if type == .acceptCallBack {
            if let data = data {
                /* The CFSocketNativeHandle type is an int, which is an Int32
                 on a 64-bit macOS.  For further reading:
                 https://www.wwdcnotes.com/notes/wwdc20/10167/ */
                let handle = CFSocketNativeHandle(data.load(as: Int32.self))
                server.addConnectedClient(handle: handle)
            } else {
                /* This never happens when running demo. */
            }
        } else {
            /* This never happens when running demo. */
        }
    } else {
        /* This never happens when running demo. */
    }
}


protocol UDSServerDelegate: AnyObject {
    func handleSocketServerStopped(_ server: UDSServer?)
    func handleSocketServerMsgDict(
        _ aDict: [AnyHashable : AnyHashable]?,
        from client: UDSClient?,
        error: Error?)
    func handleConnectionError(_ error: Error?)
}

class UDSServer : UDSocket, UDSClientDelegate {
    enum Status {
        case unknown
        case running
        case stopped
        case starting
        case stopping
    }
    
    var sockStatus: UDSServer.Status = .unknown
    @Published var sockClients = Set<UDSClient>() // empty set
    var delegate: UDSServerDelegate? = nil

    func socketServerCreate() throws -> Void {
        if (self.sockRef != nil) {
            throw Self.UDSErr(kind: .socketAlreadyCreated)
        }
        
        let sock = socket( AF_UNIX, SOCK_STREAM, 0 )
        
        establishBufferSize(sock: sock)

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

    func disconnectClients() -> Void {
        self.sockClients.forEach { client in
            self.disconnectClient(client)
        }
    }
    
    func disconnectClient(_ client: UDSClient?) -> Void {
        objc_sync_enter(self) // Someday, use Swift 5.5 concurrency instead
        if let client = client {
            self.sockClients.remove(client)
            client.stop()
        }
        objc_sync_exit(self) // Someday, use Swift 5.5 concurrency instead
    }
    
    func addConnectedClient(handle: CFSocketNativeHandle) -> Void {
        objc_sync_enter(self) // Someday, use Swift 5.5 concurrency instead
        do {
            if let client = try UDSClient(handle: handle) {
                client.delegate = self
                client.establishBufferSize(sock: handle)
                
                if ( client.isSockConnected() ) {
                    self.sockClients.insert(client)
                }
            }
        } catch {
            self.delegate?.handleConnectionError(error)
        }
        objc_sync_exit(self) // Someday, use Swift 5.5 concurrency instead
    }
    
    func handleSocketClientDisconnect(_ client: UDSClient?) {
        self.disconnectClient(client)
    }
    
    func handleSocketServerDisconnect(_ client: UDSClient?) {
        /* Just needed to conform to protocol.  This may happen if the
         client process terminates.  It never happens when running the demo
         app. */
    }
    
    func handleSocketClientMsgDict(
        _ aDict: [AnyHashable : AnyHashable]?,
        client: UDSClient?,
        error: Error?
    ) {
        self.delegate?.handleSocketServerMsgDict(
            aDict,
            from: client,
            error: error
        )
    }

    func start() throws -> Void {
        if (self.sockStatus == .running) {
            return
        }
        self.sockStatus = .starting
        
        do {
            try self.socketServerCreate()
        } catch {
            throw Self.UDSErr(kind: .nested(
                identifier: "strtSrvr-create",
                underlying: error))
        }
        
        do {
            try self.socketServerBind()
        } catch {
            throw Self.UDSErr(kind: .nested(
                identifier: "strtSrvr-bind",
                underlying: error))
        }

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

    func isSockConnected() -> Bool {
        return ((self.sockStatus == .running) && self.isSockRefValid())
    }

    init?(socketUrl: NSURL) {
        super.init()
        
        self.sockUrl = socketUrl
        self.sockStatus = .stopped
        self.sockClients = Set<UDSClient>() // empty set
    }
    
    deinit {
        self.stop()
    }
}
