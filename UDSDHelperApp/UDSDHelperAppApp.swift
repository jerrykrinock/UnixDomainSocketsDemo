import SwiftUI

@main
struct UDSDHelperApp: App {
    var server: CommSocketServer? = nil
    var producer: Producer? = nil

    init() {
        self.server = CommSocketServer(socketUrl: CommSocket.serviceUrl())
        self.server?.start()
        self.producer = Producer()
        self.server?.delegate = producer
    }

    var body: some Scene {
        WindowGroup {
            HelperAppContentView(server: self.server!)
        }
    }
    
}
