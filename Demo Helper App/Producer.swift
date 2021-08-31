import Foundation

class Producer : UDServerDelegate {
    func handleSocketServerStopped(_ server: UDServer?) {
        Logger.shared.log("Whoops server stopped")
    }

    func handleSocketServerMsgDict(
        _ aDict: [String : String]?,
        from client: UDClient?,
        error: Error?) {
        if let requestDic = aDict {
            Logger.shared.log("Got dictionary from client \(String(describing: client))")
            var replyDict: Dictionary<String, String> = Dictionary()
            for key in requestDic.keys {
                if (key == "Question from client")  && (requestDic[key] == "What time is it?") {
                    replyDict[key] = "The time is \(Date())"
                } else {
                    replyDict[key] = requestDic[key]
                }
            }
            
            do {
                try client?.sendMessageDict(dictionary: replyDict)
            } catch {
                Logger.shared.log("Message send failed with error: \(error)")
            }
        }
        if let error = error {
            Logger.shared.log("Got error: \(error)")
        }
    }
    
}
