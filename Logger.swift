import Foundation

class Logger : ObservableObject {    
    @Published var log: String = "¡Hola Mundo!"
    
    /* our singleton */
    static let shared = Logger()

    func log(_ newEntry: String) {
        self.log = self.log + "\n" + newEntry
    }
    
    func registerError(_ error: UDSocket.UDSErr) {
        self.log("ERROR: " + String(describing: error.kind) + "\n"
        + "    " +  error.localizedDescription)
    }

}
