import Foundation

class Logger : ObservableObject {    
    @Published var log: String = ""
    
    /* our singleton */
    static let shared = Logger()
    
    init() {
        self.log("Greetings from a new Logger")
    }

    func log(_ newEntry: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS "
        self.log = self.log + "\n" + dateFormatter.string(from: Date()) + newEntry
    }
    
    func logError(_ error: Error) {
        if let error = error as? UDSocket.UDSErr {
            self.log("ERROR: " + String(describing: error.kind) + "\n"
            + "    " +  error.localizedDescription)
        } else {
            self.log("FOREIGN ERROR: \(String(describing: error))")
        }

    }

}
