//
//  TrackerView-1.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/15/25.
//

import SwiftUI
import Combine

struct TrackerView_1: View {
    @State private var offset: CGFloat = 0
    @State private var countdown: Int = 3
    @State private var showCountdownText: Bool = true
    @State private var timerSubscription: AnyCancellable? = nil
    @State var shouldAnimate: Bool = false
    var onAnimationEnd: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color(red: 240/255, green: 240/255, blue: 240/255).edgesIgnoringSafeArea(.all)
            GeometryReader { geometry in
                ZStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 50))
                        .offset(x: 175 , y: offset)
                        .overlay(
                            Group {
                                if showCountdownText {
                                    Text("Start Following the ball in:")
                                        .font(.largeTitle)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .rotationEffect(.degrees(90))
                                        .offset(x: 280, y: 380)
                                        .transition(.opacity)

                                    Text("\(countdown)")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .rotationEffect(.degrees(90))
                                        .offset(x: 175, y: offset)
                                        .transition(.opacity)
                                }
                            }
                        )
                }
                .onAppear {
                    // Set the initial offset to center
                    offset = (geometry.size.height / 2.1)
                    startCountdownTimer(screenHeight: geometry.size.height)
                }
                .onDisappear {
                    stopTimer()
                }
                .onChange(of: shouldAnimate) { oldValue, newValue in
                    if newValue && !showCountdownText {
                        startAnimation(screenHeight: geometry.size.height)
                    }
                }
            }
            .background(Color.clear)
        }.ignoresSafeArea()
    }
    
    private func startCountdownTimer(screenHeight: CGFloat) {
        guard timerSubscription == nil else { return }

        countdown = 3
        showCountdownText = true

        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    self.showCountdownText = false
                    self.stopTimer()
                    self.shouldAnimate = true
                }
            }
    }

    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
        print("Countdown Timer stopped.")
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
    TrackerView_1(onAnimationEnd: nil)
}
