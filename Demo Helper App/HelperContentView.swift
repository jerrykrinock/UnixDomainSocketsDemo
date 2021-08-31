import SwiftUI


struct HelperAppContentView: View {
    var server: UDServer
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Text("I don't have any buttons because in a real product I shall probably be a LSUIElement (faceless background app).")
                .frame(minWidth: 500.0, idealWidth: 500.0, maxWidth: 500.0, minHeight: nil, idealHeight: nil, maxHeight: nil, alignment: .leading)
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
