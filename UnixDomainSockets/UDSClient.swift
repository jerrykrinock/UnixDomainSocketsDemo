import Foundation

extension Data {
    mutating func append(data: Data, offset: Int, size: Int) {
        let safeSize = Swift.min(data.count - offset, size)
        let start = Int(data.startIndex) + Int(offset)
        let end = Int(start) + Int(safeSize)
        self.append(data[start..<end])
    }
}

func SocketClientCallback(
    _ sock: CFSocket?,
    _ type: CFSocketCallBackType,
    _ address: CFData?,
    _ data: UnsafeRawPointer?,
    _ info: UnsafeMutableRawPointer?) {
    if let info = info {
        let client = unsafeBitCast(info, to:UDSClient.self)
        
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
                client.messageReceived(data: swiftData)
            case .connectCallBack:
                /* I have never seen this occur.  It does not occur when
                 running the demo app. */
                break
            case .acceptCallBack:
                /* I have never seen this occur.  It does not occur when
                 running the demo app. */
                break
            default:
                /* I have never seen this occur.  It does not occur when
                 running the demo app. */
                break
            }
        }
    }
}

protocol UDSClientDelegate: AnyObject {
    func handleSocketClientDisconnect(_ client: UDSClient?)
    func handleSocketServerDisconnect(_ client: UDSClient?)
    func handleSocketClientMsgDict(_ aDict: [AnyHashable : AnyHashable]?, client: UDSClient?, error: Error?)
}

class UDSClient : UDSocket, Hashable {
    enum Status {
        case unknown
        case linked
        case disconnected
        case linking
        case disconnecting
    }
        
    private var sockStatus: Status?
    private var dataReceiving: Data = Data()
    var timeout: CFTimeInterval = 5.0
    var delegate: UDSClientDelegate?
    
    /**  Code in the client process should call this initializer to create
     a client object.
     - parameter socketUrl: The URL of the target socket.
     */
    init(socketUrl: NSURL) {
        super.init()
        self.sockUrl = socketUrl
        self.sockStatus = .disconnected
    }
    
    /**  Code in the server process should call this initializer to create
     a "connected client" object when it receives the first job request from
     a client.
     - parameter handle: The handle (actually, an integer) identifying the
     client which is requesting a connection.
     */
    init?(handle: CFSocketNativeHandle) throws {
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
            throw UDSClient.UDSErr.init(kind: .nested(identifier: "UDSClient.init(handle:)", underlying: error))
        }
    }
    
    deinit {
        self.stop()
    }
    
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
    }
    
    func messageReceived(data:Data) -> Void {
        if (data.count > 0) {
            /* For explanation, see Note: Data Transmission Protocol */
            let moreChunksHeaderSize = Int(MemoryLayout<Int>.size)
            let moreChunksData = data.subdata(in: 0..<moreChunksHeaderSize)
            let moreChunksValue = moreChunksData.withUnsafeBytes {
                $0.load(as: Int.self)
            }
            let payloadData = data.subdata(in: moreChunksHeaderSize..<data.count)

            self.dataReceiving.append(payloadData)
            if (moreChunksValue == 0) {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: self.dataReceiving,
                                                                      options:JSONSerialization.ReadingOptions.init(rawValue: 0))
                    // Prepare for next message…
                    self.dataReceiving.removeAll()
                    
                    if let dict = jsonObject as? Dictionary<AnyHashable, AnyHashable> {
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
        } else {
            /* Oddly, I think, when the server stops or its host
             process terminates, the client receives a .dataCallback
             with 0 bytes of data; no other callback*/
            self.delegate?.handleSocketServerDisconnect(self)
            self.stop()
        }

    }
    
    private func chunksRequired(payloadSize: Int, payloadLimit: Int) -> Int {
        let answer = payloadSize / payloadLimit
        if (payloadSize % payloadLimit != 0) {
            return answer + 1
        } else {
            return answer
        }
    }
    
    func sendMessageData(data:Data) throws -> Void {
        if ( self.isSockConnected() ) {
            /* For explanation, see Note: Data Transmission Protocol */
            let payloadLimit = self.bufferSize - Int(MemoryLayout<Int>.size)
            var moreChunks = chunksRequired(payloadSize: data.count, payloadLimit: payloadLimit)
            var offset = Int(0)
            repeat {
                let payloadBytesInThisChunk = min(payloadLimit, data.count - offset)
                moreChunks -= 1
                var dataOut = Data(bytes: &moreChunks,
                                   count: MemoryLayout.size(ofValue: moreChunks))
                dataOut.append(
                    data: data,
                    offset: offset,
                    size: payloadBytesInThisChunk
                )
                offset += payloadBytesInThisChunk
                let socketErr = CFSocketSendData(self.sockRef,
                                                 nil,
                                                 dataOut as CFData,
                                                 self.timeout)
                switch socketErr {
                case .timeout:
                    let error = Self.UDSErr(kind: .sendDataTimeout)
                    throw error
                case .error:
                    let error = Self.UDSErr(kind: .sendDataUnspecifiedError)
                    throw error
                case .success:
                    break // do nothing
                @unknown default:
                    let error = Self.UDSErr(kind: .sendDataKnownUnknownError)
                    throw error
                }
            } while (moreChunks > 0)
        } else {
            let error = Self.UDSErr(kind: .socketNotConnected)
            throw error
        }
    }
    
    func sendMessageDict(_ dictionary: Dictionary<AnyHashable, AnyHashable>) throws -> Void {
        do {
            let data = try JSONSerialization.data(
                withJSONObject: dictionary,
                options: JSONSerialization.WritingOptions(rawValue: 0)
            )
            try self.sendMessageData(data: data)
        } catch {
            let error = Self.UDSErr(kind: .nested(
                identifier: #function,
                underlying: error))
            throw error
        }
    }
    
    func start() throws -> Void {
        if (self.sockStatus == .linked) {
            return
        }
        self.sockStatus = .linking
        
        let sock = socket(AF_UNIX, SOCK_STREAM, 0)
        
        if (sock == 0) {
            self.stop()
            throw Self.UDSErr(kind: .systemFailedToCreateSocket)
        }
        
        establishBufferSize(sock: sock)

        do {
            try self.socketClientCreate(sock: sock)
        } catch {
            self.stop()
            throw Self.UDSErr(kind: .nested(
                identifier: "startCl1",
                underlying: error
            ))
        }
        
        do {
            try self.socketClientConnect()
        } catch {
            self.stop()
            throw Self.UDSErr(kind: .nested(
                identifier: "startCl2",
                underlying: error
            ))
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
    
    // MARK: conform to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    // MARK: conform to Equatable
    static func == (lhs: UDSClient, rhs: UDSClient) -> Bool {
        return lhs === rhs
    }
    
}

/* Note: Data Transmission Protocol
 
 The size of a data message passed via Unix Domain Sockets is limited to the
 buffer size of that socket.  On my M1 Mac running macOS 10.12 beta, the
 default size is 8192 bytes.  To allow transmission of larger size data, in
 UDSClient.sendMessageData(data:), we partition the data into chunks  of
 appropriate size, each chunk beginning with an 8 byte header whose Int
 value indicates how many chunks remain after the current chunks (moreChunks).
 The receiver (in UDSClient.messageReceived(data:)) appends data into a mutable
 Data property (UDSClient.dataReceiving) until it receives a chunk whose
 moreChunks header value is 0. */
