//
//  EyeMask.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 7/13/24.
//

import SwiftUI

struct EyeShape: Shape {
    var yOffset: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height / 2
        
        path.move(to: CGPoint(x: 0, y: yOffset))
        path.addQuadCurve(to: CGPoint(x: width, y: yOffset), control: CGPoint(x: width / 2, y: yOffset - height / 2))
        path.addQuadCurve(to: CGPoint(x: 0, y: yOffset), control: CGPoint(x: width / 2, y: yOffset + height / 2))
        return path
    }
}

struct EyeMask: View {
    var yOffset: CGFloat
    var body: some View {
        GeometryReader { geometry in
            Color.white.opacity(0.4)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .mask(
                    EyeShape(yOffset: yOffset)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                )
        }
    }
}

struct EyeMask_Previews: PreviewProvider {
    static var previews: some View {
        EyeMask(yOffset: 200).background(Color(uiColor: .black))
    }
}
