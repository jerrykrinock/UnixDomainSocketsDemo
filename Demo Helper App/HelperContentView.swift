import SwiftUI


struct HelperAppContentView: View {
    @ObservedObject var server: UDSServer
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Text("No buttons because in a real product this shall probably be a LSUIElement (faceless background app).")
                .frame(minWidth: 500.0, idealWidth: 500.0, maxWidth: 500.0, minHeight: nil, idealHeight: nil, maxHeight: nil, alignment: .leading)
            Spacer(minLength: 10)
            Text("Internal now server has \(server.sockClients.count) connected clients.")
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
