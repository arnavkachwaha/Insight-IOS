//
//  QuestionToggle.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/16/25.
//

import SwiftUI

struct QuestionToggleView: View {
    var question: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            // Text takes the max width available
            Text(question)
                .font(.body)
                .fontWeight(.regular)
                .multilineTextAlignment(.leading)
                .padding(.leading, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil) 
                .fixedSize(horizontal: false, vertical: true)
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                .padding(.leading, 15)
                .fixedSize()
        }
        .padding(.all, 10)
    }
}

#Preview {
    @Previewable @State var exampleToggle: Bool = false
    return QuestionToggleView(question: "Example Question?", isOn: $exampleToggle)
}
