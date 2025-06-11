import SwiftUI
import SwiftData

// MARK: - Reading Status
struct StatusSection: View {
    @Bindable var book: BookData
    
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var isEditingStartDate = false
    @State private var isEditingFinishDate = false
    
    private var bookStatus: some View {
        HStack {
            Text("Status:")
                .font(.subheadline)
            
            Label(book.status.displayText, systemImage: book.status.iconName)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(book.status.statusColor.opacity(0.2))
                .foregroundColor(book.status.statusColor)
                .clipShape(.capsule)
            
            Spacer()
        }
        .padding(.bottom, 6)
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            bookStatus

            if book.status != .unread {
                DateEditor(
                    date: $book.dateStarted,
                    isEditing: $isEditingStartDate,
                    label: "Date Started",
                    minDate: nil
                )

                if book.status != .reading {
                    DateEditor(
                        date: $book.dateFinished,
                        isEditing: $isEditingFinishDate,
                        label: "Date Finished",
                        minDate: book.dateStarted
                    )
                }
            }
        }
        .padding(.vertical, 10)
        .onChange(of: [book.dateStarted, book.dateFinished]) {
            validateDates()
            contentViewModel.saveChanges()
        }
        .onChange(of: book.id) {
            isEditingStartDate = false
            isEditingFinishDate = false
        }
    }
    
    private func validateDates() {
        if let start = book.dateStarted, let finish = book.dateFinished, finish < start {
            book.dateFinished = start
        }
    }
}

// MARK: - Date Start/Finish
private struct DateEditor: View {
    @Binding var date: Date?
    @Binding var isEditing: Bool
    
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var tempDate: Date? = nil
    
    let label: String
    
    var minDate: Date? = nil
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.subheadline)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.secondary)
            
            if date != nil || isEditing {
                if isEditing {
                    HStack {
                        if tempDate != nil {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { tempDate ?? Date() },
                                    set: { newDate in tempDate = newDate }
                                ),
                                in: (minDate ?? Date.distantPast)...Date(), displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)

                            // Clear date button
                            Button(action: {
                                tempDate = nil
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("No date")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                    )
                    
                    // Confirm changes
                    Button(action: {
                        date = tempDate // Will be nil if cleared
                        isEditing = false
                        contentViewModel.saveChanges()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    // Cancel changes
                    Button(action: {
                        tempDate = date // Reset to original
                        isEditing = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    
                } else {
                    HStack {
                        Text(formatDate(date!))
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            tempDate = date
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                    )
                }
            } else {
                Button("Add Date") {
                    tempDate = Date()
                    isEditing = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return DateFormatterUtils.cachedMediumFormatter.string(from: date)
    }
}
