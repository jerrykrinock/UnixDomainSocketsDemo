import Foundation

class Producer : UDServerDelegate {
    func handleSocketServerStopped(_ server: UDServer?) {
        Logger.shared.log("Whoops server stopped")
    }

    func handleSocketServerMsgDict(
        _ aDict: [AnyHashable : Any]?,
        from client: UDClient?,
        error: Error?) {
        if let dict = aDict {
            Logger.shared.log("Got message: \(dict)")
            do {
                let answer = "son los \(Date())"
                try client?.sendMessageDict(dictionary: ["Answer from server": answer])
            } catch {
                Logger.shared.log("Message send failed with error: \(error)")
            }
        }
        if let error = error {
            Logger.shared.log("Got error: \(error)")
        }
    }
    
}
