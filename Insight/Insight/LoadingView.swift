//
//  LoadingView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 9/23/24.
//

import SwiftUI

struct LoadingView: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack {
            Image(systemName: "eye")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear {
                    isPulsing = true
                }
            Text("Loading...")
                .padding(.top, 10)
                .foregroundColor(.black)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 240/255, green: 240/255, blue: 240/255))
        .edgesIgnoringSafeArea(.all)
    }
}


#Preview {
    LoadingView()
}
