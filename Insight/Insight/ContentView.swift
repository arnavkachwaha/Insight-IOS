//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

//
//  ContentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel(frameHandler: FrameHandler())

    var body: some View {
        switch viewModel.currentView {
        case "PLR", "VOMS":
            CaptureView(viewModel: viewModel)
        case "SCAT6":
            SCAT6View()
        default:
            LoadingView()
        }
    }
}

#Preview {
    ContentView()
}
