import SwiftUI


struct MainAppContentView: View {
    var client: UDClient
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Spacer(minLength: 20)
            Text("To check socket status in Terminal.app:")
            Text("netstat -f unix | grep -e UDSDService -e Recv-Q")
            /* (The last -e in that command is to print the column headings.) */
            Spacer(minLength: 20)
            Button(action: {
                launchHelper()
            }) {
                Text("Launch the Helper app (which will start its server)")
            }
            Button(action: {
                self.client.start()
            }) {
                Text("Start the Client (which is in this app)")
            }
            Button(action: {
                do {
                    try self.client.sendMessageDict(dictionary: ["Question from client": "What time is it?"])
                } catch {
                    Logger.shared.log("Message send failed with error: \(error)")
                }
            }) {
                Text("Demo simple service: Ask server for the time of day")
            }

            ScrollView {
                VStack {
                    Text(Logger.shared.log)
                        .font(.subheadline)
                        .lineLimit(nil)
                }.frame(maxWidth: .infinity)
            }
            .border(Color.red)
        }
    }
}
