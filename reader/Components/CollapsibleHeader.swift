import SwiftUI

struct CollapsibleHeader: View {
    @Binding var isEditing: Bool
    @Binding var isCollapsed: Bool
    
    var title: String
    var isEditingDisabled: Bool
    var onEditToggle: () -> Void
    var onToggleCollapse: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    onToggleCollapse()
                }
            }) {
                HStack {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                        .animation(.easeInOut(duration: 0.5), value: isCollapsed)
                        .font(.body)
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(isEditing ? "Done" : "Edit") {
                withAnimation(.easeInOut(duration: 0.5)) {
                    onEditToggle()
                }
            }
            .buttonStyle(LinkButtonStyle())
            .disabled(isEditingDisabled)
        }
        .padding(.bottom, 4)
    }
}
