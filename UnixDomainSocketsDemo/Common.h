#import <Foundation/Foundation.h>

typedef enum _CommSocketServerStatus {

    CommSocketServerStatusUnknown       = 0,
    CommSocketServerStatusRunning       = 1,
    CommSocketServerStatusStopped       = 2,
    CommSocketServerStatusStarting      = 3,
    CommSocketServerStatusStopping      = 4

} CommSocketServerStatus;

typedef enum _CommSocketClientStatus {

    CommSocketClientStatusUnknown       = 0,
    CommSocketClientStatusLinked        = 1,
    CommSocketClientStatusDisconnected  = 2,
    CommSocketClientStatusLinking       = 3,
    CommSocketClientStatusDisconnecting = 4

} CommSocketClientStatus;

@class CommSocketServer, CommSocketClient;

@protocol CommSocketServerDelegate <NSObject>
@optional
- (void) handleSocketServerStopped:(CommSocketServer *)server;
- (void) handleSocketServerMsgDict:(NSDictionary *)aDict fromClient:(CommSocketClient *)client error:(NSError *)error;
@end

@protocol CommSocketClientDelegate <NSObject>
@optional
- (void) handleSocketClientDisconnect:(CommSocketClient *)client;
- (void) handleSocketClientMsgDict:(NSDictionary *)aDict client:(CommSocketClient *)client error:(NSError*)error;
@end

@interface CommSocket : NSObject

@property (readonly, nonatomic, getter=isSockRefValid) BOOL sockRefValid;
@property (readonly, nonatomic, getter=isSockConnected) BOOL sockConnected;
@property (readwrite, nonatomic) CFSocketRef sockRef;
@property (readwrite, strong, nonatomic) NSURL    *sockURL;
@property (readonly, strong, nonatomic) NSData   *sockAddress;
@property (readonly, strong, nonatomic) NSString *sockLastError;

+ (NSURL*)serviceUrl;

@end

@interface CommSocketServer : CommSocket <CommSocketClientDelegate> { id <CommSocketServerDelegate> delegate; }
@property (readwrite, strong, nonatomic) id delegate;
@property (readonly,  strong, nonatomic) NSSet *sockClients;
@property (readonly, nonatomic) CommSocketServerStatus sockStatus;
@property (readonly, nonatomic) BOOL startServer;
@property (readonly, nonatomic) BOOL stopServer;
- (id) initWithSocketURL:(NSURL *)socketURL;
+ (id) initAndStartServer:(NSURL *)socketURL;
- (void) addConnectedClient:(CFSocketNativeHandle)handle;

@end

@interface CommSocketClient : CommSocket { id <CommSocketClientDelegate> delegate; }
@property (readwrite, strong, nonatomic) id delegate;
@property (readonly, nonatomic) CommSocketClientStatus sockStatus;
@property (readonly, nonatomic) CFRunLoopSourceRef sockRLSourceRef;
@property (readonly, nonatomic) BOOL startClient;
@property (readonly, nonatomic) BOOL stopClient;
- (id) initWithSocketURL:(NSURL *)socketURL;
- (id) initWithSocket:(CFSocketNativeHandle)handle;
+ (id) initAndStartClient:(NSURL *)socketURL;
+ (id) initWithSocket:(CFSocketNativeHandle)handle;
- (BOOL) sendMessageDict:(NSDictionary *)aDict
                 error_p:(NSError**)error_p;

- (void) messageReceived:(NSData *)data;

@end
