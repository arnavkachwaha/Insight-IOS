//
//  GlasgowComaScaleView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/16/25.
//

import SwiftUI

struct GlasgowComaScaleView: View {
    @ObservedObject var results: NeuroScreenResults
    @Binding var navigationPath: NavigationPath
    @State private var selectedEyeResponse: Int? = nil
    @State private var selectedVerbalResponse: Int? = nil
    @State private var selectedMotorResponse: Int? = nil
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // Header
                        ScatHeaderView(stepText: "Step Two", sectionTitle: "Glasgow Coma Scale")
                        
                        HStack {
                            Spacer()
                            Text("Please select one response for each section below.")
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.all, 10)
                            Spacer()
                        }
                        
                        SingleSelectResponseSection(
                            title: "Best Eye Response (E)",
                            options: ["No eye opening", "Eye opening to pain", "Eye opening to speech", "Eyes opening spontaneously"],
                            selectedOption: $selectedEyeResponse
                        )
                        
                        SingleSelectResponseSection(
                            title: "Best Verbal Response (V)",
                            options: ["No verbal response", "Incomprehensible sounds", "Inappropriate words", "Confused", "Oriented"],
                            selectedOption: $selectedVerbalResponse
                        )
                        
                        SingleSelectResponseSection(
                            title: "Best Motor Response (M)",
                            options: [
                                "No motor response",
                                "Extension to pain",
                                "Abnormal flexion to pain",
                                "Flexion/withdrawal to pain",
                                "Localized to pain",
                                "Obeys commands"
                            ],
                            selectedOption: $selectedMotorResponse
                        )
                        
                        HStack {
                            Spacer()
                            PrimaryButton1(
                                text: "Continue",
                                destination: CervicalSpineAssessmentView(results: results, navigationPath: $navigationPath)
                            ).padding(.trailing, 20)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.all, 1)
            }
        }
        .onDisappear {
            results.glasgowComaScore = (selectedEyeResponse ?? 0) +
            (selectedVerbalResponse ?? 0) +
            (selectedMotorResponse ?? 0)
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    GlasgowComaScaleView(results: NeuroScreenResults(), navigationPath: $navigationPath)
}
