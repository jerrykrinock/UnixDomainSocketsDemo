import SwiftUI

@main
struct UDSDHelperApp: App {
    var server: CommSocketServer? = nil;  // stays nil in Main app

    init() {
        self.server = CommSocketServer(socketUrl: CommSocket.toHelperUrl())
        self.server?.start()
        self.server?.delegate = Logger.shared
    }

    var body: some Scene {
        WindowGroup {
            HelperAppContentView(server: self.server!)
        }
    }
    
}
