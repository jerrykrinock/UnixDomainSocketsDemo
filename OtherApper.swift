import Foundation
import AppKit  // Needed for NSWorkspace, NSRunningApplication

/**
 Some funcs for controlling other macOS apps
 */
struct OtherApper {
    struct OAError: Error {
        enum Kind {
            case triedAllUrlsButNoBundlesFound
        }
        
        let kind: Kind
    }

    /**
     Launches another app, specified by multiple URLs, then performs a closure.
     
     - parameter urls: Array of URLs which are tried in order given, until an
     existing bundle is found.  If a bundle exists at a tried URL but we cannot
     launch an app from there, this method terminates and returns the error to
     the thenDo: closure.
     - parameter thenDo: Closure which is always invoked even if failure occurs
     - returns:
     - throws:
     - requires: Swift 3.0
     */
    static func launchApp(urls: [URL]?,
                          thenDo: @escaping (_ runningApp: NSRunningApplication?, _ error: Error?) -> Void) -> Void {
        let handleLaunch = {(runningApp: NSRunningApplication?, error: Error?) -> Void in
            thenDo(runningApp, error)
        }
        
        let url = urls?.first
        if (url != nil) {
            if (launchAppAtUrl(url, thenDo: handleLaunch) == false) {
                var nextUrls = urls
                nextUrls?.remove(at: 0)
                launchApp(urls: nextUrls,
                          thenDo: thenDo)
            }
        } else {
            let error = OAError(kind: .triedAllUrlsButNoBundlesFound)
            thenDo(nil, error)
        }
    }
    
    private static func launchAppAtUrl(_ url: URL!,
                               thenDo: @escaping (_ runningApp: NSRunningApplication?, _ error: Error?) -> Void) -> Bool {
        let bundle = Bundle(url: url)
        let bundleExists = bundle != nil
        if bundleExists {
            NSWorkspace.shared.openApplication(at: url,
                                               configuration: NSWorkspace.OpenConfiguration.init()) { runningApp, error in
                thenDo(runningApp, error)
            }
            return true
        } else {
            return false
        }
    }

}


