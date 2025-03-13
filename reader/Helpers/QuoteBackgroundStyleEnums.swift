import SwiftUI

enum QuoteBackgroundStyle: String, CaseIterable, Identifiable {
    case light
    case sepia
    case dark
    
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
