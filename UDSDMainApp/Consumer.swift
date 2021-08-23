import Foundation

class Consumer : CommSocketClientDelegate {
    func handleSocketClientDisconnect(_ client: CommSocketClient?) {
        Logger.shared.log("Whoops client stopped")
    }
    
    func handleSocketClientMsgDict(
        _ aDict: [AnyHashable : Any]?,
        client: CommSocketClient?,
        error: Error?) {
        if let dict = aDict {
            Logger.shared.log("Got answer: \(dict)")
        }
        if let error = error {
            Logger.shared.log("Got error: \(error)")
        }
    }
    
}
