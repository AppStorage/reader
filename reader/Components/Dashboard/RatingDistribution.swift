import SwiftUI
import Charts

struct RatingDistribution: View {
    let books: [BookData]
    
    private var ratingData: [RatingData] {
        BookStatisticsService.ratingDistribution(books: books)
            .map { RatingData(rating: $0.key, count: $0.value) }
            .sorted { $0.rating < $1.rating }
    }
    
    private var chart: some View {
        Group {
            if ratingData.isEmpty {
                EmptyStateView(
                    type: .chart,
                    isCompact: true,
                    icon: "star",
                    titleOverride: "No rating data available"
                )
            } else {
                RatingBarChart(ratingData: ratingData)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(title: "Ratings")
            chart
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
    }
}

// MARK: - Rating Bar Chart
private struct RatingData: Identifiable {
    let rating: Int
    let count: Int
    var id: Int { rating }
}

private struct RatingBarChart: View {
    @State private var selectedRating: RatingData?
    @State private var tooltipOffset: CGPoint = .zero
    
    let ratingData: [RatingData]

    private var totalCount: Int {
        ratingData.map { $0.count }.reduce(0, +)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Chart {
                ForEach(ratingData) { data in
                    BarMark(
                        x: .value("Rating", String(data.rating)),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(selectedRating?.rating == data.rating ? Color(red: 1.0, green: 1.0, blue: 0.2) : .yellow)
                    .cornerRadius(4)
                    .accessibilityLabel(Text("\(data.rating) stars"))
                    .accessibilityValue(Text("\(data.count) books"))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let ratingStr = value.as(String.self),
                           let ratingInt = Int(ratingStr) {
                            Text("\(ratingInt)") +
                            Text(" ★")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5]))
                    AxisValueLabel() {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard !ratingData.isEmpty,
                                          let plotFrame = proxy.plotFrame else {
                                        selectedRating = nil
                                        return
                                    }

                                    let origin = geometry[plotFrame].origin
                                    let localX = value.location.x - origin.x

                                    guard let ratingStr = proxy.value(atX: localX, as: String.self),
                                          let ratingInt = Int(ratingStr),
                                          let found = ratingData.first(where: { $0.rating == ratingInt }) else {
                                        selectedRating = nil
                                        return
                                    }

                                    // Position tooltip above bar
                                    let xPos = min(geometry.size.width - 150, max(0, localX - 50))
                                    let yPos = max(10, value.location.y - origin.y - 70)

                                    selectedRating = found
                                    tooltipOffset = CGPoint(x: xPos, y: yPos)
                                }
                        )
                }
            }
            .frame(height: 200)

            // Tooltip
            if let selected = selectedRating {
                VStack {
                    let percentage = totalCount > 0 ? Int(Double(selected.count) / Double(totalCount) * 100) : 0
                    
                    Text("\(selected.count) book\(selected.count == 1 ? "" : "s") (\(percentage)%)")
                        .font(.subheadline)
                }
                .padding()
                .background(.windowBackground)
                .cornerRadius(8)
                .offset(x: tooltipOffset.x, y: tooltipOffset.y)
            }
        }
        .padding(.vertical, 8)
    }
}
