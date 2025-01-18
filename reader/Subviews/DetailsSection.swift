import SwiftUI

struct DetailsSection: View {
    let title: String
    let author: String
    let genre: String
    let series: String
    let isbn: String
    let publisher: String
    let formattedDate: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text(title)
                .font(.custom("Merriweather-Regular", size: 24))
                .foregroundStyle(.primary)
                .accessibilityLabel("Title: \(title)")
            
            // Author
            Text("by \(author)")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Author: \(author)")
            
            // Info Rows
            ForEach(infoRows, id: \.label) { row in
                Text("\(row.label): \(row.value)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(row.label): \(row.value)")
            }
            
            // Description with ScrollView
            if !description.isEmpty {
                ScrollView {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .padding(10)
                }
                .frame(maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
    }
    
    private var infoRows: [(label: String, value: String)] {
        [
            ("Genre", genre),
            ("Series", series),
            ("ISBN", isbn),
            ("Publisher", publisher),
            ("Published", formattedDate)
        ].filter { !$0.value.isEmpty } // Only show non-empty rows
    }
}
