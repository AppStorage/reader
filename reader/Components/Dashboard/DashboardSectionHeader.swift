import SwiftUI

struct DashboardSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .accessibilityAddTraits(.isHeader)
    }
}
