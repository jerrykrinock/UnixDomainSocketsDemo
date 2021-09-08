import Foundation

// typealias Decoshable = Decodable & Hashable

struct Decoshable : Decodable, Hashable {
    static func == (lhs: Decoshable, rhs: Decoshable) -> Bool {
        Logger.shared.log("Uh-oh #1")
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        Logger.shared.log("Uh-oh #2")
    }
}

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
                } else if command == JobTalk.Commands.getSafariBookmarks {
                    // Cannot send Date via JSON, so describe as String
                    let url = NSURL.init(fileURLWithPath:NSHomeDirectory())
                        .appendingPathComponent("Library")?
                        .appendingPathComponent("Safari")
                        .appendingPathComponent("Bookmarks")
                        .appendingPathExtension("plist")
                    if let url = url {
                        do {
                            let data = try Data.init(contentsOf: url)
                            Logger.shared.log("Got Safari bookmarks data, \(data.count) bytes")
                            /* Decoding this data as a plist is beyond the scope of this
                             demo.  But we would like to verify that a MB or more of data
                             can pass via our Unix Domain Socket.  Since this is a *binary*
                             plist, it is not encodeable as UTF8, but we can lossily encode
                             it as ASCII. */
                            let safariText = String(data: data, encoding: .ascii)
                            if (safariText != nil) {
                                output[JobTalk.Keys.jobDataOut] = safariText
                            } else {
                                output[JobTalk.Keys.jobDataOut] = "Failed to encode Safari bookmarks file data as string"
                            }
                        } catch {
                            output[JobTalk.Keys.jobDataOut] = "Error reading Safari bookmarks data: \(error) This is either due to no Safari bookmarks ever having been set or, more likely, Helper App does not have the required Full Disk Access."
                        }
                    } else {
                        output[JobTalk.Keys.jobDataOut] = "Could not generate Safari Bookmarks URL"
                    }
                } else {
                    output[JobTalk.Keys.jobDataOut] = "Unknown command: \(command)"
                }
            } else {
                output[JobTalk.Keys.jobDataOut] = "Sorry, no command"
            }
            
            do {
                let truncatedOutput = (String(describing: output)).stringByTruncatingMiddle(toLength: 300, wholeWords: true)
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
