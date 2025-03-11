import SwiftUI

struct QuoteShareView: View {
    let book: BookData
    @Binding var isPresented: Bool
    
    @State private var selectedQuoteIndex = 0
    @State private var selectedBackground: QuoteBackgroundStyle = .light
    @State private var quoteContentSize: CGSize = .zero
    
    enum QuoteBackgroundStyle: String, CaseIterable, Identifiable {
        case light, sepia, dark
        
        var id: String { self.rawValue }
        
        var backgroundColor: Color {
            switch self {
            case .light: return Color.white
            case .sepia: return Color(red: 249/255, green: 241/255, blue: 228/255)
            case .dark: return Color(white: 0.1)
            }
        }
        
        var quoteTextColor: Color {
            switch self {
            case .light, .sepia: return Color.black
            case .dark: return Color.white
            }
        }
        
        var attributionTextColor: Color {
            switch self {
            case .light, .sepia: return Color.gray
            case .dark: return Color(white: 0.8)
            }
        }
        
        var bookAuthorColor: Color {
            switch self {
            case .light, .sepia: return Color.black
            case .dark: return Color.white
            }
        }
        
        var bookTitleColor: Color {
            switch self {
            case .light, .sepia: return Color.gray
            case .dark: return Color(white: 0.8)
            }
        }
        
        var iconName: String {
            switch self {
            case .light: return "sun.max"
            case .sepia: return "book.closed"
            case .dark: return "moon"
            }
        }
    }
    
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
    
    private var controlsView: some View {
        VStack(spacing: 28) {
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Background")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                backgroundStyleSelector
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var pickerWithNavigationButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                if selectedQuoteIndex > 0 {
                    selectedQuoteIndex -= 1
                    updateQuoteContentSize()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedQuoteIndex > 0 ? .primary : .secondary.opacity(0.5))
                    .frame(width: 36, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedQuoteIndex == 0)
            
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
            .onChange(of: selectedQuoteIndex) { oldValue, newValue in
                updateQuoteContentSize()
            }
            
            Button(action: {
                if selectedQuoteIndex < book.quotes.count - 1 {
                    selectedQuoteIndex += 1
                    updateQuoteContentSize()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedQuoteIndex < book.quotes.count - 1 ? .primary : .secondary.opacity(0.5))
                    .frame(width: 36, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedQuoteIndex == book.quotes.count - 1)
        }
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
    
    private var previewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            ScrollView(.vertical, showsIndicators: true) {
                quoteCardView
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
    
    private var quoteCardView: some View {
        let parsedQuote = ShareQuoteManager.parseQuote(book.quotes[selectedQuoteIndex])
        
        return ZStack {
            selectedBackground.backgroundColor
            // Quote icon
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24))
                    .foregroundColor(selectedBackground.quoteTextColor.opacity(0.3))
                    .padding(.bottom, 1)
                    .padding(.leading, 17)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Quote text and attribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text(parsedQuote.quote)
                            .font(.custom("Merriweather-Regular", size: 18))
                            .foregroundColor(selectedBackground.quoteTextColor)
                            .lineSpacing(7)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 16)
                            .frame(width: 452, alignment: .leading)
                        
                        if let attribution = parsedQuote.attribution, !attribution.isEmpty {
                            Text("— \(attribution)")
                                .font(.custom("Merriweather-Italic", size: 16))
                                .foregroundColor(selectedBackground.attributionTextColor)
                                .padding(.leading, 16)
                                .frame(width: 452, alignment: .leading)
                        }
                    }
                    .overlay(
                        Rectangle()
                            .fill(selectedBackground.quoteTextColor.opacity(0.5))
                            .frame(width: 3)
                        , alignment: .leading
                    )
                    
                    // Book details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.author)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedBackground.bookAuthorColor)
                        
                        Text(book.title)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(selectedBackground.bookTitleColor)
                    }
                    .frame(width: 452, alignment: .leading)
                }
                .padding(.all, 24)
                .frame(width: 500)
            }
            .padding(.top, 20)
        }
        .frame(width: 500)
        .transition(.opacity)
        .id(selectedBackground)
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
        
        let parsedQuote = ShareQuoteManager.parseQuote(book.quotes[selectedQuoteIndex])
        
        let exportView = createExportView(parsedQuote: parsedQuote, width: exportWidth, height: exportHeight)
        
        // Create filename from the quote
        let quoteWords = parsedQuote.quote.split(separator: " ").prefix(5).joined(separator: " ")
        let filename = "\(quoteWords)..."
        
        ShareQuoteManager.exportQuoteAsPNG(
            exportView: exportView,
            size: CGSize(width: exportWidth, height: exportHeight),
            cornerRadius: 16,
            filename: filename,
            scaleFactor: 2.0
        )
    }
    
    private func createExportView(parsedQuote: (quote: String, attribution: String?), width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            selectedBackground.backgroundColor
            
            VStack(alignment: .leading, spacing: 0) {
                // Quote icon
                Image(systemName: "quote.opening")
                    .font(.system(size: 24))
                    .foregroundColor(selectedBackground.quoteTextColor.opacity(0.3))
                    .padding(.bottom, 4)
                    .padding(.leading, 17)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Quote text and attribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text(parsedQuote.quote)
                            .font(.custom("Merriweather-Regular", size: 18))
                            .foregroundColor(selectedBackground.quoteTextColor)
                            .lineSpacing(7)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 16)
                            .frame(width: width - 48, alignment: .leading)
                        
                        if let attribution = parsedQuote.attribution, !attribution.isEmpty {
                            Text("— \(attribution)")
                                .font(.custom("Merriweather-Italic", size: 16))
                                .foregroundColor(selectedBackground.attributionTextColor)
                                .padding(.leading, 16)
                                .frame(width: width - 48, alignment: .leading)
                        }
                    }
                    .overlay(
                        Rectangle()
                            .fill(selectedBackground.quoteTextColor.opacity(0.5))
                            .frame(width: 3)
                        , alignment: .leading
                    )
                    
                    // Book details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.author)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedBackground.bookAuthorColor)
                        
                        Text(book.title)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(selectedBackground.bookTitleColor)
                    }
                    .frame(width: width - 48, alignment: .leading)
                }
                .padding(.all, 24)
                .frame(width: width)
            }
            .padding(.top, 20)
        }
        .frame(width: width, height: height)
        .environment(\.colorScheme, .light)
    }
}
