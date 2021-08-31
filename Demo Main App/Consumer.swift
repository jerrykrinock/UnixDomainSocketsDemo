import Foundation

class Consumer : UDClientDelegate {
    func handleSocketClientDisconnect(_ client: UDClient?) {
        Logger.shared.log("Whoops client stopped")
    }
    
    func handleSocketClientMsgDict(
        _ aDict: [String : String]?,
        client: UDClient?,
        error: Error?) {
        if let dict = aDict {
            Logger.shared.log("Got answer: \(dict)")
        }
        if let error = error {
            Logger.shared.log("Got error: \(error)")
        }
    }
    
}
