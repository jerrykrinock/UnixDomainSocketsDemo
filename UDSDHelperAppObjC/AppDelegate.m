#import "AppDelegate.h"
#import "Common.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@property (strong) CommSocketClient* inboundSocket;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.inboundSocket = [CommSocketServer initAndStartServer:[CommSocket serviceUrl]];
    /*SSYDBL*/ NSLog(@"Helper created server:\n%@", self.inboundSocket);

    self.inboundSocket.delegate = self;
}

- (void) handleSocketServerMsgDict:(NSDictionary *)aDict
                        fromClient:(CommSocketClient *)client
                             error:(NSError *)error {
    NSLog(@"Got dict: %@\nerror: %@", aDict, error);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
