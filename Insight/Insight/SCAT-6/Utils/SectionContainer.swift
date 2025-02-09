//
//  SectionContainer.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

struct SectionContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    SectionContainer {
        Text("Sample Section")
        Text("This is a reusable container for sections.")
    }
}
