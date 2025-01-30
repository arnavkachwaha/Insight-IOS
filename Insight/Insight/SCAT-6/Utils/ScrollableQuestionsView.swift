//
//  ScrollableQuestionsView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/16/25.
//

import SwiftUI

struct ScrollableQuestionsView: View {
    var questions: [String]
    @Binding var toggleStates: [Bool]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(questions.indices, id: \.self) { index in
                    QuestionToggleView(question: questions[index], isOn: $toggleStates[index])
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            .shadow(radius: 10)
            .padding(.horizontal)
        }
    }
}

#Preview {
    @Previewable @State var exampleStates = Array(repeating: false, count: 3)
    return ScrollableQuestionsView(
        questions: ["Question 1", "Question 2", "Question 3"],
        toggleStates: $exampleStates
    )
}

