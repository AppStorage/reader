import SwiftUI

struct DetailsSection: View {
    @State private var isbnCopied: Bool = false
    @State private var showFullDescription = false
    
    let title: String
    let author: String
    let rating: Int
    let genre: String
    let series: String
    let isbn: String
    let publisher: String
    let formattedDate: String
    let description: String
    let canRate: Bool
    
    private let lineLimit = 5
    private let truncationThreshold = 300
    
    var onRatingChanged: ((Int) -> Void)?
    
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
            
            if canRate {
                HStack(spacing: 4) {
                    Text("Rating:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                            .onTapGesture {
                                onRatingChanged?(star)
                            }
                            .accessibilityLabel("\(star) star\(star > 1 ? "s" : "")")
                    }
                    if rating != 0 {
                        Button(action: {
                            onRatingChanged?(0)
                        }) {
                            Image(systemName: "x.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear rating")
                    }
                }
                .padding(.vertical, 5)
            }
            
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
                VStack(alignment: .leading, spacing: 6) {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .lineLimit(showFullDescription ? nil : lineLimit)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .animation(.easeInOut(duration: 0.25), value: showFullDescription)
                    
                    if description.count > truncationThreshold {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showFullDescription.toggle()
                            }
                        }) {
                            Text(showFullDescription ? "Show Less" : "Show More")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .padding(.top, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
        
        withAnimation {
            isbnCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isbnCopied = false
            }
        }
    }
}
