//
//  TestMenuView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/27/25.
//

import SwiftUI

struct TestMenuView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var Scat6Results = NeuroScreenResults()
    @StateObject private var VideoResults = VideoTestResults()
    @State private var tests = [
        ("PLR", "eye", false),
        ("VOMS", "hand.point.up", false),
        ("SCAT6", "doc.text", false)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 250/255, green: 250/255, blue: 250/255)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Assessments")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                
                ForEach(tests.indices, id: \.self) { index in
                    Button(action: {
                        navigationPath.append(tests[index].0)
                        tests[index].2 = true
                    }) {
                        VStack {
                            Image(systemName: tests[index].1)
                                .resizable()
                                .frame(width: index == 0 ? 160 : 80, height: 100)
                                .padding(.all, 10)
                            Text(tests[index].0)
                                .font(.headline)
                                .foregroundColor(tests[index].2 ? .gray : .black)
                        }
                        .frame(width: 290, height: 180)
                        .background(tests[index].2 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .disabled(tests[index].2)
                    .padding(.all, 10)
                }
                
                HStack {
                    Button(action: {
                        resetTests()
                    }) {
                        Text("Redo Tests")
                            .font(.headline)
                            .foregroundColor(tests.allSatisfy({ $0.2 }) ? Color.white : Color.accentColor)
                            .padding()
                            .frame(width: 130)
                            .background(tests.allSatisfy({ $0.2 }) ? Color.red : Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.all, 10)
                    .disabled(!tests.allSatisfy({ $0.2 }))
                    
                    Button(action: {
                        navigateToResults()
                    }) {
                        Text("Test Results")
                            .font(.headline)
                            .foregroundColor(tests.allSatisfy({ $0.2 }) ? Color.white : Color.accentColor)
                            .padding()
                            .frame(width: 130)
                            .background(tests.allSatisfy({ $0.2 }) ? Color.blue : Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.all, 10)
                    .disabled(!tests.allSatisfy({ $0.2 }))
                }
            }

        }
    }
    
    private func navigateToResults() {
        navigationPath.append("CombinedResults")
    }
    
    private func resetTests() {
        VideoResults.reset()
        Scat6Results.reset()
        for index in tests.indices {
            tests[index].2 = false
        }
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    return NavigationStack {
        TestMenuView(navigationPath: $navigationPath)
    }
}
