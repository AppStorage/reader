import SwiftUI
import Charts

struct ReadingDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appState: AppState
    
    private let gridSpacing: CGFloat = 16
    private let sectionSpacing: CGFloat = 24
    
    private var secondaryColor: Color {
        switch appState.selectedTheme {
        case .dark:
            return .pink
        default:
            return Color(nsColor: NSColor.systemOrange)
        }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                insightsCards
                    .padding(.bottom, 4)
                readingTrendsView
                    .padding(.bottom, 4)
                monthlySummaryChart
                    .padding(.bottom, 4)
                topGenresChart
                    .padding(.bottom, 4)
                recentActivityPanel
            }
            .padding(16)
        }
        .scrollIndicators(.visible)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataManager.fetchBooks()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh dashboard data")
                .accessibilityLabel("Refresh")
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: Insights Cards
    private var insightsCards: some View {
        let monthlyComparison = BookStatisticsService.getBooksReadComparison(books: dataManager.books)
        let yearlyComparison = BookStatisticsService.getBooksReadYearlyComparison(books: dataManager.books)
        let completionTimes = calculateCompletionTimes()
        
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Reading Insights")
            
            GeometryReader { geometry in
                HStack(spacing: 16) {
                    // Books This Month
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.accentColor)
                            
                            Text("Books This Month")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(monthlyComparison.current)")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("books")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.accentColor)
                            
                            Text("Books This Year")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(yearlyComparison.current)")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("books")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
                    )
                    
                    if let avgCompletionDays = completionTimes.average {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.accentColor)
                                
                                Text("Average Reading Time")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(Int(avgCompletionDays))")
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("days")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
                        )
                    }
                }
            }
            .frame(height: 100)
        }
    }
    
    private func insightCard(
        title: String,
        value: Int,
        previousValue: Int? = nil,
        unit: String = "books",
        icon: String,
        width: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.accentColor)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: value)
                
                Text(unit)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
                
                Spacer()
                
                if let previousValue = previousValue {
                    comparisonIndicator(current: value, previous: previousValue)
                        .padding(.trailing, 4)
                }
            }
        }
        .padding(12)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    private func comparisonIndicator(current: Int, previous: Int) -> some View {
        let difference = current - previous
        let percentChange = previous > 0 ? (Double(difference) / Double(previous) * 100).rounded() : 0
        let isPositiveChange = difference >= 0
        
        return HStack(spacing: 4) {
            Image(systemName: isPositiveChange ? "arrow.up" : "arrow.down")
                .foregroundColor(isPositiveChange ? Color(nsColor: NSColor.systemGreen) : Color(nsColor: NSColor.systemRed))
            
            Text("\(abs(difference)) (\(abs(Int(percentChange)))%)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isPositiveChange ? Color(nsColor: NSColor.systemGreen) : Color(nsColor: NSColor.systemRed))
        }
        .opacity(previous > 0 ? 1.0 : 0.0)
        .accessibilityLabel(buildComparisonAccessibilityLabel(
            difference: difference, percentChange: percentChange))
    }
    
    private func buildComparisonAccessibilityLabel(difference: Int, percentChange: Double) -> String {
        let changeDirection = difference >= 0 ? "increase" : "decrease"
        return "\(abs(difference)) books \(changeDirection), \(abs(Int(percentChange))) percent \(changeDirection)"
    }
    
    // MARK: Reading Trends
    private var readingTrendsView: some View {
        let yearlyComparison = BookStatisticsService.getBooksReadYearlyComparison(books: dataManager.books)
        let currentMonth = Calendar.current.component(.month, from: Date())
        let averageBooksPerMonth = yearlyComparison.current > 0
        ? Double(yearlyComparison.current) / Double(currentMonth)
        : 0
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                sectionHeader("Reading Trends")
                
                Spacer()
                
                Picker("", selection: .constant(0)) {
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
            
            HStack(spacing: 24) {
                trendItem(
                    title: "Monthly Average",
                    value: String(format: "%.1f", averageBooksPerMonth),
                    unit: "books",
                    icon: "chart.xyaxis.line"
                )
                
                Divider().frame(height: 40)
                
                trendItem(
                    title: "This Year",
                    value: "\(yearlyComparison.current)",
                    unit: "books",
                    icon: "calendar"
                )
                
                if yearlyComparison.previous > 0 {
                    Divider().frame(height: 40)
                    
                    trendItem(
                        title: "Last Year",
                        value: "\(yearlyComparison.previous)",
                        unit: "books",
                        icon: "calendar.badge.clock",
                        color: secondaryColor
                    )
                }
                
                Divider().frame(height: 40)
                
                let currentYear = Calendar.current.component(.year, from: Date())
                let remainingMonths = 12 - currentMonth
                
                trendItem(
                    title: "Projected \(currentYear)",
                    value: String(format: "%.0f", Double(yearlyComparison.current) + (averageBooksPerMonth * Double(remainingMonths))),
                    unit: "books",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(nsColor: NSColor.systemBlue)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    private func trendItem(
        title: String,
        value: String,
        unit: String,
        icon: String? = nil,
        color: Color? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(color ?? Color.accentColor)
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(color ?? Color.accentColor)
                
                Text(unit)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var readingStreakText: String? {
        let currentStreak = calculateReadingStreak(books: dataManager.books)
        return currentStreak > 0
        ? "You've read \(currentStreak) consecutive month\(currentStreak == 1 ? "" : "s") with at least one book!"
        : nil
    }
    
    private func calculateReadingStreak(books: [BookData]) -> Int {
        let longestStreak = BookStatisticsService.getLongestReadingStreak(books: books)
        return longestStreak
    }
    
    // MARK: Monthly Summary
    private var monthlySummaryChart: some View {
        let monthlyData = BookStatisticsService.getMonthlyReadingData(books: dataManager.books).toMonthlyData()
        
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Monthly Reading")
            
            if monthlyData.isEmpty {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.bottom, 8)
                    
                    Text("No monthly reading data available")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack {
                    Chart {
                        ForEach(monthlyData) { month in
                            LineMark(
                                x: .value("Month", month.month),
                                y: .value("Books", month.count)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .symbol {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                            }
                            .interpolationMethod(.catmullRom)
                        }
                        
                        ForEach(monthlyData) { month in
                            PointMark(
                                x: .value("Month", month.month),
                                y: .value("Books", month.count)
                            )
                            .foregroundStyle(Color.accentColor)
                            .annotation(position: .top) {
                                if month.count > 0 {
                                    Text("\(month.count)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5, dash: [5]))
                            AxisValueLabel() {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel() {
                                if let strValue = value.as(String.self) {
                                    Text(strValue)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: Top Genres
    private var topGenresChart: some View {
        let genreData = BookStatisticsService.getTopGenres(books: dataManager.books).toGenreData()
        
        let colorPalette = [
            Color(nsColor: NSColor.systemBlue),
            Color(nsColor: NSColor.systemPurple),
            Color(nsColor: NSColor.systemGreen),
            Color(nsColor: NSColor.systemOrange),
            Color(nsColor: NSColor.systemTeal),
            Color(nsColor: NSColor.systemPink),
            Color(nsColor: NSColor.systemIndigo)
        ]
        
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Top Genres")
            
            if genreData.isEmpty {
                VStack {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.bottom, 8)
                    
                    Text("No genre data available")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(alignment: .leading) {
                    Chart(genreData) { genre in
                        BarMark(
                            x: .value("Books", genre.count),
                            y: .value("Genre", genre.genre)
                        )
                        .foregroundStyle(by: .value("Genre", genre.genre))
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text("\(genre.count)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .chartForegroundStyleScale(range: colorPalette)
                    .chartLegend(.hidden)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel() {
                                if let genre = value.as(String.self) {
                                    Text(genre)
                                        .font(.system(size: 11))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5, dash: [5]))
                            AxisValueLabel() {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(genreData.count * 35 + 50), 200))
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: Recent Activity
    private var recentActivityPanel: some View {
        let recentBooks = getRecentlyFinishedBooks()
        
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recently Finished Books")
            
            if !recentBooks.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(recentBooks.prefix(5), id: \.id) { book in
                            recentActivityItem(book: book)
                        }
                    }
                }
                .frame(height: 180)
            } else {
                VStack {
                    Image(systemName: "book.closed")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.bottom, 8)
                    
                    Text("No recently finished books")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    private func recentActivityItem(book: BookData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 16))
                .foregroundColor(Color.accentColor.opacity(0.9))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("by \(book.author)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let dateFinished = book.dateFinished {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(dateFinished))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    if let genre = book.genre, !genre.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(genre)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if let dateStarted = book.dateStarted, let dateFinished = book.dateFinished {
                let days = Calendar.current.dateComponents([.day], from: dateStarted, to: dateFinished).day ?? 0
                if days > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(days) day\(days == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getRecentlyFinishedBooks() -> [BookData] {
        dataManager.books
            .filter { $0.dateFinished != nil }
            .sorted {
                ($0.dateFinished ?? Date.distantPast) > ($1.dateFinished ?? Date.distantPast)
            }
    }
    
    private func calculateCompletionTimes() -> (
        average: Double?, fastest: Double?, fastestBook: String?,
        totalBooksWithDates: Int
    ) {
        let booksWithBothDates = dataManager.books.filter {
            $0.dateStarted != nil && $0.dateFinished != nil
        }
        
        let completionTimes = booksWithBothDates.map { book -> (title: String, days: Double) in
            let start = book.dateStarted ?? Date()
            let finish = book.dateFinished ?? Date()
            let days = Calendar.current.dateComponents([.day], from: start, to: finish).day ?? 0
            return (title: book.title, days: max(Double(days), 1))
        }
        
        if completionTimes.isEmpty {
            return (average: nil, fastest: nil, fastestBook: nil, totalBooksWithDates: 0)
        }
        
        let avgDays = completionTimes.map { $0.days }.reduce(0, +) / Double(completionTimes.count)
        let fastestBook = completionTimes.min { $0.days < $1.days }
        
        return (
            average: avgDays,
            fastest: fastestBook?.days,
            fastestBook: fastestBook?.title,
            totalBooksWithDates: completionTimes.count
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .accessibilityAddTraits(.isHeader)
    }
}

extension Color {
    static var random: Color {
        let colors: [Color] = [
            .blue, .purple, .green, .orange, .teal, .pink, .red
        ]
        return colors.randomElement() ?? .blue
    }
}

extension BookStatisticsService {
    struct MonthlyData: Identifiable {
        let id = UUID()
        let month: String
        let count: Int
        
        init(month: String, count: Int) {
            self.month = month
            self.count = count
        }
    }
    
    struct GenreData: Identifiable {
        let id = UUID()
        let genre: String
        let count: Int
        
        init(genre: String, count: Int) {
            self.genre = genre
            self.count = count
        }
    }
}

extension Array where Element == (month: String, count: Int) {
    func toMonthlyData() -> [BookStatisticsService.MonthlyData] {
        let monthOrder = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let sortedData = self.sorted { first, second in
            guard let firstIndex = monthOrder.firstIndex(of: first.month),
                  let secondIndex = monthOrder.firstIndex(of: second.month) else {
                return false
            }
            return firstIndex < secondIndex
        }
        
        return sortedData.map { BookStatisticsService.MonthlyData(month: $0.month, count: $0.count) }
    }
}

extension Array where Element == (genre: String, count: Int) {
    func toGenreData() -> [BookStatisticsService.GenreData] {
        let sortedData = self.sorted { $0.count > $1.count }
        return sortedData.map { BookStatisticsService.GenreData(genre: $0.genre, count: $0.count) }
    }
}
