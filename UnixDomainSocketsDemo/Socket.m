#import <sys/un.h>
#import <sys/socket.h>
#import "Common.h"

#pragma mark Socket Superclass:

@implementation CommSocket
@synthesize sockConnected;
@synthesize sockRef, sockURL;

- (NSString*)description {
    return [[NSString alloc] initWithFormat:
            @"ptr=%p  isSockRefValid=%hhd  isSockConnected=%hhd\n"
            @"   sockRef = %p\n"
            @"   sockUrl = %@\n"
            @"   sockAddress = %@\n"
            @"   sockLastError = %@\n",
            self,
            self.isSockRefValid,
            self.isSockConnected,
            self.sockRef,
            self.sockURL,
            self.sockAddress,
            self.sockLastError];
}

- (BOOL) isSockRefValid {
    if ( self.sockRef == nil ) return NO;
    return (BOOL)CFSocketIsValid( self.sockRef );
}

- (NSData *) sockAddress {

    struct sockaddr_un address;
    address.sun_family = AF_UNIX;
    strcpy( address.sun_path, [[self.sockURL path] fileSystemRepresentation] );
    address.sun_len = SUN_LEN( &address );
    return [NSData dataWithBytes:&address length:sizeof(struct sockaddr_un)];
}

- (NSString *) sockLastError {
    return [NSString stringWithFormat:@"%s (%d)", strerror( errno ), errno ];
}

+ (NSURL*) serviceUrl {
    NSString* path = [NSHomeDirectory() stringByAppendingPathComponent:@"UDSDService.socket"];
    return [NSURL fileURLWithPath:path];
}

@end

