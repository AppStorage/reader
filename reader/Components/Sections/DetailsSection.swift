import SwiftUI

struct DetailsSection: View {
    @Namespace private var starNamespace
    @State private var copiedISBN: String? = nil
    
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
    let showFullDescription: Binding<Bool>
    
    var onRatingChanged: ((Int) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleAndAuthorRow
            ratingRow
            infoRow
            descriptionRow
        }
    }
    
    // MARK: - Title and Author Row
    private var titleAndAuthorRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("Merriweather-Regular", size: 24))
                .foregroundColor(.primary)
                .accessibilityLabel("Title: \(title)")
            
            Text("by \(author)")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .accessibilityLabel("Author: \(author)")
        }
    }
    
    // MARK: - Rating Row
    private var ratingRow: some View {
        Group {
            if canRate {
                HStack(spacing: 6) {
                    Text("Rating:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .matchedGeometryEffect(id: star <= rating ? "filledStar\(star)" : "emptyStar\(star)", in: starNamespace)
                            .foregroundStyle(.yellow)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    onRatingChanged?(star)
                                }
                            }
                            .accessibilityLabel("\(star) star\(star > 1 ? "s" : "")")
                    }
                    
                    if rating != 0 {
                        Button(action: {
                            withAnimation(.spring()) {
                                onRatingChanged?(0)
                            }
                        }) {
                            Image(systemName: "x.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear rating")
                    }
                }
            }
        }
    }
    
    // MARK: - Info Row
    private var infoLabel: [(label: String, value: String)] {
        [
            ("Genre", genre),
            ("Series", series),
            ("ISBN", isbn),
            ("Publisher", publisher),
            ("Published", formattedDate)
        ].map { ($0.0, $0.1.isEmpty ? "—" : $0.1) }
    }
    
    private var infoRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(infoLabel, id: \.label) { row in
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
                            Image(systemName: copiedISBN == isbn ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                .font(.caption)
                                .foregroundStyle(copiedISBN == isbn ? .green : .secondary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.borderless)
                        .help("Copy ISBN")
                        .accessibilityLabel("Copy ISBN")
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
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let cleaned = text.replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleaned, forType: .string)
        
        withAnimation {
            copiedISBN = cleaned
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedISBN == cleaned {
                    copiedISBN = nil
                }
            }
        }
    }
    
    // MARK: - Description
    private var descriptionRow: some View {
        let previewLimit = 300
        let displayDescription = showFullDescription.wrappedValue || description.count <= previewLimit
        ? description
        : String(description.prefix(previewLimit)) + "…"
        
        return Group {
            if !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayDescription)
                        .font(.custom("Merriweather-Regular", size: 12))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.gray.opacity(0.1))
                        )
                        .transition(.opacity)
                    
                    if description.count > previewLimit {
                        ExpandableTextToggle(
                            isExpanded: showFullDescription,
                            alignmentPadding: 6,
                            font: .caption
                        )
                    }
                }
                .frame(minHeight: 100, alignment: .top)
            }
        }
    }
}
