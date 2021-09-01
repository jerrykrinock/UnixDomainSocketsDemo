import SwiftUI


struct MainAppContentView: View {
    var client: UDClient
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Text("""
To run this demo, click the 3 buttons in order.

1.  Launch Helper App.  The Helper App will start its internal server upon launch.
2.  Start Internal Client.  (The Client is an object in this here Main app.)  It will connect to the sersver in the Helper.
3.  Time of Day.  This button will cause the Client to ask the helper/server for the time of day.  The server will respond.
3.  Big Dictionary.  This button will send a big dictionary to the server.  The server will echo it back.

If you ever want to see the socket status in the system, in Terminal.app enter:
    netstat -f unix | grep -e UDSDService -e Recv-Q
(The last -e in that command is to print the column headings.)
""")
                .frame(minWidth: 500.0, idealWidth: 500.0, maxWidth: 500.0, minHeight: 185.0, idealHeight: nil, maxHeight: .infinity, alignment: .leading)
            Spacer(minLength: 20)
            Button(action: {
                launchHelper()
            }) {
                Text("Launch Helper App")
            }
            Button(action: {
                self.client.start()
            }) {
                Text("Start Internal Client")
            }
            Button(action: {
                do {
                    try self.client.sendMessageDict(dictionary: ["Question from client": "What time is it?"])
                } catch {
                    Logger.shared.logError(UDClient.UDSErr(kind: .nested(
                        identifier: "sendingQuestion",
                        underlying: error)))
                }
            }) {
                Text("Time of Day")
            }
            Button(action: {
                do {
                    var bigDict: Dictionary<String, String> = Dictionary()
                    for i in 1...681 {  // 680 is OK, 681 fails
                        bigDict[String(describing:i)] = String(describing:2*i)
                    }
                    try self.client.sendMessageDict(dictionary: bigDict)
                } catch {
                    Logger.shared.logError(UDClient.UDSErr(kind: .nested(
                        identifier: "sendingBigDict",
                        underlying: error)))
                }
            }) {
                Text("Big Dictionary")
            }

            Spacer(minLength: 20)

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
