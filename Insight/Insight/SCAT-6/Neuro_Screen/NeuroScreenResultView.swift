//
//  NeuroScreenResultView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

struct NeuroScreenResultView: View {
    @ObservedObject var results: NeuroScreenResults
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        // Header
                        ScatHeaderView(stepText: nil, sectionTitle: "Neuro Screen Results")
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Red Flags:")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .padding(.bottom, 10)
                            
                            Text("""
                                • Neck pain or tenderness
                                • Seizure or convulsion
                                • Double vision
                                • Loss of consciousness
                                • Weakness or tingling/burning in more than 1 arm or in the legs
                                • Deteriorating conscious state
                                • Vomiting
                                • Severe or increasing headache
                                • Increasingly restless, agitated or combative
                                • GCS <15
                                • Visible deformity of the skull
                                """)
                            .font(.system(size: 20, weight: .medium, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        
                        .padding(.horizontal)
                        
                        // Summary Section
                        SectionContainer {
                            VStack(alignment: .center, spacing: 10) {
                                Text("Summary")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .padding(.bottom, 10)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Observable Signs: \(results.observableSignsCount)")
                                    Text("Cervical Spine Signs: \(results.cervicalSpineSignsCount)")
                                    Text("Ocular/Motor Signs: \(results.ocularMotorSignsCount)")
                                    Text("Glasgow Coma Score: \(results.glasgowComaScore)")
                                    Text("Maddocks Score: \(results.maddocksScore)/5")
                                }
                                .font(.system(size: 20, weight: .medium, design: .serif))
                                .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.all, 1)
            }
        }
    }
}

#Preview {
    NeuroScreenResultView(results: NeuroScreenResults())
}
