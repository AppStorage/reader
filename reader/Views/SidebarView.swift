import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack {
                // Sidebar main content
                List(selection: $viewModel.selectedStatus) {
                    ForEach(StatusFilter.allCases) { status in
                        StatusButton(
                            status: status,
                            selectedStatus: $viewModel.selectedStatus,
                            count: viewModel.bookCount(for: status)
                        )
                        .background(
                            backgroundForStatus(status)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        )
                        .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.sidebar)

                Spacer()
            }

            // Settings button
            Button(action: {
                openWindow(id: "settingsWindow")
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .regular))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
                    .brightness(isHovered ? 0.5 : 0)
            }
            .buttonStyle(.borderless)
            .padding([.leading, .bottom], 10)
            .accessibilityLabel("Settings")
            .help("Settings")
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }

    private func backgroundForStatus(_ status: StatusFilter) -> some View {
        Group {
            if viewModel.selectedStatus == status {
                Color.accentColor.opacity(0.15)
            } else {
                Color.clear
            }
        }
    }
}

struct StatusButton: View {
    let status: StatusFilter
    @Binding var selectedStatus: StatusFilter
    let count: Int

    var body: some View {
        Button(action: { handleStatusSelection() }) {
            HStack {
                statusIcon
                statusText
                Spacer()
                statusCount
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
    }

    private func handleStatusSelection() {
        withAnimation {
            selectedStatus = status
        }
    }
    
    private var statusIcon: some View {
        Image(systemName: status.iconName)
            .foregroundColor(selectedStatus == status ? .accentColor : .primary)
    }
    
    private var statusText: some View {
        Text(status.rawValue)
            .font(.body)
            .fontWeight(selectedStatus == status ? .semibold : .regular)
    }
    
    private var statusCount: some View {
        Text("\(count)")
            .font(.footnote)
            .foregroundColor(.secondary)
    }
}
