import SwiftUI

struct DashboardSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .accessibilityAddTraits(.isHeader)
    }
}
