//
//  MemoryAssessmentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

struct MemoryAssessmentView: View {
    @ObservedObject var results: NeuroScreenResults
    @Binding var navigationPath: NavigationPath
    @State private var questions = [
        "What venue are we at today?",
        "Which half is it now?",
        "Who scored last in this match?",
        "What team did you play last week/game?",
        "Did your team win the last game?"
    ]
    @State private var toggleStates = Array(repeating: false, count: 5)
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ScatHeaderView(stepText: "Step Five", sectionTitle: "Memory Assessment Maddocks Questions")
                        
                        HStack {
                            Spacer()
                            VStack {
                                Text("Begin the assessment after reading aloud the instructions:")
                                    .font(.system(size: 15, weight: .bold, design: .serif))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.all, 10)
                                
                                Text("“I am going to ask you a few questions, please listen carefully and give your best effort. First, tell me what happened?”")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.all, 10)
                            }
                            Spacer()
                        }
                        
                        SectionContainer {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("SELECT IF THEY RESPONDED CORRECTLY")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .padding(.all, 10)
                                }
                                Spacer()
                            }
                            ForEach(questions.indices, id: \.self) { index in
                                QuestionToggleView(question: questions[index], isOn: $toggleStates[index])
                            }
                        }
                        
                        HStack {
                            Spacer()
                            PrimaryButton1(
                                text: "Continue",
                                destination: NeuroScreenResultView(results: results, navigationPath: $navigationPath)
                            )
                            .padding(.trailing, 20)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.all, 1)
            }
        }
        .onDisappear {
            results.maddocksScore = toggleStates.filter { $0 }.count
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    MemoryAssessmentView(results: NeuroScreenResults(), navigationPath: $navigationPath)
}
