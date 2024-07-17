//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var frameHandler = FrameHandler()
    
    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            ZStack {
                CameraView(frameHandler: frameHandler)
                EyeMask(yOffset: 200)
            }
            Spacer()
            FooterView(frameHandler: frameHandler)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
