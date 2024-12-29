import SwiftUI

struct AddCollectionSheet: View {
    @Binding var collectionName: String
    @State private var errorMessage: String?
    @State private var typingTimer: Timer?
    
    var existingCollectionNames: [String]
    var onAdd: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Add New Collection")
                .font(.headline)
                .padding(.top, 8)
            
            TextField("Collection Name", text: $collectionName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .onChange(of: collectionName) {
                    typingTimer?.invalidate()
                    typingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                        DispatchQueue.main.async {
                            _ = validateName()
                        }
                    }
                }
            
            if let errorMessage = errorMessage {
                Label {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.yellow)
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.yellow)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: errorMessage)
            }
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add") {
                    if validateName() {
                        onAdd()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(errorMessage != nil || collectionName.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 300, height: 200)
        .animation(.easeInOut, value: errorMessage)
    }
    
    // MARK:  Validation
    private func validateName() -> Bool {
        if collectionName.isEmpty {
            errorMessage = "Name cannot be empty"
            return false
        }
        else if existingCollectionNames.contains(where: { $0.lowercased() == collectionName.lowercased() }) {
            errorMessage = "A collection with this name already exists"
            return false
        }
        else {
            errorMessage = nil
            return true
        }
    }
}
