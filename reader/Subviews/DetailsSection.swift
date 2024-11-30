import SwiftUI

struct DetailsSection: View {
    @Binding var title: String
    @Binding var author: String
    @Binding var genre: String
    @Binding var series: String
    @Binding var isbn: String
    @Binding var publisher: String
    @Binding var formattedDate: String
    @Binding var description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("Merriweather-Regular", size: 24))
            
            Text("by \(author)")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            if !genre.isEmpty {
                Text("Genre: \(genre)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            if !series.isEmpty {
                Text("Series: \(series)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            if !isbn.isEmpty {
                Text("ISBN: \(isbn)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            if !publisher.isEmpty {
                Text("Publisher: \(publisher)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            if !formattedDate.isEmpty {
                Text("Published: \(formattedDate)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            if !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .padding(.top, 10)
                
            }
        }
    }
}
