#import "AppDelegate.h"
#import "Common.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@property (strong) CommSocketClient* outboundSocket;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.outboundSocket = [CommSocketClient initAndStartClient:[CommSocket toHelperUrl]];
    /*SSYDBL*/ NSLog(@"Main created client: %@", self.outboundSocket);
    self.outboundSocket.delegate = self;
    
    NSError* error = nil;
    BOOL ok = [self.outboundSocket sendMessageDict:@{@"Bone":@"Head2"}
                                           error_p:&error];
    NSLog(@"Sent message ok=%hhd error = %@", ok, error);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
