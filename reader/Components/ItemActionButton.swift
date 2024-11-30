import SwiftUI

struct ItemActionButton: View {
    let label: String?
    let systemImageName: String
    let foregroundColor: Color
    let action: () -> Void
    let padding: EdgeInsets?

    var body: some View {
        Button(action: { withAnimation { action() } }) {
            if let label = label {
                Label(label, systemImage: systemImageName)
                    .font(.callout)
                    .foregroundColor(foregroundColor)
            } else {
                Image(systemName: systemImageName)
                    .foregroundColor(foregroundColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(padding ?? .init())
    }
}
