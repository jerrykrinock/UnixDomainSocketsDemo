import SwiftUI

@main
struct UDSDHelperApp: App {
    var server: UDServer? = nil
    var producer: Producer? = nil

    init() {
        self.server = UDServer(socketUrl: UDSocket.serviceUrl())
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
