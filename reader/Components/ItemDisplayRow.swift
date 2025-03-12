import SwiftUI

struct ItemDisplayRow: View {
    let text: String
    let secondaryText: String?
    let attributedText: String?
    let isEditing: Bool
    let includeQuotes: Bool
    let customFont: Font?
    
    let isEditingThis: Bool
    
    @Binding var editText: String
    @Binding var editSecondary: String
    @Binding var editAttribution: String
    
    let onRemove: (() -> Void)?
    let onEdit: (() -> Void)?
    let onSave: (() -> Void)?
    let onCancel: (() -> Void)?
    
    var body: some View {
        if isEditingThis {
            ItemForm(
                text: $editText,
                supplementaryField: Binding<String?>(
                    get: { editSecondary },
                    set: { editSecondary = $0 ?? "" }
                ),
                attributedField: includeQuotes ? Binding<String?>(
                    get: { editAttribution },
                    set: { editAttribution = $0 ?? "" }
                ) : .constant(nil),
                textLabel: includeQuotes ? "Edit quote" : "Edit note",
                iconName: includeQuotes ? "text.quote" : "note.text",
                onSave: onSave ?? {},
                onCancel: onCancel ?? {},
                isSingleLine: false
            )
            .transition(.asymmetric(
                insertion: .opacity.animation(.easeIn(duration: 0.2)),
                removal: .opacity.animation(.easeOut(duration: 0.2))
            ))
        } else {
            HStack(alignment: .top, spacing: 8) {
                mainTextView
                Spacer()
                if let secondary = secondaryText, !secondary.isEmpty {
                    secondaryTextView(secondary)
                }
                
                if isEditing {
                    Menu {
                        Button(action: {
                            if let onEdit = onEdit {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    onEdit()
                                }
                            }
                        }) {
                            Text("Edit")
                        }
                        if let onRemove = onRemove {
                            Button(action: {
                                withAnimation { onRemove() }
                            }) {
                                Text("Delete")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .contentShape(Rectangle())
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 6)
            .transition(.asymmetric(
                insertion: .opacity.animation(.easeIn(duration: 0.2)),
                removal: .opacity.animation(.easeOut(duration: 0.2))
            ))
        }
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
    
    private var formattedText: String {
        text
    }
}
