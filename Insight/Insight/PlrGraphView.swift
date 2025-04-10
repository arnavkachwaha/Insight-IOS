//
//  PlrGraphView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 4/1/25.
//

import SwiftUI
import Charts


// Data model for chart points.
struct DataPoint: Identifiable {
    let id = UUID()
    let time: Double
    let radius: Double
}

struct PlrGraphView: View {
    let radii: [Double]
    let fps: Double
    
    private var yAxisDomain: ClosedRange<Double> {
        let minVal = radii.min() ?? 0
        let maxVal = radii.max() ?? 1
        let lowerBound = max(0, minVal - 2)
        let upperBound = maxVal + 2
        return lowerBound...upperBound
    }
    
    var processedData: [DataPoint] {
        radii.enumerated().map { index, radius in
            DataPoint(time: Double(index) / fps, radius: radius)
        }
    }
    
    var body: some View {
        Chart {
            ForEach(processedData) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Radius", point.radius)
                )
            }
        }
        .chartYAxis {
            AxisMarks()
        }
        .chartYScale(domain: yAxisDomain)
        .chartXAxisLabel("Time (seconds)")
        .chartYAxisLabel("Radius")
        .frame(height: 300)
        .padding()
        
        
    }
}


#Preview {
    PlrGraphView(radii: [], fps: 30.0)
}
