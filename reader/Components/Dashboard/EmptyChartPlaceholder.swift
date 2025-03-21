import SwiftUI

struct EmptyChartPlaceholder: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.bottom, 8)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding()
    }
}
