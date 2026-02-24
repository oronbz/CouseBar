import SwiftUI

struct ContentView: View {
    let service: CopilotService

    var body: some View {
        PopoverView(service: service)
    }
}

#Preview {
    ContentView(service: CopilotService())
}
