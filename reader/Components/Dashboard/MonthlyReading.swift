import SwiftUI
import Charts

// MARK: - Line Chart View
struct MonthlyReading: View {
    @State private var selectedPosition: ChartHighlightPosition? = nil

    let books: [BookData]

    private let currentYear = DateFormatterUtils.currentYear
    private let previousYear = DateFormatterUtils.previousYear

    private var currentYearData: [MonthlyData] {
        monthlyData(for: currentYear)
    }

    private var previousYearData: [MonthlyData] {
        monthlyData(for: previousYear)
    }

    private var header: some View {
        HStack {
            DashboardSectionHeader(title: "Monthly Reading")

            Spacer()

            ChartLegend(items: [
                (label: "\(currentYear)", color: Color(red: 0.99, green: 0.46, blue: 0.44)),
                (label: "\(previousYear)", color: Color(red: 0.49, green: 0.69, blue: 0.84))
            ])
        }
    }

    private var chart: some View {
        Group {
            if currentYearData.isEmpty && previousYearData.isEmpty {
                EmptyStateView(
                    type: .chart,
                    isCompact: true,
                    icon: "chart.line.uptrend.xyaxis",
                    titleOverride: "No monthly reading data available"
                )
            } else {
                LineChart(
                    selectedPosition: $selectedPosition,
                    currentYearData: currentYearData,
                    previousYearData: previousYearData,
                    currentYear: currentYear,
                    previousYear: previousYear
                )
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            chart
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
    }

    private func monthlyData(for year: Int) -> [MonthlyData] {
        let rawData = BookStatisticsService.getMonthlyReadingData(books: books, forYear: year)
        return BookStatisticsService.toMonthlyData(from: rawData)
    }
}

// MARK: - Monthly Reading Chart Legend
private struct ChartLegend: View {
    let items: [(label: String, color: Color)]
    
    var body: some View {
        ForEach(items, id: \.label) { item in
            HStack {
                Circle()
                    .fill(item.color)
                    .frame(width: 8, height: 8)
                
                Text(item.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Monthly Reading Line Chart
struct ChartHighlightPosition {
    let month: String
    let currentYearValue: Int?
    let previousYearValue: Int?
    let tooltipOffset: CGPoint
}

private struct LineChart: View {
    @Binding var selectedPosition: ChartHighlightPosition?
    
    let currentYearData: [MonthlyData]
    let previousYearData: [MonthlyData]
    let currentYear: Int
    let previousYear: Int
    
    private var hasData: Bool {
        !currentYearData.isEmpty || !previousYearData.isEmpty
    }
    
    private var currentYearColor: Color {
        Color(red: 0.99, green: 0.46, blue: 0.44)
    }

    private var previousYearColor: Color {
        Color(red: 0.49, green: 0.69, blue: 0.84)
    }
    
    private var currentYearLine: some ChartContent {
        ForEach(currentYearData) { month in
            LineMark(
                x: .value("Month", month.month),
                y: .value("Count", month.count)
            )
            .foregroundStyle(by: .value("Year", String(currentYear)))
            .interpolationMethod(.catmullRom)
            .symbol {
                Circle()
                    .fill(currentYearColor)
                    .frame(width: 8, height: 8)
            }

            AreaMark(
                x: .value("Month", month.month),
                y: .value("Count", month.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                .linearGradient(
                    Gradient(colors: [currentYearColor.opacity(0.4), currentYearColor.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private var previousYearLine: some ChartContent {
        ForEach(previousYearData) { month in
            LineMark(
                x: .value("Month", month.month),
                y: .value("Count", month.count)
            )
            .foregroundStyle(by: .value("Year", String(previousYear)))
            .interpolationMethod(.catmullRom)
            .symbol {
                Circle()
                    .fill(previousYearColor)
                    .frame(width: 8, height: 8)
            }

            AreaMark(
                x: .value("Month", month.month),
                y: .value("Count", month.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                .linearGradient(
                    Gradient(colors: [previousYearColor.opacity(0.3), previousYearColor.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Chart {
                currentYearLine
                previousYearLine
                
                if let position = selectedPosition {
                    if position.currentYearValue != nil {
                        PointMark(
                            x: .value("Month", position.month),
                            y: .value("Count", position.currentYearValue!)
                        )
                        .foregroundStyle(currentYearColor)
                        .symbolSize(CGSize(width: 12, height: 12))
                    }
                    
                    if position.previousYearValue != nil {
                        PointMark(
                            x: .value("Month", position.month),
                            y: .value("Count", position.previousYearValue!)
                        )
                        .foregroundStyle(previousYearColor)
                        .symbolSize(CGSize(width: 12, height: 12))
                    }
                    
                    RuleMark(x: .value("Month", position.month))
                        .foregroundStyle(.gray.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .chartForegroundStyleScale([
                "\(currentYear)": currentYearColor,
                "\(previousYear)": previousYearColor
            ])
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel() {
                        if let strValue = value.as(String.self) {
                            Text(strValue)
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
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding()
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    updateSelection(at: value.location, geometry: geometry, proxy: proxy)
                                }
                                .onEnded { _ in
                                    // Keep selection on drag end
                                }
                        )
                        .onTapGesture { location in
                            updateSelection(at: location, geometry: geometry, proxy: proxy)
                        }
                        .onHover { isHovering in
                            if !isHovering {
                                selectedPosition = nil
                            }
                        }
                }
            }
            
            // Tooltip
            if let position = selectedPosition {
                VStack(alignment: .leading, spacing: 6) {
                    Text(position.month)
                        .font(.subheadline)
                    
                    if let currentValue = position.currentYearValue {
                        HStack {
                            Circle()
                                .fill(currentYearColor)
                                .frame(width: 8, height: 8)
                            
                            Text(String(format: "%d", currentYear) + ": \(currentValue) book\(currentValue == 1 ? "" : "s")")
                                .font(.caption)
                        }
                    }
                    
                    if let previousValue = position.previousYearValue {
                        HStack {
                            Circle()
                                .fill(previousYearColor)
                                .frame(width: 8, height: 8)
                            
                            Text(String(format: "%d", previousYear) + ": \(previousValue) book\(previousValue == 1 ? "" : "s")")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(.windowBackground)
                .cornerRadius(8)
                .offset(x: position.tooltipOffset.x, y: position.tooltipOffset.y)
            }
        }
    }
    
    private func updateSelection(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        guard !currentYearData.isEmpty || !previousYearData.isEmpty else {
            selectedPosition = nil
            return
        }

        guard let plotFrame = proxy.plotFrame else {
            return
        }
        
        let origin = geometry[plotFrame].origin
        
        guard let month = proxy.value(atX: location.x - origin.x, as: String.self) else {
            return
        }
        
        let currentYearPoint = currentYearData.first(where: { $0.month == month })
        let previousYearPoint = previousYearData.first(where: { $0.month == month })
        
        if currentYearPoint != nil || previousYearPoint != nil {
            let currentValue = currentYearPoint?.count
            let previousValue = previousYearPoint?.count
            
            let xPos = min(geometry.size.width - 150, max(0, location.x - origin.x - 50))
            let yPos = max(10, min(geometry.size.height - 100, location.y - origin.y - 70))
            
            selectedPosition = ChartHighlightPosition(
                month: month,
                currentYearValue: currentValue,
                previousYearValue: previousValue,
                tooltipOffset: CGPoint(x: xPos, y: yPos)
            )
        }
    }
}
