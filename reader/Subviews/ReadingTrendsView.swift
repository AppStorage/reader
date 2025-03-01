import SwiftUI

struct ReadingTrendsView: View {
    let books: [BookData]
    @State private var timeScale: Int = 0 // 0: This Year, 1: All Time
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                DashboardSectionHeader("Reading Trends")
                
                Spacer()
                
                Picker("Time Scale", selection: $timeScale) {
                    Text("This Year").tag(0)
                    Text("All Time").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .frame(width: 150)
            }
            
            if let streakText = readingStreakText {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(nsColor: NSColor.systemOrange))
                    
                    Text(streakText)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            trendMetricsRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    private var trendMetricsRow: some View {
        let yearlyComparison = BookStatisticsService.getBooksReadYearlyComparison(books: books)
        let currentMonth = Calendar.current.component(.month, from: Date())
        let averageBooksPerMonth = yearlyComparison.current > 0
        ? Double(yearlyComparison.current) / Double(currentMonth)
        : 0
        let currentYear = Calendar.current.component(.year, from: Date())
        let remainingMonths = 12 - currentMonth
        let projectedTotal = Double(yearlyComparison.current) + (averageBooksPerMonth * Double(remainingMonths))
        
        return HStack(spacing: 24) {
            TrendMetricView(
                title: "Monthly Average",
                value: String(format: "%.1f", averageBooksPerMonth),
                unit: "books",
                icon: "chart.xyaxis.line"
            )
            
            Divider().frame(height: 40)
            
            TrendMetricView(
                title: "This Year",
                value: "\(yearlyComparison.current)",
                unit: "books",
                icon: "calendar"
            )
            
            if yearlyComparison.previous > 0 {
                Divider().frame(height: 40)
                
                TrendMetricView(
                    title: "Last Year",
                    value: "\(yearlyComparison.previous)",
                    unit: "books",
                    icon: "calendar.badge.clock"
                )
            }
            
            Divider().frame(height: 40)
            
            TrendMetricView(
                title: "Projected \(currentYear)",
                value: String(format: "%.0f", projectedTotal),
                unit: "books",
                icon: "chart.line.uptrend.xyaxis",
                color: Color(nsColor: NSColor.systemBlue)
            )
        }
    }
    
    private var readingStreakText: String? {
        let currentStreak = calculateReadingStreak(books: books)
        return currentStreak > 0
        ? "You've read \(currentStreak) consecutive month\(currentStreak == 1 ? "" : "s") with at least one book!"
        : nil
    }
    
    private func calculateReadingStreak(books: [BookData]) -> Int {
        let longestStreak = BookStatisticsService.getLongestReadingStreak(books: books)
        return longestStreak
    }
}
