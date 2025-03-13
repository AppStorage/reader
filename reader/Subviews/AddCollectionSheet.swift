import SwiftUI

struct AddCollectionSheet: View {
    @Binding var collectionName: String
    @State private var errorMessage: String?
    @State private var typingTimer: Timer?
    
    var existingCollectionNames: [String]
    var onAdd: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
                .padding(.horizontal)
                .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Collection Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Enter name", text: $collectionName)
                        .font(.system(size: 14))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: collectionName) {
                            typingTimer?.invalidate()
                            typingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                DispatchQueue.main.async {
                                    _ = validateName()
                                }
                            }
                        }
                        .onSubmit {
                            if validateName() {
                                onAdd()
                            }
                        }
                }
                
                if let errorMessage = errorMessage {
                    validationMessageView(message: errorMessage)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 20)
            .animation(.spring(duration: 0.3), value: errorMessage)
            
            Spacer(minLength: 20)
            
            actionButtonsView
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(width: 350, height: 225)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private var headerView: some View {
        HStack {
            Text("Add New Collection")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
        .padding(.bottom, 14)
    }
    
    private func validationMessageView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.yellow)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.8))
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private var actionButtonsView: some View {
        HStack {
            Button(action: {
                onCancel()
            }) {
                Text("Cancel")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(minWidth: 80)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button(action: {
                if validateName() {
                    onAdd()
                }
            }) {
                Text("Add")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .keyboardShortcut(.defaultAction)
            .disabled(errorMessage != nil || collectionName.isEmpty)
        }
    }
    
    // MARK: Validation
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
