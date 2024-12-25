import SwiftUI

struct EmptyStateView: View {
    let type: EmptyStateType
    var minWidth: CGFloat? = nil
    
    var body: some View {
        VStack(spacing: type.spacing) {
            Spacer()
            
            Image(systemName: type.imageName)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(type.title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let message = type.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(minWidth: minWidth)
    }
}
