import SwiftUI

struct ReadingDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isRefreshing: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    ReadingInsightsView(books: dataManager.books)
                        .padding(.bottom, 4)
                    ReadingTrendsView(books: dataManager.books)
                        .padding(.bottom, 4)
                    MonthlyReadingChartView(books: dataManager.books)
                        .padding(.bottom, 4)
                    TopGenresChartView(books: dataManager.books)
                        .padding(.bottom, 4)
                    RecentActivityView(books: dataManager.books)
                }
                .padding(16)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    .help("Refresh")
                    .accessibilityLabel("Refresh")
                    .disabled(isRefreshing)
                }
            }
            
            if isRefreshing {
                ZStack {
                    Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        ProgressView("Refreshing...")
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    private func refresh() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isRefreshing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dataManager.fetchBooks()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isRefreshing = false
                }
            }
        }
    }
}
