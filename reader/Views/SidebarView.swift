import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SidebarList
            SettingsButton
        }
    }
    
    // Sidebar list of status buttons
    private var SidebarList: some View {
        VStack {
            List(selection: $viewModel.selectedStatus) {
                ForEach(StatusFilter.allCases) { status in
                    StatusButton(
                        status: status,
                        selectedStatus: $viewModel.selectedStatus,
                        count: viewModel.bookCount(for: status)
                    )
                    .background(backgroundForStatus(status))
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.sidebar)
            
            Spacer()
        }
    }
    
    // Settings button at the bottom
    private var SettingsButton: some View {
        Button(action: { openWindow(id: "settingsWindow") }) {
            Image(systemName: "gear")
                .font(.system(size: 16, weight: .regular))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .foregroundColor(buttonForegroundColor)
                .brightness(buttonBrightness)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.borderless)
        .padding([.leading, .bottom], 10)
        .accessibilityLabel("Settings")
        .help("Settings")
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // Determine the button's foreground color based on hover state and color scheme
    private var buttonForegroundColor: Color {
        isHovered && colorScheme == .light ? .accentColor : .primary
    }
    
    // Determine the button's brightness based on hover state and color scheme
    private var buttonBrightness: Double {
        isHovered ? (colorScheme == .dark ? 0.5 : 0) : 0
    }
    
    // Background color for selected status
    private func backgroundForStatus(_ status: StatusFilter) -> some View {
        Group {
            if viewModel.selectedStatus == status {
                Color.accentColor.opacity(0.15)
            } else {
                Color.clear
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
