import SwiftUI

@main
struct CouseBarApp: App {
    @State private var service = CopilotService()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(service: service)
        } label: {
            MenuBarLabel(usage: service.usage)
        }
        .menuBarExtraStyle(.window)
    }
}
