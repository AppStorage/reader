import SwiftUI
import Combine

// Wrapper class for cancellables
class CancellableStorage {
    var cancellables = Set<AnyCancellable>()
}

// MARK: - Add Book View
struct AddView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var alertManager: AlertManager
    @EnvironmentObject var overlayManager: OverlayManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var localPublishedDate: Date?
    @State private var showNoResultsAlert = false
    @State private var validationErrors: [Field: String] = [:]
    @State private var cancellableStorage = CancellableStorage()
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                header
                
                Divider()
                    .opacity(0.25)
                
                bookForm
                
                Divider()
                    .opacity(0.25)
                
                actionButtons
            }
            .frame(width: 450)
            .padding()
            .onAppear {
                enforceWindowStyle()
            }
            .onDisappear {
                viewModel.resetAddBookForm()
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isAddBookSheetPresented },
                set: { viewModel.isAddBookSheetPresented = $0 }
            )) {
                SelectEditionSheet(
                    selectedBook: Binding(
                        get: { viewModel.selectedBookForAdd },
                        set: { viewModel.selectedBookForAdd = $0 }
                    ),
                    searchResults: viewModel.bookSearchResults,
                    addBook: { book in
                        handleAddBook(book)
                    },
                    cancel: {
                        viewModel.isAddBookSheetPresented = false
                    }
                )
            }
            .alert(isPresented: $showNoResultsAlert) {
                Alert(
                    title: Text("No Results Found"),
                    message: Text("No books found. Please check the details and try again."),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            OverlayView(windowId: "addBookWindow")
                .environmentObject(overlayManager)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Spacer()
            Label("Add New Book", systemImage: "book.fill")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private var bookForm: some View {
        BookFormView(
            title: Binding(
                get: { viewModel.addBookForm.title },
                set: { viewModel.addBookForm.title = $0 }
            ),
            author: Binding(
                get: { viewModel.addBookForm.author },
                set: { viewModel.addBookForm.author = $0 }
            ),
            genre: Binding(
                get: { viewModel.addBookForm.genre },
                set: { viewModel.addBookForm.genre = $0 }
            ),
            series: Binding(
                get: { viewModel.addBookForm.series },
                set: { viewModel.addBookForm.series = $0 }
            ),
            isbn: Binding(
                get: { viewModel.addBookForm.isbn },
                set: { viewModel.addBookForm.isbn = $0 }
            ),
            publisher: Binding(
                get: { viewModel.addBookForm.publisher },
                set: { viewModel.addBookForm.publisher = $0 }
            ),
            publishedDate: Binding(
                get: { localPublishedDate },
                set: {
                    localPublishedDate = $0
                    viewModel.addBookForm.published = $0
                }
            ),
            description: Binding(
                get: { viewModel.addBookForm.description },
                set: { viewModel.addBookForm.description = $0 }
            ),
            validationErrors: $validationErrors,
            showValidationErrors: false,
            focusedField: $focusedField
        )
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            Button("Fetch Book") {
                fetchAndShowSheet()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canFetchBook)
            
            Button("Add Book") {
                handleAddManualBook()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
    
    // MARK: - Show Fetched Books
    private func fetchAndShowSheet() {
        overlayManager.showLoading(message: "Fetching books...", windowId: "addBookWindow", onCancel: {
            viewModel.cancelAddBookFetch()
            overlayManager.hideOverlay(windowId: "addBookWindow")
        })
        
        viewModel.fetchBooks()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                overlayManager.hideOverlay(windowId: "addBookWindow")
                if case .failure(let error) = completion {
                    overlayManager.showToast(
                        message: "Error fetching books: \(error.localizedDescription)",
                        windowId: "addBookWindow"
                    )
                }
            }, receiveValue: { results in
                if results.isEmpty {
                    showNoResultsAlert = true
                } else {
                    viewModel.bookSearchResults = results
                    viewModel.isAddBookSheetPresented = true
                }
            })
            .store(in: &cancellableStorage.cancellables)
    }
    
    // MARK: - Helpers
    private func handleAddBook(_ book: BookTransferData) {
        overlayManager.showLoading(message: "Adding book...", windowId: "addBookWindow")
        
        viewModel.addBook(book)
            .receive(on: RunLoop.main)
            .sink { successMessage in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.overlayManager.hideOverlay(windowId: "addBookWindow")
                    self.overlayManager.showToast(
                        message: successMessage,
                        duration: 1.5,
                        windowId: "addBookWindow"
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if let window = NSApp.windows.first(where: { $0.title == "Add Book" }) {
                            window.close()
                        }
                    }
                }
            }
            .store(in: &cancellableStorage.cancellables)
    }
    
    private func handleAddManualBook() {
        validationErrors = BookFormView.validateFields(
            title: viewModel.addBookForm.title,
            author: viewModel.addBookForm.author,
            isbn: viewModel.addBookForm.isbn
        )
        
        if !validationErrors.isEmpty {
            if let field = validationErrors.keys.first {
                focusedField = field
            }
            return
        }
        
        overlayManager.showLoading(message: "Adding book...", windowId: "addBookWindow")
        
        viewModel.addManualBook()
            .receive(on: RunLoop.main)
            .sink { successMessage in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.overlayManager.hideOverlay(windowId: "addBookWindow")
                    self.overlayManager.showToast(
                        message: successMessage,
                        duration: 1.5,
                        windowId: "addBookWindow"
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if let window = NSApp.windows.first(where: { $0.title == "Add Book" }) {
                            window.close()
                        }
                    }
                }
            }
            .store(in: &cancellableStorage.cancellables)
    }
    
    private func enforceWindowStyle() {
        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "addBookWindow" }) {
            window.styleMask.remove([.resizable, .miniaturizable])
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
    }
}
