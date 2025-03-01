import SwiftUI

struct ChartLegend: View {
    let items: [(label: String, color: Color)]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(items, id: \.label) { item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                    
                    Text(item.label)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
