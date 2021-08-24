import SwiftUI


struct HelperAppContentView: View {
    var server: UDServer
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Text("I don't have any buttons because in a real product I shall probably be a LSUIElement (faceless background app).")
                .frame(minWidth: 500.0, idealWidth: 500.0, maxWidth: 500.0, minHeight: nil, idealHeight: nil, maxHeight: nil, alignment: .leading)
            Spacer(minLength: 20)

            Text("LOG")
                .frame(width: nil, height: nil, alignment: .topLeading)
            ScrollView {
                VStack {
                    Text(Logger.shared.log)
                }.frame(maxWidth: .infinity)
            }
            .border(.red, width: 2.0) // for debugging SwiftUI code
        }
        .frame(width: 500, height: nil, alignment:.leading)
        .multilineTextAlignment(.leading)
        .padding()
    }
}
