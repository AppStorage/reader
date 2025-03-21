import SwiftUI

struct TrendMetricView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String?
    var color: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(color ?? Color.accentColor)
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(color ?? Color.accentColor)
                
                Text(unit)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
