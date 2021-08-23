import SwiftUI

@main
struct UDSDMainApp: App {
    var client: UDClient? = nil
    var consumer: Consumer? = nil

    init() {
        self.client = UDClient(socketUrl: UDSocket.serviceUrl())
        self.consumer = Consumer()
        if let consumer = consumer {
            self.client?.delegate = consumer
        }
    }

    var body: some Scene {
        WindowGroup {
            MainAppContentView(client: self.client!)
        }
    }
    
}

func launchHelper () {
    let helperName = "UDSDHelperApp"
    let myUrl = Bundle.main.bundleURL
    let myDir = myUrl.deletingLastPathComponent()
    let dirs = [
        myDir.appendingPathComponent("Junk"),
        myDir.appendingPathComponent("Contents").appendingPathComponent("Helpers"),
        myDir
    ]
    var urls = dirs.map {
        $0.appendingPathComponent(helperName)
    }
    let urlFromBundleIdentifier = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.sheepsystems.UDSDHelperApp")
    // Can chain this optional?…
    if let urlFromBundleIdentifier = urlFromBundleIdentifier {
        urls.append(urlFromBundleIdentifier);
    }
    
    OtherApper.launchApp(urls: urls) { runningApp, error in
        if (runningApp != nil) {
            // TODO display in log
        }
        if (error != nil) {
            // TODO display in log
        }
    }
}

