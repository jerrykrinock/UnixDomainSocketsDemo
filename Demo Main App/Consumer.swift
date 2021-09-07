import Foundation

class Consumer : UDSClientDelegate {
    func handleSocketServerDisconnect(_ client: UDSClient?) {
        Logger.shared.log("Server has disconnected.")
    }
    
    func handleSocketClientDisconnect(_ client: UDSClient?) {
        Logger.shared.log("Client has disconnected.")
    }
    
    func handleSocketClientMsgDict(
        _ aDict: [AnyHashable : AnyHashable]?,
        client: UDSClient?,
        error: Error?) {
        if let dict = aDict {
            let wholeString = String(describing: dict)
            if let truncatedString = wholeString.stringByTruncatingMiddle(toLength: 180, wholeWords: true) {
                var truncationMsg = ""
                if (wholeString.count > truncatedString.count) {
                    truncationMsg = "(showing truncated result, \(truncatedString.count)/\(wholeString.count) chars) "
                }
                Logger.shared.log("Got answer: \(truncationMsg)\((truncatedString))")
            }
        }
        if let error = error {
            Logger.shared.log("Got error: \(error)")
        }
    }
    
}
