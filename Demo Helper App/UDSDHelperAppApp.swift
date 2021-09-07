import SwiftUI

@main
struct UDSDHelperApp: App {
    var server: UDSServer? = nil
    var producer: Producer? = nil

    init() {
        self.server = UDSServer(socketUrl: UDSocket.serviceUrl())
        do {
            try self.server?.start()
        } catch {
            Logger.shared.logError(error)
        }
        if let server = self.server {
            Logger.shared.log("Started server with bufferSize \(server.bufferSize) bytes")
            self.producer = Producer()
            server.delegate = producer
        }
    }

    var body: some Scene {
        WindowGroup {
            HelperAppContentView(server: self.server!)
        }
    }
    
}
