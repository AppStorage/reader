import SwiftUI
import Combine

@MainActor
class AlertManager: ObservableObject {
    @Published var currentAlert: AlertTypes?
    
    weak var appState: AppState?
    weak var contentViewModel: ContentViewModel?
    
    func showAlert(_ alertType: AlertTypes) {
        currentAlert = alertType
    }
    
    func showSoftDeleteConfirmation(for books: [BookData]) {
        showAlert(.softDelete(books: books))
    }
    
    func showPermanentDeleteConfirmation(for books: [BookData]) {
        showAlert(.permanentDelete(books: books))
    }
    
    func showNoResults() {
        showAlert(.noResults(""))
    }
    
    func showImportSuccess() {
        showAlert(.importSuccess)
    }
    
    func showExportSuccess() {
        showAlert(.exportSuccess)
    }
    
    func showError(_ message: String) {
        showAlert(.error(message))
    }
    
    func dismissAlert() {
        currentAlert = nil
    }
}
