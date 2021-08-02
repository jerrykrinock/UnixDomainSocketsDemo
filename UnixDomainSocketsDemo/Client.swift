import Foundation

let kCommSocketClientTimeout: TimeInterval = 5.0

private func SocketClientCallback(_ sock: CFSocket?, _ type: CFSocketCallBackType, _ address: CFData?, _ data: UnsafeRawPointer?, _ info: UnsafeMutableRawPointer?) {
}

class CommSocketClient : CommSocket {
    enum Status {
        case unknown
        case linked
        case disconnected
        case linking
        case disconnecting
    }
    
    private var startClientCleanup = false
    private var sockStatus: Status?
    private var sockRLSourceRef: CFRunLoopSource?

// MARK: Helper Methods

func socketClientCreate(sock: CFSocketNativeHandle) -> Bool {

    if ( self.sockRef != nil ) {
        return false
    }
    
    let context = CFSocketContext(
        version: 0,
        info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
        retain: nil,
        release: nil,
        copyDescription: nil)

    // "extraneous argument labels" if I put "allocator:", "sock:", etc.
    let refSock = CFSocketCreateWithNative (
        nil,
        sock,
        UInt(CFSocketCallBackType.dataCallBack.rawValue),
        SocketClientCallback,
        unsafeBitCast(context,to: UnsafePointer.self)
    )

    if (refSock == nil) {
        return false
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

    return true
}

func socketClientBind() -> Bool {
    if ( self.sockRef == nil ) {
        return false
    }
    let success = CFSocketError.success
    if let sockAddressData = self.sockAddress {
        if ( CFSocketConnectToAddress(
            self.sockRef,
            sockAddressData as CFData,
            kCommSocketClientTimeout) != success ) {
            return false
        }
    } else {
        return false
    }
        return true
}

// MARK: Client Messaging:

func messageReceived(data:Data) -> Void {
    NSError* error = nil;
    id msg = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDictionary class]
                                               fromData:data
                                                  error:&error];

    if ( [msg isKindOfClass:[NSDictionary class]] ) {

        if ( [self.delegate respondsToSelector:@selector(handleSocketClientMsgDict:client:error:)] )
            [self.delegate handleSocketClientMsgDict:(NSDictionary *)msg client:self error:error];
    }
}

- (BOOL) sendMessageData:(NSData *)data {

    if ( self.isSockConnected ) {

        if ( kCFSocketSuccess == CFSocketSendData(self.sockRef,
                                                  nil,
                                                  (__bridge CFDataRef)data,
                                                  kCommSocketClientTimeout) )
            return YES;

    } return NO;
}

- (BOOL) sendMessageDict:(NSDictionary *)aDict
                 error_p:(NSError**)error_p {
    BOOL ok;
    NSError* error = nil;
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:aDict
                                         requiringSecureCoding:YES
                                                         error:&error];
    ok = ((data != nil) && (error == nil));
    if (ok) {
        ok = [self sendMessageData:data];
    }
    
    return ok;
}


#pragma mark - Start / Stop Client:

- (BOOL) startClientCleanup { [self stopClient]; return NO; }

- (BOOL) startClient {

    if ( self.sockStatus == CommSocketClientStatusLinked ) return YES;
    self.sockStatus = CommSocketClientStatusLinking;

    CFSocketNativeHandle sock = socket( AF_UNIX, SOCK_STREAM, 0 );
    if ( ![self socketClientCreate:sock] ) return self.startClientCleanup;
    if ( ![self socketClientBind]        ) return self.startClientCleanup;

    CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource( kCFAllocatorDefault, self.sockRef, 0 );
    CFRunLoopAddSource( CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes );

    self.sockRLSourceRef = sourceRef;
    CFRelease( sourceRef );

    self.sockStatus = CommSocketClientStatusLinked;
    return YES;
}

- (BOOL) stopClient {

    self.sockStatus = CommSocketClientStatusDisconnecting;

    if ( self.sockRef != nil ) {

        if ( self.sockRLSourceRef != nil ) {

            CFRunLoopSourceInvalidate( self.sockRLSourceRef );
            self.sockRLSourceRef = nil;
        }

        CFSocketInvalidate(self.sockRef);
        self.sockRef = nil;
    }

    if ( [self.delegate respondsToSelector:@selector(handleSocketClientDisconnect:)] )
        [self.delegate handleSocketClientDisconnect:self];

    self.sockStatus = CommSocketClientStatusDisconnected;

    return YES;
}

#pragma mark - Client Validation:

- (BOOL) isSockConnected {

    if ( self.sockStatus == CommSocketClientStatusLinked )
        return self.isSockRefValid;

    return NO;
}

#pragma mark - Initialization:

+ (id) initAndStartClient:(NSURL *)socketURL {

    CommSocketClient *client = [[CommSocketClient alloc] initWithSocketURL:socketURL];
    [client startClient];
    return client;
}

+ (id) initWithSocket:(CFSocketNativeHandle)handle {

    CommSocketClient *client = [[CommSocketClient alloc] initWithSocket:handle];
    return client;
}

- (id) initWithSocketURL:(NSURL *)socketURL {

    if ( (self = [super init]) ) {

        self.sockURL    = socketURL;
        self.sockStatus = CommSocketClientStatusDisconnected;

    } return self;
}

- (id) initWithSocket:(CFSocketNativeHandle)handle {

    if ( (self = [super init]) ) {

        self.sockStatus = CommSocketClientStatusLinking;

        if ( ![self socketClientCreate:handle] ) [self startClientCleanup];

        else {

            CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource( kCFAllocatorDefault, self.sockRef, 0 );
            CFRunLoopAddSource( CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes );

            self.sockRLSourceRef = sourceRef;
            CFRelease( sourceRef );

            self.sockStatus = CommSocketClientStatusLinked;
        }

    } return self;
}

- (void) dealloc { [self stopClient]; }

#pragma mark - Client Callback:

static void SocketClientCallback (CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {

    CommSocketClient *client = (__bridge CommSocketClient *)info;

    if ( kCFSocketDataCallBack == type ) {

        NSData *objData = (__bridge NSData *)data;

        if ( [objData length] == 0 )
            [client stopClient];

        else
            [client messageReceived:objData];
    }
}

@end
