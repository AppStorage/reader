import SwiftUI

struct PaginationControls: View {
    let currentPage: Int
    let totalCount: Int
    let pageSize: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        let maxPage = max((totalCount - 1) / pageSize, 0)

        HStack(spacing: 16) {
            Button(action: {
                withAnimation { onPrevious() }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(currentPage == 0 ? .gray : .accentColor)
            }
            .disabled(currentPage == 0)
            .buttonStyle(.plain)
            .help("Previous page")
            .accessibilityLabel("Previous page")

            Text("Page \(currentPage + 1) of \(maxPage + 1)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.secondary.opacity(0.1)))

            Button(action: {
                withAnimation { onNext() }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor((currentPage >= maxPage) ? .gray : .accentColor)
            }
            .disabled(currentPage >= maxPage)
            .buttonStyle(.plain)
            .help("Next page")
            .accessibilityLabel("Next page")
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
    }
}
