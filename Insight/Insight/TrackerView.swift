//
//  TrackerVew.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 12/22/24.
//

import SwiftUI

struct TrackerView: View {
    @State private var offset: CGFloat = 0 
    @Binding var shouldAnimate: Bool
    var onAnimationEnd: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 70, height: 70)
                    .offset(x: offset, y: geometry.size.height - 300)
                
                Image(systemName: "hand.point.up")
                    .font(.system(size: 70))
                    .offset(x: offset + 5, y: geometry.size.height - 228)
            }
            .onAppear {
                // Set the initial offset to center
                offset = (geometry.size.width - 70) / 2
            }
            .onChange(of: shouldAnimate) { oldValue, newValue in
                if newValue {
                    startAnimation(screenWidth: geometry.size.width)
                }
            }
        }
        .background(Color.clear)
    }
    
    private func startAnimation(screenWidth: CGFloat) {
        offset = (screenWidth - 70) / 2 // Start at the center
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            withAnimation(
                Animation.linear(duration: 1.0).repeatCount(1)
            ) {
                offset = screenWidth - 50
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(
                Animation.linear(duration: 2.0).repeatCount(3, autoreverses: true)
            ) {
                offset = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            withAnimation(
                Animation.linear(duration: 1.0).repeatCount(1)
            ) {
                offset = (screenWidth - 70) / 2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            onAnimationEnd?()
        }
    }
}

#Preview {
    TrackerView(shouldAnimate: .constant(false), onAnimationEnd: nil)
}
