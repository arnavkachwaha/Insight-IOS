//
//  HeaderView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//


import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("INSIGHT")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.blue)
                Spacer()
            }
            .foregroundColor(.clear)
            .padding(.all, 10)
        }
    }
}

#Preview {
    HeaderView()
}
