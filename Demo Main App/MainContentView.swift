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
3.  Demo a Job.  This button will cause the Client to ask the helper/server for the time of day.  The server will respond.

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
                Text("Demo a Job")
            }
            Spacer(minLength: 20)

            Text("LOG")
                .frame(width: nil, height: nil, alignment: .topLeading)
            ScrollView {
                VStack {
                    Text(Logger.shared.log)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 500, height: nil, alignment:.leading)
        .multilineTextAlignment(.leading)
        .padding()
        
    }
    
}
