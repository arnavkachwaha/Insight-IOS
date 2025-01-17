//
//  SingleSelectResponseSection.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

struct SingleSelectResponseSection: View {
    let title: String
    let options: [String]
    @Binding var selectedOption: Int? // Tracks the selected option
    
    var body: some View {
        SectionContainer {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.bottom, 5)
            
            ForEach(options.indices, id: \.self) { index in
                QuestionToggleView(
                    question: options[index],
                    isOn: Binding(
                        get: { selectedOption == index + 1 }, // Check if option selected
                        set: { isSelected in
                            selectedOption = isSelected ? index + 1 : nil // Update selected option
                        }
                    )
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedOption: Int? = nil
    return SingleSelectResponseSection(
        title: "Best Eye Response (E)",
        options: ["No eye opening", "Eye opening to pain", "Eye opening to speech", "Eyes opening spontaneously"],
        selectedOption: $selectedOption
    )
}
