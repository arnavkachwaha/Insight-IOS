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
                    Image(systemName: "circle.fill")
                        .font(.system(size: 50))
                        .offset(x: 175 , y: offset)
                    
                }
                .onAppear {
                    // Set the initial offset to center
                    offset = (geometry.size.height / 2.1)
                }
                .onChange(of: shouldAnimate) { oldValue, newValue in
                    if newValue {
                        startAnimation(screenHeight: geometry.size.height)
                    }
                }
            }
            .background(Color.clear)
        }.ignoresSafeArea()
    }
    
    private func startAnimation(screenHeight: CGFloat) {
        let screenHeight = UIScreen.main.bounds.height
        offset = screenHeight / 2.1 // Start at the center
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            withAnimation(
                Animation.linear(duration: 0.75).repeatCount(1)
            ) {
                offset = screenHeight
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(
                Animation.linear(duration: 1.5).repeatCount(4, autoreverses: true)
            ) {
                offset = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.75) {
            onAnimationEnd?()
        }
    }
}

#Preview {
    TrackerView_1(shouldAnimate: .constant(false), onAnimationEnd: nil)
}
