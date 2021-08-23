import Foundation

class Logger : ObservableObject, CommSocketServerDelegate {
    func handleSocketServerStopped(_ server: CommSocketServer?) {
        self.log("Whoops server stopped")
    }
    
    func handleSocketServerMsgDict(
        _ aDict: [AnyHashable : Any]?,
        from client: CommSocketClient?,
        error: Error?) {
        if let dict = aDict {
            self.log("Got message: \(dict)")
        }
        if let error = error {
            self.log("Got error: \(error)")
        }
    }
    
    @Published var log: String = "Beginning new log"
    
    static let shared = Logger()

    func registerError(_ error: CommSocket.UDSErr) {
        self.log("ERROR: " + String(describing: error.kind) + "\n"
        + "    " +  error.localizedDescription)
    }
    
    func log(_ newEntry: String) {
        self.log = self.log + "\n" + newEntry
    }
}
