import Foundation

class CommSocketServer {
    enum Status {
        case unknown
        case running
        case stopped
        case starting
        case stopping
    }
    
    var startServerCleanup: Bool
    @property (readwrite, nonatomic) CommSocketServerStatus sockStatus;
    @property (readwrite,  strong, nonatomic) NSSet *sockClients;
    static void SocketServerCallback (CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
    @end

    #pragma mark - Server Implementation:

    @implementation CommSocketServer

    @synthesize delegate;
    @synthesize sockStatus;
    @synthesize sockClients;

    #pragma mark - Helper Methods:

    - (BOOL) socketServerCreate {

        if ( self.sockRef != nil ) return NO;
        CFSocketNativeHandle sock = socket( AF_UNIX, SOCK_STREAM, 0 );
        CFSocketContext context = { 0, (__bridge void *)self, nil, nil, nil };
        CFSocketRef refSock = CFSocketCreateWithNative( nil, sock, kCFSocketAcceptCallBack, SocketServerCallback, &context );

        if ( refSock == nil ) return NO;

        int opt = 1;
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (void *)&opt, sizeof(opt));
        setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, (void *)&opt, sizeof(opt));

        self.sockRef = refSock;
        CFRelease( refSock );

        return YES;
    }

    - (BOOL) socketServerBind {
        if ( self.sockRef == nil ) return NO;
        unlink( [[self.sockURL path] fileSystemRepresentation] );
        if ( CFSocketSetAddress(self.sockRef, (__bridge CFDataRef)self.sockAddress) != kCFSocketSuccess ) return NO;
        return YES;
    }

    #pragma mark - Connected Clients:

    - (void) disconnectClients {


        for ( CommSocketClient *client in self.sockClients )
            [client stopClient];

        self.sockClients = [NSSet set];
    }

    - (void) disconnectClient:(CommSocketClient *)client {

        @synchronized( self ) {
            NSMutableSet *clients = [NSMutableSet setWithSet:self.sockClients];

            if ( [clients containsObject:client] ) {

                if ( client.isSockRefValid ) [client stopClient];
                [clients removeObject:client];
                self.sockClients = clients;
        } }
    }

    - (void) addConnectedClient:(CFSocketNativeHandle)handle {

        @synchronized( self ) {
            CommSocketClient *client = [CommSocketClient initWithSocket:handle];
            client.delegate = self;
            NSMutableSet *clients = [NSMutableSet setWithSet:self.sockClients];

            if ( client.isSockConnected ) {
                [clients addObject:client];
                self.sockClients = clients;
        } }
    }

    #pragma mark - Connected Client Protocols:

    - (void) handleSocketClientDisconnect:(CommSocketClient *)client {

        [self disconnectClient:client];
    }

    - (void) handleSocketClientMsgDict:(NSDictionary *)aDict client:(CommSocketClient *)client error:(NSError *)error {

        if ( [self.delegate respondsToSelector:@selector(handleSocketServerMsgDict:fromClient:error:)] )
            [self.delegate handleSocketServerMsgDict:aDict fromClient:client error:error];
    }

    #pragma mark - Connected Client Messaging:

    #pragma mark - Start / Stop Server:

    - (BOOL) startServerCleanup { [self stopServer]; return NO; }

    - (BOOL) startServer {

        if ( self.sockStatus == CommSocketServerStatusRunning ) {
            return YES;
        }
        
        self.sockStatus = CommSocketServerStatusStarting;

        if ( ![self socketServerCreate] ) {
            return self.startServerCleanup;
        }
        if ( ![self socketServerBind]   ) {
            return self.startServerCleanup;
        }

        CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource( kCFAllocatorDefault, self.sockRef, 0 );
        CFRunLoopAddSource( CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes );
        CFRelease( sourceRef );

        self.sockStatus = CommSocketServerStatusRunning;
        return YES;
    }

    - (BOOL) stopServer {

        self.sockStatus = CommSocketServerStatusStopping;

        [self disconnectClients];

        if ( self.sockRef != nil ) {

            CFSocketInvalidate(self.sockRef);
            self.sockRef = nil;
        }

        unlink( [[self.sockURL path] fileSystemRepresentation] );

        if ( [self.delegate respondsToSelector:@selector(handleSocketServerStopped:)] )
            [self.delegate handleSocketServerStopped:self];

        self.sockStatus = CommSocketServerStatusStopped;
        return YES;
    }

    #pragma mark - Server Validation:

    - (BOOL) isSockConnected {

        if ( self.sockStatus == CommSocketServerStatusRunning )
            return self.isSockRefValid;

        return NO;
    }

    #pragma mark - Initialization:

    + (id) initAndStartServer:(NSURL *)socketURL {

        CommSocketServer *server = [[CommSocketServer alloc] initWithSocketURL:socketURL];
        [server startServer];
        return server;
    }

    - (id) initWithSocketURL:(NSURL *)socketURL {

        if ( (self = [super init]) ) {

            self.sockURL     = socketURL;
            self.sockStatus  = CommSocketServerStatusStopped;
            self.sockClients = [NSSet set];

        } return self;
    }

    - (void) dealloc { [self stopServer]; }

    #pragma mark - Server Callback:

    static void SocketServerCallback (CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {

        CommSocketServer *server = (__bridge CommSocketServer *)info;

        if ( kCFSocketAcceptCallBack == type ) {
            CFSocketNativeHandle handle = *(CFSocketNativeHandle *)data;
            [server addConnectedClient:handle];
        }
    }

}
