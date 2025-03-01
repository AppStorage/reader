import SwiftUI
import Charts

struct MonthlyReadingChartView: View {
    let books: [BookData]
    @State private var selectedPosition: ChartHighlightPosition? = nil
    
    var body: some View {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let previousYear = currentYear - 1
        
        let currentYearData = BookStatisticsService.getMonthlyReadingData(
            books: books,
            forYear: currentYear
        ).toMonthlyData()
        
        let previousYearData = BookStatisticsService.getMonthlyReadingData(
            books: books,
            forYear: previousYear
        ).toMonthlyData()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                DashboardSectionHeader("Monthly Reading")
                
                Spacer()
                
                ChartLegend(items: [
                    (label: "\(currentYear)", color: Color.accentColor),
                    (label: "\(previousYear)", color: Color(nsColor: NSColor.systemOrange))
                ])
            }
            
            if currentYearData.isEmpty && previousYearData.isEmpty {
                EmptyChartPlaceholder(
                    icon: "chart.line.uptrend.xyaxis",
                    message: "No monthly reading data available"
                )
            } else {
                InteractiveChart(
                    currentYearData: currentYearData,
                    previousYearData: previousYearData,
                    currentYear: currentYear,
                    previousYear: previousYear,
                    selectedPosition: $selectedPosition
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
    
    private struct InteractiveChart: View {
        let currentYearData: [BookStatisticsService.MonthlyData]
        let previousYearData: [BookStatisticsService.MonthlyData]
        let currentYear: Int
        let previousYear: Int
        @Binding var selectedPosition: ChartHighlightPosition?
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                Chart {
                    ForEach(currentYearData) { month in
                        LineMark(
                            x: .value("Month", month.month),
                            y: .value("Count", month.count)
                        )
                        .foregroundStyle(by: .value("Year", String(currentYear)))
                        .interpolationMethod(.catmullRom)
                        .symbol {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 7, height: 7)
                        }
                    }
                    
                    ForEach(previousYearData) { month in
                        LineMark(
                            x: .value("Month", month.month),
                            y: .value("Count", month.count)
                        )
                        .foregroundStyle(by: .value("Year", String(previousYear)))
                        .interpolationMethod(.catmullRom)
                        .symbol {
                            Circle()
                                .fill(Color(nsColor: NSColor.systemOrange))
                                .frame(width: 5, height: 5)
                        }
                    }
                    
                    if let position = selectedPosition {
                        if position.currentYearValue != nil {
                            PointMark(
                                x: .value("Month", position.month),
                                y: .value("Count", position.currentYearValue!)
                            )
                            .foregroundStyle(Color.accentColor)
                            .symbolSize(CGSize(width: 12, height: 12))
                        }
                        
                        if position.previousYearValue != nil {
                            PointMark(
                                x: .value("Month", position.month),
                                y: .value("Count", position.previousYearValue!)
                            )
                            .foregroundStyle(Color(nsColor: NSColor.systemOrange))
                            .symbolSize(CGSize(width: 12, height: 12))
                        }
                        
                        RuleMark(x: .value("Month", position.month))
                            .foregroundStyle(.gray.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
                .chartForegroundStyleScale([
                    "\(currentYear)": Color.accentColor,
                    "\(previousYear)": Color(nsColor: NSColor.systemOrange)
                ])
                .chartLegend(.hidden)
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
                
                if let position = selectedPosition {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(position.month)
                            .font(.caption)
                            .bold()
                            .padding(.bottom, 2)
                        
                        if let currentValue = position.currentYearValue {
                            HStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                                Text(String(format: "%d", currentYear) + ": \(currentValue) book\(currentValue == 1 ? "" : "s")")
                                    .font(.caption)
                            }
                        }
                        
                        if let previousValue = position.previousYearValue {
                            HStack {
                                Circle()
                                    .fill(Color(nsColor: NSColor.systemOrange))
                                    .frame(width: 8, height: 8)
                                Text(String(format: "%d", previousYear) + ": \(previousValue) book\(previousValue == 1 ? "" : "s")")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .offset(x: position.tooltipOffset.x, y: position.tooltipOffset.y)
                }
            }
        }
        
        private func updateSelection(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
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
}

struct ChartHighlightPosition {
    let month: String
    let currentYearValue: Int?
    let previousYearValue: Int?
    let tooltipOffset: CGPoint
}
