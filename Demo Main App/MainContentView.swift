import SwiftUI


struct MainAppContentView: View {
    var client: UDSClient
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Text("""
To run this demo, click the 3 buttons in order.

1.  Launch Helper App.  The Helper App will start its internal server upon launch.
2.  Start Internal Client.  (The Client is an object in this here Main app.)  It will connect to the sersver in the Helper.
3.  Small Job.  This button will cause the Client to ask the helper/server for the time of day.  The server's response will be printed to the Event Log.
3.  Big Job.  This button will send an array of several thousand numbers to the server.  The server will send back an array weach number multiplied by 2, and a truncated version of this response will be displayed in the Event Log.

If you ever want to see the socket status in the system, in Terminal.app enter:
    netstat -f unix | grep -e UDSDService -e Recv-Q
(The last -e in that command is to print the column headings.)
""")
                .frame(minWidth: 500.0, idealWidth: 500.0, maxWidth: 500.0, minHeight: 230.0, idealHeight: nil, maxHeight: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            /* Is it really this hard for a Text to expand to fit text?
             https://lostmoa.com/blog/DynamicHeightForTextFieldInSwiftUI/ */
            
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
                        identifier: "sendingQuestion",
                        underlying: error)))
                }
            }) {
                Text("Small Job")
            }
            Button(action: {
                do {
                    var numbers: Array<Int> = Array()
                    for i in 1...6850 {
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
                Text("Big Job")
            }

            Text("EVENT LOG")
                .frame(maxWidth: .infinity, alignment: .topLeading)
            ScrollView {
                Text(Logger.shared.log)
                    .frame(maxWidth: .infinity, minHeight: 10.0, alignment: .topLeading)
            }
        }
        .frame(width: 500, alignment:.leading)
        .multilineTextAlignment(.leading)
        .padding()
        
    }
    
}
