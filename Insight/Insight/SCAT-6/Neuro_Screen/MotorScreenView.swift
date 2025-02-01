//
//  MotorScreenView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

struct MotorScreenView: View {
    @ObservedObject var results: NeuroScreenResults
    @Binding var navigationPath: NavigationPath
    @State private var isFingerToNoseNormal: Bool = false
    @State private var canLookWithoutDoubleVision: Bool = false
    @State private var areEyeMovementsNormal: Bool = false
    @State private var extraocularDescription: String = ""
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ScatHeaderView(stepText: "Step Four", sectionTitle: "Coordination & Ocular/Motor Screen")
                        
                        SectionContainer {
                            Text("CONCUSSION")
                                .font(.system(size: 25, weight: .bold, design: .serif))
                                .padding(.bottom, 10)
                            
                            QuestionToggleView(
                                question: "Is finger-to-nose normal for both hands with eyes open and closed?",
                                isOn: $isFingerToNoseNormal
                            )
                        }
                        
                        SectionContainer {
                            Text("OCULAR/MOTOR")
                                .font(.system(size: 25, weight: .bold, design: .serif))
                                .padding(.bottom, 10)
                            
                            QuestionToggleView(
                                question: "Without moving their head or neck, can the patient look side-to-side and up-and-down without double vision?",
                                isOn: $canLookWithoutDoubleVision
                            )
                            
                            QuestionToggleView(
                                question: "Are observed extraocular eye movements normal? If not, please describe below:",
                                isOn: $areEyeMovementsNormal
                            )
                            
                            if !areEyeMovementsNormal {
                                ZStack(alignment: .topLeading) {
                                    // TextEditor
                                    TextEditor(text: $extraocularDescription)
                                        .padding(8)
                                        .frame(minHeight: 100)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                            
                        }
                        
                        HStack {
                            Spacer()
                            PrimaryButton1(
                                text: "Continue",
                                destination: MemoryAssessmentView(results: results, navigationPath: $navigationPath)
                            )
                            
                            .padding(.trailing, 20)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.all, 1)
            }
        }
        .onDisappear {
            results.ocularMotorSignsCount = (isFingerToNoseNormal ? 1 : 0) +
            (canLookWithoutDoubleVision ? 1 : 0) +
            (areEyeMovementsNormal ? 1 : 0)
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    MotorScreenView(results: NeuroScreenResults(), navigationPath: $navigationPath)
}
