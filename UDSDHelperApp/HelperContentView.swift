import SwiftUI


struct HelperAppContentView: View {
    var server: CommSocketServer
    @ObservedObject var logger: Logger = Logger.shared

    var body: some View {
        VStack {
            Spacer(minLength: 20)

            Text("I don't have any buttons because in real life I am faceless background.")
                .padding()

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
