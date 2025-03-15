import SwiftUI

struct DetailsSection: View {
    @State private var isbnCopied: Bool = false
    
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
            Text(title)
                .font(.custom("Merriweather-Regular", size: 24))
                .foregroundStyle(.primary)
                .accessibilityLabel("Title: \(title)")
            
            Text("by \(author)")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Author: \(author)")
            
            ForEach(infoRows, id: \.label) { row in
                if row.label == "ISBN" && !isbn.isEmpty {
                    HStack(spacing: 6) {
                        Text("\(row.label): \(row.value)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            let cleanedISBN = isbn.replacingOccurrences(of: " ", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            copyToClipboard(cleanedISBN)
                        } label: {
                            Image(systemName: isbnCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(isbnCopied ? .green : .secondary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.borderless)
                        .help("Copy ISBN")
                    }
                    .accessibilityLabel("\(row.label): \(row.value)")
                    .accessibilityHint("Copy ISBN")
                } else {
                    Text("\(row.label): \(row.value)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(row.label): \(row.value)")
                }
            }
            
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
        ].filter { !$0.value.isEmpty }
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        // Show checkmark feedback
        withAnimation {
            isbnCopied = true
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isbnCopied = false
            }
        }
    }
}
