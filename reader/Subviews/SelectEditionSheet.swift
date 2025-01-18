import SwiftUI

struct SelectEditionSheet: View {
    @Binding var selectedBook: BookTransferData?
    var addBook: (BookTransferData) -> Void
    var cancel: () -> Void
    let searchResults: [BookTransferData]
    
    var body: some View {
        VStack {
            Text("Select Edition")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            if searchResults.isEmpty {
                VStack {
                    Text("No editions found.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button("Dismiss") {
                        cancel()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(searchResults) { book in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(book.title)
                                    .font(.headline)
                                Text("By: \(book.author)")
                                    .font(.subheadline)
                                Text("Publisher: \(book.publisher ?? "Unknown")")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                if let isbn = book.isbn, !isbn.isEmpty {
                                    Text("ISBN: \(isbn)")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("ISBN: Not available")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(book.bookDescription ?? "")
                                    .lineLimit(2)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(selectedBook == book ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture { selectedBook = book }
                        }
                    }
                }
                .padding()
            }
            
            HStack {
                Spacer()
                Button("Cancel") { cancel() }
                    .buttonStyle(.bordered)
                
                Button("Add") {
                    if let selectedBook = selectedBook {
                        addBook(selectedBook)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedBook == nil)
                Spacer()
            }
            .padding(.vertical)
        }
    }
}
