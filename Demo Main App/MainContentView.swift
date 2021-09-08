import SwiftUI


struct MainAppContentView: View {
    var client: UDSClient
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Text("""
To run this demo, first Launch Helper App, then Start Internal Client, then try one or more of the Jobs.

If you ever want to see the socket status in the system, in Terminal.app enter:
    netstat -f unix | grep -e UDSDService -e Recv-Q
(The last -e in that command is to print the column headings.)
""")
            Button(action: {
                launchHelper()
            }) {
                Text("Launch Helper App")
            }
            Button(action: {
                do {
                    try self.client.start()
                    Logger.shared.log("Started client with bufferSize \(client.bufferSize) bytes")
                } catch {
                    Logger.shared.logError(error)
                }
            }) {
                Text("Start Internal Client")
            }
            Button(action: {
                do {
                    try self.client.sendMessageDict([
                        JobTalk.Keys.command : JobTalk.Commands.whatTimeIsIt
                    ])
                } catch {
                    Logger.shared.logError(UDSClient.UDSErr(kind: .nested(
                        identifier: "askingTimeOfDay",
                        underlying: error)))
                }
            }) {
                Text("Small Job (ask time of day)")
            }
            Button(action: {
                do {
                    var numbers: Array<Int> = Array()
                    for i in 1...10000 {
                        numbers.append(i)
                    }
                    try self.client.sendMessageDict([
                        JobTalk.Keys.command : JobTalk.Commands.multiplyEachElementBy2,
                        JobTalk.Keys.jobDataIn : numbers
                    ])
                } catch {
                    Logger.shared.logError(UDSClient.UDSErr(kind: .nested(
                        identifier: "sendingBigDict",
                        underlying: error)))
                }
            }) {
                Text("Big Job (process 10K integers)")
            }
            Button(action: {
                do {
                    try self.client.sendMessageDict([
                        JobTalk.Keys.command : JobTalk.Commands.getSafariBookmarks
                    ])
                } catch {
                    Logger.shared.logError(UDSClient.UDSErr(kind: .nested(
                        identifier: "askingForSafariBookmarks",
                        underlying: error)))
                }
            }) {
                Text("Full Disk Access Job (read Safari bookmarks file)")
            }

            Text("EVENT LOG")
                .frame(maxWidth: .infinity, alignment: .topLeading)
            ScrollView {
                Text(Logger.shared.log)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: 500, alignment:.leading)
        .multilineTextAlignment(.leading)
        .padding()
    }
}
