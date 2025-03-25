import SwiftUI
import Charts

struct RatingDistribution: View {
    let books: [BookData]

    var body: some View {
        let ratingData = BookStatisticsService.ratingDistribution(books: books)
            .map { RatingData(rating: $0.key, count: $0.value) }
            .sorted { $0.rating < $1.rating }

        return VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader("Ratings")

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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
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

    var totalCount: Int {
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
                    .foregroundStyle(data.count > 0 ? .yellow : .gray.opacity(0.3))
                    .cornerRadius(4)
                    .accessibilityLabel(Text("\(data.rating) stars"))
                    .accessibilityValue(Text("\(data.count) books"))
                }

                if let selected = selectedRating, selected.count > 0 {
                    RuleMark(x: .value("Selected Rating", String(selected.rating)))
                        .foregroundStyle(.gray.opacity(0.3))

                    PointMark(
                        x: .value("Selected Rating", String(selected.rating)),
                        y: .value("Count", selected.count)
                    )
                    .foregroundStyle(.yellow)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if let plotFrame = proxy.plotFrame {
                                    let origin = geometry[plotFrame].origin
                                    let localX = value.location.x - origin.x
                                    if let ratingStr = proxy.value(atX: localX, as: String.self),
                                       let ratingInt = Int(ratingStr),
                                       let found = ratingData.first(where: { $0.rating == ratingInt }) {
                                        
                                        // Position tooltip above bar
                                        let xPos = min(geometry.size.width - 150, max(0, value.location.x - origin.x - 50))
                                        let yPos = max(10, value.location.y - origin.y - 70)

                                        selectedRating = found
                                        tooltipOffset = CGPoint(x: xPos, y: yPos)
                                    } else {
                                        selectedRating = nil
                                    }
                                }
                            }
                        )
                }
            }
            .frame(height: 200)

            // Tooltip
            if let selected = selectedRating {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("★")
                            .foregroundColor(.yellow)
                        Text("\(selected.rating)")
                            .font(.caption)
                            .bold()
                    }

                    Text("\(selected.count) book\(selected.count == 1 ? "" : "s") (\(Int(Double(selected.count) / Double(totalCount) * 100))%)")
                        .font(.caption)
                }
                .padding(8)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
                .shadow(radius: 2)
                .offset(x: tooltipOffset.x, y: tooltipOffset.y)
            }
        }
        .padding(.vertical, 8)
    }
}
