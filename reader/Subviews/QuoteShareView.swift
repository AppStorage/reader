import SwiftUI

struct QuoteShareView: View {
    let book: BookData
    @Binding var isPresented: Bool
    
    @State private var selectedQuoteIndex = 0
    @State private var selectedBackground: QuoteBackgroundStyle = .light
    @State private var quoteContentSize: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
                .padding(.horizontal)
            
            if book.quotes.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    previewView
                        .padding(.top, 24)
                    
                    Spacer()
                        .frame(height: 30)
                    
                    controlsView
                    
                    Spacer(minLength: 25)
                    
                    actionButtonsView
                }
                .padding(.bottom, 24)
            }
        }
        .frame(width: 580, height: 650)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateQuoteContentSize()
            }
        }
    }
    
    private var currentQuote: (quote: String, attribution: String?, page: String?) {
        ShareQuoteManager.parseQuote(book.quotes[selectedQuoteIndex])
    }
    
    private var headerView: some View {
        HStack {
            Text("Share Quote")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            
            Spacer()
            
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape)
            .help("Close")
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 54))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            
            Text("No quotes available")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Add some highlights to this book to create quotes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var previewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            ScrollView(.vertical, showsIndicators: true) {
                QuoteCard(
                    quote: currentQuote.quote,
                    attribution: currentQuote.attribution,
                    book: book,
                    style: selectedBackground
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                .frame(width: 500)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .background(
                    GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            quoteContentSize = geo.size
                        }
                        return Color.clear
                    }
                )
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 28) {
            quoteSelectionControls
            backgroundStyleControls
        }
    }
    
    private var quoteSelectionControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Quote")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(selectedQuoteIndex + 1) of \(book.quotes.count)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            pickerWithNavigationButtons
        }
        .padding(.horizontal, 24)
    }
    
    private var backgroundStyleControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            backgroundStyleSelector
        }
        .padding(.horizontal, 24)
    }
    
    private var pickerWithNavigationButtons: some View {
        HStack(spacing: 8) {
            navigationButton(
                iconName: "chevron.left",
                isEnabled: selectedQuoteIndex > 0,
                action: { selectedQuoteIndex -= 1 }
            )
            
            Picker("", selection: $selectedQuoteIndex) {
                ForEach(0..<book.quotes.count, id: \.self) { index in
                    let parsedQuote = ShareQuoteManager.parseQuote(book.quotes[index])
                    Text(parsedQuote.quote.prefix(40) + (parsedQuote.quote.count > 40 ? "..." : ""))
                        .tag(index)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .onChange(of: selectedQuoteIndex) { _, _ in
                updateQuoteContentSize()
            }
            
            navigationButton(
                iconName: "chevron.right",
                isEnabled: selectedQuoteIndex < book.quotes.count - 1,
                action: { selectedQuoteIndex += 1 }
            )
        }
    }
    
    private func navigationButton(iconName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            if isEnabled {
                action()
                updateQuoteContentSize()
            }
        }) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isEnabled ? .primary : .secondary.opacity(0.5))
                .frame(width: 36, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
    
    private var backgroundStyleSelector: some View {
        HStack(spacing: 12) {
            ForEach(QuoteBackgroundStyle.allCases) { style in
                backgroundStyleButton(style)
            }
        }
        .padding(4)
    }
    
    private func backgroundStyleButton(_ style: QuoteBackgroundStyle) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedBackground = style
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(style.backgroundColor)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                    
                    Image(systemName: style.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(style.quoteTextColor.opacity(0.7))
                    
                    if selectedBackground == style {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 48, height: 48)
                    }
                }
                
                Text(style.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(style == selectedBackground ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    private var actionButtonsView: some View {
        VStack {
            Button(action: {
                exportQuote()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 12))
                    Text("Save Image")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(minWidth: 130)
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private func updateQuoteContentSize() {
        // This function gets called when the view appears and when the selected quote changes
        // The actual size update happens through the GeometryReader in the preview
    }
    
    private func exportQuote() {
        let exportHeight = max(280.0, quoteContentSize.height + 24.0)
        let exportWidth: CGFloat = 500.0
        
        // Create filename from book title and page number
        let pageText = currentQuote.page != nil ? ", p.\(currentQuote.page!)" : ""
        let filename = "\(book.title)\(pageText)"
        
        let exportView = QuoteCard(
            quote: currentQuote.quote,
            attribution: currentQuote.attribution,
            book: book,
            style: selectedBackground,
            fixedSize: CGSize(width: exportWidth, height: exportHeight)
        )
            .environment(\.colorScheme, .light)
        
        ShareQuoteManager.exportQuoteAsPNG(
            exportView: exportView,
            size: CGSize(width: exportWidth, height: exportHeight),
            cornerRadius: 16,
            filename: filename,
            scaleFactor: 2.0
        )
    }
}
