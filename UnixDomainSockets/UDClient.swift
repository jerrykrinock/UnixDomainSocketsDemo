import Foundation

func SocketClientCallback(
    _ sock: CFSocket?,
    _ type: CFSocketCallBackType,
    _ address: CFData?,
    _ data: UnsafeRawPointer?,
    _ info: UnsafeMutableRawPointer?) {

    Logger.shared.log("Client has received callback")
    if let info = info {
        let client = unsafeBitCast(info, to:UDClient.self)
        
        /* From documentation of CFClientCallback:
         `data` is data appropriate for the callback type.
         • For a kCFSocketConnectCallBack that failed in the background, it is a pointer to an SInt32 error code.
         • For a kCFSocketAcceptCallBack, it is a pointer to a CFSocketNativeHandle.
         • For a kCFSocketDataCallBack, it is a CFData object containing the incoming data.
         • In all other cases, it is NULL.
         To handle this in Swift,  */
        if let data = data {
            switch type {
            case .dataCallBack:
                let cfData = unsafeBitCast(data, to: CFData.self)
                let nsData = cfData as NSData
                let swiftData = nsData as Data
                Logger.shared.log("Client callback has received a .dataCallback of \(swiftData.count) bytes")
                if (swiftData.count > 0) {
                    client.messageReceived(data: swiftData)
                } else {
                    client.stop()
                }
            case .connectCallBack:
                Logger.shared.log("Client callback has received a .connectCallback")
            case .acceptCallBack:
                Logger.shared.log("Client callback has received a .acceptCallback")
            default:
                Logger.shared.log("Client callback has received a unknown callback")
            }
        }
    }
}

protocol UDClientDelegate: AnyObject {
    func handleSocketClientDisconnect(_ client: UDClient?)
    func handleSocketClientMsgDict(_ aDict: [AnyHashable : Any]?, client: UDClient?, error: Error?)
}

class UDClient : UDSocket, Hashable {
    enum Status {
        case unknown
        case linked
        case disconnected
        case linking
        case disconnecting
    }
        
    private var sockStatus: Status?
    var timeout: CFTimeInterval = 5.0
    var delegate: UDClientDelegate?
    var junk: Any? = nil
    
    func socketClientCreate(sock: CFSocketNativeHandle) throws -> Void {
        
        if ( self.sockRef != nil ) {
            throw Self.UDSErr(kind: .cannotCreateSocketAlreadyExists)
        }
        
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
            UInt(CFSocketCallBackType.dataCallBack.rawValue),
            SocketClientCallback,
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
            SO_NOSIGPIPE,
            &opt,
            socklen
        )
        
        Logger.shared.log("Did create Client without throwing any error")
        self.sockRef = refSock;
    }
    
    func socketClientConnect() throws -> Void {
        if ( self.sockRef == nil ) {
            throw Self.UDSErr(kind: .cannotConnectToNilSocket)
        }
        if let sockAddressData = self.sockAddress() {
            let connectError = CFSocketConnectToAddress(
                self.sockRef,
                sockAddressData as CFData,
                self.timeout
            )
            switch connectError {
            case .timeout:
                throw Self.UDSErr(kind: .connectToAddressTimeout)
            case .error:
                throw Self.UDSErr(kind: .connectToAddressUnspecifiedError)
            case .success:
                break // do nothing
            @unknown default:
                throw Self.UDSErr(kind: .connectToAddressKnownUnknownError)
            }
        } else {
            throw Self.UDSErr(kind: .cannotConnectToNilAddress)
        }
        Logger.shared.log("Did connect Client without throwing any error")
    }
    
    func messageReceived(data:Data) -> Void {
        Logger.shared.log("Client has received message data: \(data)")
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data,
                                                            options:JSONSerialization.ReadingOptions.init(rawValue: 0))
            if let dict = jsonObject as? Dictionary<String, Any> {
                self.delegate?.handleSocketClientMsgDict(dict, client: self, error: nil)
            } else {
                let className = (jsonObject as AnyObject).className ?? "not an object"
                self.delegate?.handleSocketClientMsgDict(
                    nil,
                    client: self,
                    error: Self.UDSErr(kind:.receivedNonDictionary(typeReceived: className)))
            }
        } catch {
            self.delegate?.handleSocketClientMsgDict(
                nil,
                client: self,
                error: Self.UDSErr(kind: .nested(
                    identifier: #function,
                    underlying: error)
            ))
        }
    }
    
    func sendMessageData(data:Data) throws -> Void {
        if ( self.isSockConnected() ) {
            let socketErr = CFSocketSendData(self.sockRef,
                                             nil,
                                             data as CFData,
                                             self.timeout)
            switch socketErr {
            case .timeout:
                Logger.shared.log("Send data result: .timeout")
                throw Self.UDSErr(kind: .sendDataTimeout)
            case .error:
                Logger.shared.log("Send data result: .error")
                throw Self.UDSErr(kind: .sendDataUnspecifiedError)
            case .success:
                Logger.shared.log("Send data result: .success")
                break // do nothing
            @unknown default:
                Logger.shared.log("Send data result: ????")
                throw Self.UDSErr(kind: .sendDataKnownUnknownError)
            }
        } else {
            throw Self.UDSErr(kind: .socketNotConnected)
        }
    }
    
    func sendMessageDict(dictionary:Dictionary<String, String>) throws -> Void {
        do {
            let data = try JSONSerialization.data(
                withJSONObject: dictionary,
                options: JSONSerialization.WritingOptions(rawValue: 0)
            )
            try self.sendMessageData(data: data)
        } catch {
            throw Self.UDSErr(kind: .nested(
                identifier: #function,
                underlying: error))
        }
    }
    
    func start() -> Void {
        if (self.sockStatus == .linked) {
            return
        }
        self.sockStatus = .linking
        
        let sock = socket(AF_UNIX, SOCK_STREAM, 0)
        
        if (sock == 0) {
            self.stop()
            Logger.shared.registerError(Self.UDSErr(kind: .systemFailedToCreateSocket))
            return
        }
        
        do {
            try self.socketClientCreate(sock: sock)
        } catch {
            self.stop()
            Logger.shared.registerError(Self.UDSErr(kind: .nested(
                identifier: "startCl1",
                underlying: error
            )))
            return
        }
        
        do {
            try self.socketClientConnect()
        } catch {
            self.stop()
            Logger.shared.registerError(Self.UDSErr(kind: .nested(
                identifier: "startCl2",
                underlying: error
            )))
            return
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

        self.sockStatus = .linked
    }
    
    func stop() -> Void {
        self.sockStatus = .disconnecting
        
        if let sockRef = self.sockRef {
            if let sourceRef = self.sockRLSourceRef {
                CFRunLoopSourceInvalidate(sourceRef)
                self.sockRLSourceRef = nil
            }
            
            CFSocketInvalidate(sockRef)
            self.sockRef = nil;
        }
        
        self.delegate?.handleSocketClientDisconnect(self)
        self.sockStatus = .disconnected
    }
    
    func isSockConnected() -> Bool{
        return (self.sockStatus == .linked) && self.isSockRefValid()
    }
    
    init(socketUrl: NSURL) {
        super.init()
        self.sockUrl = socketUrl
        self.sockStatus = .disconnected
    }
    
    init?(socket handle: CFSocketNativeHandle) {
        super.init()
        self.sockStatus = .linking

        do {
            try socketClientCreate(sock: handle)
            let sourceRef = CFSocketCreateRunLoopSource(
                kCFAllocatorDefault,
                sockRef,
                CFIndex(0))
            CFRunLoopAddSource(
                CFRunLoopGetCurrent(),
                sourceRef,
                CFRunLoopMode.commonModes
            )
            
            self.sockRLSourceRef = sourceRef
            
            sockStatus = .linked
        } catch {
            self.stop()
            Logger.shared.log("Could not create socket \(error)")
        }
    }
    
    deinit {
        self.stop()
    }
    
    // MARK: conform to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    // MARK: conform to Equatable
    static func == (lhs: UDClient, rhs: UDClient) -> Bool {
        return lhs === rhs
    }
    
}
