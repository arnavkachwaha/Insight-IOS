//
//  vomsGraphView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 4/9/25.
//

import SwiftUI
import Charts

struct VomsGraphView: View {
    let plotData: [Double]
    let fps: Double

    struct DataPoint: Identifiable {
        let id = UUID()
        let time: Double
        let value: Double
    }

    var dataPoints: [DataPoint] {
        plotData.enumerated().map { (index, value) in
            let time = Double(index) / fps * 1000
            return DataPoint(time: time, value: value)
        }
    }

    private var yAxisDomain: ClosedRange<Double> {
        let minVal = plotData.min() ?? 0
        let maxVal = plotData.max() ?? 1
        return (minVal - 10)...(maxVal + 10)
    }

    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time (ms)", point.time),
                    y: .value("Iris Center X", point.value)
                )
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: yAxisDomain)
        .chartXAxisLabel("Time (ms)")
        .chartYAxisLabel("Iris Center X (Normalized)")
        .frame(height: 300)
        .padding()
    }
}

#Preview {
    VomsGraphView(plotData: [100, 102, 105, 107, 106, 104, 103, 102, 101, 103, 105, 107, 110, 107, 105], fps: 30)
}
