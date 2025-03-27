import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isRefreshing: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    ReadingInsights(books: dataManager.books)
                        .padding(.bottom, 4)
                    ReadingTrends(books: dataManager.books)
                        .padding(.bottom, 4)
                    MonthlyReading(books: dataManager.books)
                        .padding(.bottom, 4)
                    RatingDistribution(books: dataManager.books)
                        .padding(.bottom, 4)
                    RecentBooks(books: dataManager.books)
                }
                .padding(16)
            }
            .navigationTitle("Dashboard")
        }
    }
}
