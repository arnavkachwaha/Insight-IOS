//
//  NeuroScreenResultView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

struct NeuroScreenResultView: View {
    @ObservedObject var results: NeuroScreenResults
    @Binding var navigationPath: NavigationPath
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        // Header
                        ScatHeaderView(stepText: nil, sectionTitle: "Neuro Screen Results")
                        
                        // Summary Section
                        SectionContainer {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Summary")
                                    .font(.system(size: 35, weight: .bold, design: .serif))
                                    .padding(.bottom, 10)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Observable Signs: \(results.observableSignsCount)")
                                    Text("Cervical Spine Signs: \(results.cervicalSpineSignsCount)")
                                    Text("Ocular/Motor Signs: \(results.ocularMotorSignsCount)")
                                    Text("Glasgow Coma Score: \(results.glasgowComaScore)")
                                    Text("Maddocks Score: \(results.maddocksScore)/5")
                                }
                                .font(.system(size: 28, weight: .medium, design: .serif))
                                .multilineTextAlignment(.leading)
                            }
                        }
                        
                        //Red Flags
                        SectionContainer {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Red Flags:")
                                    .font(.system(size: 35, weight: .bold, design: .serif))
                                    .foregroundColor(.red)
                                    .padding(.bottom, 10)
                                
                                Text("""
                                    • Neck pain or tenderness
                                    • Seizure or convulsion
                                    • Double vision
                                    • Loss of consciousness
                                    • Weakness or tingling/
                                       burning in more than 1 arm or 
                                       in the legs
                                    • Deteriorating conscious state
                                    • Vomiting
                                    • Severe or increasing headache
                                    • Increasingly restless, agitated 
                                       or combative
                                    • GCS <15
                                    • Visible deformity of the skull
                                    """)
                                .font(.system(size: 20, weight: .medium, design: .serif))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Spacer()
                            
                            Button(action:{
                                results.isSCAT6Completed = true
                                navigationPath.removeLast(navigationPath.count)
                            }){
                                Text("Proceed")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 150, height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                    }
                }
                .padding(.all, 1)
            }
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    NeuroScreenResultView(results: NeuroScreenResults(), navigationPath: $navigationPath)
}
