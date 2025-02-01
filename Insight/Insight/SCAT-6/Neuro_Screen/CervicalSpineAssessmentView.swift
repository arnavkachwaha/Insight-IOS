//
//  CervicalSpineAssessmentView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

struct CervicalSpineAssessmentView: View {
    @ObservedObject var results: NeuroScreenResults
    @Binding var navigationPath: NavigationPath
    @State private var questions = [
        "Does the athlete report neck pain at rest?",
        "Is there tenderness to palpation?",
        "If NO neck pain and NO tenderness, does the athlete have a full range of ACTIVE pain free movement?",
        "Are limb strength and sensation normal?"
    ]
    @State private var toggleStates = Array(repeating: false, count: 4)
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ScatHeaderView(stepText: "Step Three", sectionTitle: "Cervical Spine Assessment")
                        
                        HStack {
                            Spacer()
                            Text("In a patient who is not lucid or fully conscious, a cervical spine injury should be assumed and spinal precautions taken.")
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.all, 10)
                            Spacer()
                        }
                        
                        SectionContainer {
                            ForEach(questions.indices, id: \.self) { index in
                                QuestionToggleView(question: questions[index], isOn: $toggleStates[index])
                            }
                        }
                        
                        HStack {
                            Spacer()
                            PrimaryButton1(
                                text: "Continue",
                                destination: MotorScreenView(results: results, navigationPath: $navigationPath)
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
            results.cervicalSpineSignsCount = toggleStates.filter { $0 }.count
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    CervicalSpineAssessmentView(results: NeuroScreenResults(), navigationPath: $navigationPath)
}
