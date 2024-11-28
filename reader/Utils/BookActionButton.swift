import SwiftUI

struct BookActionButton: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var showSoftDeleteConfirmation = false
    @State private var showPermanentDeleteConfirmation = false
    @State private var bookToDelete: BookData?
    
    // Store the keyboard monitor reference
    @State private var keyboardMonitor: Any?
    
    var body: some View {
        VStack {
            if let selectedBook = viewModel.selectedBook {
                HStack(spacing: 12) {
                    if selectedBook.status == .deleted {
                        recoverButton(for: selectedBook)
                        permanentDeleteButton(for: selectedBook)
                    } else {
                        softDeleteButton(for: selectedBook)
                    }
                }
                .alert("This will move the book to deleted.", isPresented: $showSoftDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete") {
                        if let book = bookToDelete {
                            viewModel.softDeleteBook(book)
                        }
                    }
                }
                .alert("This will permanently delete the book. You can't undo this action.", isPresented: $showPermanentDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete") {
                        if let book = bookToDelete {
                            viewModel.permanentlyDeleteBook(book)
                        }
                    }
                }
                .onAppear {
                    addKeyboardListener()
                }
                .onDisappear {
                    removeKeyboardListener()
                }
            }
        }
    }
    
    private func addKeyboardListener() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 51 { // Backspace key code on macOS
                if let firstResponder = NSApp.keyWindow?.firstResponder,
                   firstResponder is NSText || firstResponder is NSTextView {
                    // Let the backspace key function normally in text fields or text views
                    return event
                }
                
                // Custom handling for selected book
                handleBackspaceKey()
                return nil // Prevent default handling
            }
            return event
        }
    }
    
    private func removeKeyboardListener() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil // Clear the reference to avoid re-removal
        }
    }
    
    private func handleBackspaceKey() {
        if let selectedBook = viewModel.selectedBook {
            bookToDelete = selectedBook
            showSoftDeleteConfirmation = true
        }
    }
    
    // Recover button for deleted books
    private func recoverButton(for book: BookData) -> some View {
        Button(action: {
            viewModel.recoverBook(book)
        }) {
            Image(systemName: "return")
        }
        .accessibilityLabel("Recover")
    }
    
    // Permanent delete button for deleted books
    private func permanentDeleteButton(for book: BookData) -> some View {
        Button(action: {
            bookToDelete = book
            showPermanentDeleteConfirmation = true
        }) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete")
    }
    
    // Soft delete button for active books
    private func softDeleteButton(for book: BookData) -> some View {
        Button(action: {
            bookToDelete = book
            showSoftDeleteConfirmation = true
        }) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete")
    }
}
