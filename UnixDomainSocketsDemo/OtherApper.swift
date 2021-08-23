import Foundation
import AppKit  // Needed for NSWorkspace, NSRunningApplication

struct OtherApper {
    static func launchApp(urls: [URL]?,
                          thenDo: @escaping (_ runningApp: NSRunningApplication?, _ error: Error?) -> Void) -> Void {
        let handleHelperLaunch = {(runningApp: NSRunningApplication?, error: Error?) -> Void in
            thenDo(runningApp, error)
        }
        
        let url = urls?.first
        if (url != nil) {
            if (launchAppAtUrl(url, thenDo: handleHelperLaunch) == false) {
                var nextUrls = urls
                nextUrls?.remove(at: 0)
                launchApp(urls: nextUrls,
                          thenDo: thenDo)
            }
        } else {
            let error = DemoError(kind: .couldNotLaunchHelper)
            thenDo(nil, error)
        }
    }
    
    static func launchAppAtUrl(_ url: URL!,
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


