import SwiftUI

@main
struct CousebaraApp: App {
    @State private var service = CopilotService()
    @AppStorage("showPercentageInMenuBar") private var showPercentage = false

    var body: some Scene {
        MenuBarExtra {
            PopoverView(service: service)
        } label: {
            MenuBarLabel(usage: service.usage, showPercentage: showPercentage)
        }
        .menuBarExtraStyle(.window)
    }
}
