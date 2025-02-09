//
//  ScatHeaderView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/16/25.
//

import SwiftUI

struct ScatHeaderView: View {
    var stepText: String?
    var sectionTitle: String
    var onBack: (() -> Void)? // Optional closure for back button action
    
    var body: some View {
        VStack {
            // Navigation header with step text
            HStack {
                //                Button(action: {
                //                    onBack?() // Call the back action if provided
                //                }) {
                //                    Image(systemName: "chevron.backward.circle")
                //                        .resizable()
                //                        .frame(width: 25, height: 25)
                //                        .padding(.leading, 20)
                //                }
                Spacer()
                if let stepText = stepText {
                    Text(stepText)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                    //                        .padding(.trailing, 50)
                }
                Spacer()
            }
            .padding(.all, 5)
            
            // Section title
            HStack {
                Text(sectionTitle)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
            }
            .padding(.all, 5)
        }
    }
}

#Preview {
    ScatHeaderView(stepText: "Step One", sectionTitle: "Observable Signs") {
        print("Back button tapped")
    }
}
