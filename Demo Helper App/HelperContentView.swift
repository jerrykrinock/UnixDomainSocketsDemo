import SwiftUI


struct HelperAppContentView: View {
    @ObservedObject var server: UDSServer
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Text("No buttons here because in a real product this shall probably be a LSUIElement (faceless background app).")
            Spacer(minLength: 10)
            Text("Server now has \(server.sockClients.count) connected clients.")
            Spacer(minLength: 10)
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
