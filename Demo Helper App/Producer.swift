import Foundation

class Producer : UDSServerDelegate {
    func handleSocketServerStopped(_ server: UDSServer?) {
        Logger.shared.log("Whoops server stopped")
    }

    func handleSocketServerMsgDict(
        _ jobDict: [AnyHashable : AnyHashable]?,
        from client: UDSClient?,
        error: Error?) {
        if let jobDict = jobDict {
            Logger.shared.log("Got job dictionary from client \(String(describing: client))")
            var output: Dictionary<AnyHashable, AnyHashable> = Dictionary()
            if let command = jobDict[JobTalk.Keys.command] as? String {
                if command == JobTalk.Commands.whatTimeIsIt {
                    // Cannot send Date via JSON, so describe as String
                    output[JobTalk.Keys.jobDataOut] = String.init(describing: Date())
                } else if command == JobTalk.Commands.multiplyEachElementBy2 {
                    if let numbers = jobDict[JobTalk.Keys.jobDataIn] as? Array<Int> {
                        let products = numbers.map { $0 * 2 }
                        output[JobTalk.Keys.jobDataOut] = products
                    }
                }
            }
            
            do {
                let truncatedOutput = (String(describing: output)).stringByTruncatingMiddle(toLength: 180, wholeWords: true)
                Logger.shared.log("Sending output dict: \(truncatedOutput ?? "<<<NIL???>>>")")
                try client?.sendMessageDict(output)
            } catch {
                Logger.shared.logError(error)
            }
        }
        if let error = error {
            Logger.shared.log("Got error: \(error)")
        }
    }

    func handleConnectionError(_ error: Error?) {
        if let error = error {
            Logger.shared.logError(UDSocket.UDSErr(kind: .nested(
                identifier: "connectionErr",
                underlying: error)
            ))
        }
    }
}
