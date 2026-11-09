import SwiftUI

@main
struct MultiOutputApp: App {
    @State private var stack = AudioStack()

    var body: some Scene {
        WindowGroup {
            RootView(stack: stack)
                .preferredColorScheme(.light)
        }
    }
}
