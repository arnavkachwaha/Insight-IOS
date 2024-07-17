//
//  HeaderView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 6/25/24.
//


import SwiftUI

struct HeaderView: View {
    var body: some View {
            HStack {
    //            Button(action: {
    //                // No action for now
    //            }) {
    //                Image(systemName: "chevron.backward.circle")
    //                    .resizable()
    //                    .frame(width: 30, height: 30)
    //                    .padding(10)
    //            }

                Spacer()
                Text("INSIGHT")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.blue)
                Spacer()
    //            Button(action: {
    //                // No action for now
    //            }) {
    //                Image(systemName: "chevron.forward.circle")
    //                    .resizable()
    //                    .frame(width: 30, height: 30)
    //                    .padding(10)
    //            }
            }.foregroundColor(.clear)
    }
}

#Preview {
    HeaderView()
}
