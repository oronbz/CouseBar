import SwiftUI

struct ContentView: View {
    let service: CopilotService

    var body: some View {
        PopoverView(service: service)
    }
}

#Preview("Normal Usage") {
    ContentView(service: .previewMediumUsage)
}

#Preview("Over Limit") {
    ContentView(service: .previewOverLimit)
}
