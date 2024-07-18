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
            ZStack {
                CameraView(frameHandler: frameHandler)
                EyeMask(yOffset: 200)
                HeaderView()
                FooterView(frameHandler: frameHandler)
            }
    }
}

#Preview {
    ContentView()
}
