//
//  Observable_Signs.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/16/25.
//

import SwiftUI

struct ObservableSignsView: View {
    @ObservedObject var results: NeuroScreenResults
    @Binding var navigationPath: NavigationPath
    @State private var questions = [
        "Have you witnessed the injury in person?",
        "Lying motionless on playing surface",
        "Falling unprotected to the surface",
        "Balance/gait difficulties, motor incoordination, ataxia",
        "Disorientation or confusion",
        "Blank or vacant look",
        "Facial injury after head trauma",
        "Impact seizure",
        "High-risk mechanism of injury"
    ]
    @State private var toggleStates = Array(repeating: false, count: 9)
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ScatHeaderView(stepText: "Step One", sectionTitle: "Observable Signs")
                        
                        SectionContainer {
                            ForEach(questions.indices, id: \.self) { index in
                                QuestionToggleView(question: questions[index], isOn: $toggleStates[index])
                            }
                        }
                        
                        HStack {
                            Spacer()
                            PrimaryButton1(
                                text: "Continue",
                                destination: GlasgowComaScaleView(results: results, navigationPath: $navigationPath),
                                onPressed: {
                                    results.observableSignsCount = toggleStates.filter { $0 }.count
                                }
                            ).padding(.trailing, 20)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.all, 1)
            }
        }
        .onDisappear {
            results.observableSignsCount = toggleStates.filter { $0 }.count
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    ObservableSignsView(results: NeuroScreenResults(), navigationPath: $navigationPath)
}
