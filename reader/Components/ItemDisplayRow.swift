import SwiftUI

struct ItemDisplayRow: View {
    let text: String
    let secondaryText: String?
    let attributedText: String?
    let isEditing: Bool
    let includeQuotes: Bool
    let customFont: Font?
    let onRemove: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            mainTextView
            Spacer()
            if let secondary = secondaryText, !secondary.isEmpty {
                secondaryTextView(secondary)
            }
            if isEditing, let onRemove = onRemove {
                removeButton(onRemove: onRemove)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var mainTextView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedText)
                .font(customFont ?? .body)
                .multilineTextAlignment(.leading)
                .padding(10)
            
            if let attributedText = attributedText, !attributedText.isEmpty {
                Text("— \(attributedText)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    private func secondaryTextView(_ text: String) -> some View {
        Text("p. \(text)")
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
            .frame(minWidth: 50, alignment: .trailing)
    }
    
    private func removeButton(onRemove: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation { onRemove() }
        }) {
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(BorderlessButtonStyle())
        .transition(.opacity)
    }
    
    private var formattedText: String {
        includeQuotes ? "“\(text)”" : text
    }
}
