//
//  TrackerView-1.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/15/25.
//

import SwiftUI

struct TrackerView_1: View {
    @State private var offset: CGFloat = 0
    @Binding var shouldAnimate: Bool
    var onAnimationEnd: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color(red: 240/255, green: 240/255, blue: 240/255).edgesIgnoringSafeArea(.all)
            GeometryReader { geometry in
                ZStack {
                    Image(systemName: "hand.point.right.fill")
                        .font(.system(size: 300))
                        .offset(x: 20 , y: offset)
                    
                }
                .onAppear {
                    // Set the initial offset to center
                    offset = (geometry.size.height / 3.5)
                }
                .onChange(of: shouldAnimate) { oldValue, newValue in
                    if newValue {
                        startAnimation(screenHeight: geometry.size.height)
                    }
                }
            }
            .background(Color.clear)
        }
    }
    
    private func startAnimation(screenHeight: CGFloat) {
        offset = screenHeight / 3.5 // Start at the center
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            withAnimation(
                Animation.linear(duration: 1).repeatCount(1)
            ) {
                offset = screenHeight - 100
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(
                Animation.linear(duration: 2).repeatCount(3, autoreverses: true)
            ) {
                offset = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            withAnimation(
                Animation.linear(duration: 1).repeatCount(1)
            ) {
                offset = screenHeight / 3.5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            onAnimationEnd?()
        }
    }
}

#Preview {
    TrackerView_1(shouldAnimate: .constant(false), onAnimationEnd: nil)
}
