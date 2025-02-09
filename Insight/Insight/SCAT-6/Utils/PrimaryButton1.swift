//
//  PrimaryButton 2.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/16/25.
//


import SwiftUI

struct PrimaryButton1<Destination: View>: View {
    var text: String
    var destination: Destination?
    var onPressed: (() -> Void)? = nil // Optional closure to handle custom actions
    
    var body: some View {
        Button(action: {
            onPressed?() // Call the onPressed action if provided
        }) {
            NavigationLink(destination: destination) {
                Text(text)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 150, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        PrimaryButton1(
            text: "Continue",
            destination: Text("Next View"),
            onPressed: {
                print("Button pressed")
            }
        )
    }
}
