import SwiftUI
import Charts

struct TopGenresChartView: View {
    let books: [BookData]
    
    var body: some View {
        let genreData = BookStatisticsService.getTopGenres(books: books).toGenreData()
        
        return VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader("Top Genres")
            
            if genreData.isEmpty {
                EmptyChartPlaceholder(
                    icon: "books.vertical",
                    message: "No genre data available"
                )
            } else {
                GenreBarChart(genreData: genreData)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    private struct GenreBarChart: View {
        let genreData: [BookStatisticsService.GenreData]
        
        private let colorPalette = [
            Color(nsColor: NSColor.systemBlue),
            Color(nsColor: NSColor.systemPurple),
            Color(nsColor: NSColor.systemGreen),
            Color(nsColor: NSColor.systemOrange),
            Color(nsColor: NSColor.systemTeal),
            Color(nsColor: NSColor.systemPink),
            Color(nsColor: NSColor.systemIndigo)
        ]
        
        var body: some View {
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
}
