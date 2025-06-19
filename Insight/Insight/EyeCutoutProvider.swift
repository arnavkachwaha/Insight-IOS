//
//  EyeCutoutProvider.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/4/25.
//

import Foundation
import SwiftUI

struct AnyEyeShape: Shape {
    private let _pathFunc: (CGRect) -> Path

    init<S: Shape>(_ wrapped: S) {
        self._pathFunc = { rect in
            wrapped.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _pathFunc(rect)
    }
}

struct EyePathProvider {
    static func makeShape(currentView: String, yOffset: CGFloat) -> AnyEyeShape {
        if currentView == "VOMS" {
            return AnyEyeShape(FlippedEye(yOffset: yOffset))
        } else {
            return AnyEyeShape(NormalEye(yOffset: yOffset))
        }
    }

    struct NormalEye: Shape {
        var yOffset: CGFloat

        func path(in rect: CGRect) -> Path {
            var p = Path()
            let width = rect.width / 1.15
            let height = rect.height / 2.15
            let xOffset = (rect.width - width) / 2

            p.move(to: CGPoint(x: xOffset, y: yOffset))
            p.addQuadCurve(
                to: CGPoint(x: xOffset + width, y: yOffset),
                control: CGPoint(x: xOffset + width/2, y: yOffset - height/2)
            )
            p.addQuadCurve(
                to: CGPoint(x: xOffset, y: yOffset),
                control: CGPoint(x: xOffset + width/2, y: yOffset + height/2)
            )

            return p
        }
    }

    struct FlippedEye: Shape {
        var yOffset: CGFloat

        func path(in rect: CGRect) -> Path {
            let normal = NormalEye(yOffset: yOffset)
            let rawPath = normal.path(in: rect)

            let w = rect.width
            let h = rect.height
            let center = CGPoint(x: w/2, y: h/2)

            var t = CGAffineTransform(translationX: center.x, y: center.y)
            t = t.rotated(by: .pi/2)
            t = t.translatedBy(x: -center.x, y: -center.y)

            let shiftLeft = CGAffineTransform(translationX: -w/2, y: 150)
            let finalTransform = t.concatenating(shiftLeft)

            return rawPath.applying(finalTransform)
        }
    }
}
