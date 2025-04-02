//
//  TestMenuView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/27/25.
//

import SwiftUI

struct TestMenuView: View {
    @Binding var navigationPath: NavigationPath
    @ObservedObject var VideoResults: VideoTestResults
    @ObservedObject var Scat6Results: NeuroScreenResults
    
    @State private var tests = [
        ("PLR", "eye"),
        ("VOMS", "hand.point.up"),
        ("SCAT6", "doc.text")
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
                
                ForEach(tests, id: \.0) { test in
                    Button(action: {
                        navigationPath.append(test.0)
                    }) {
                        VStack {
                            Image(systemName: test.1)
                                .resizable()
                                .frame(width: test.0 == "PLR" ? 160 : 80, height: 100)
                                .padding(10)
                                .foregroundColor(isTestCompleted(testName: test.0) ? .gray : .blue)
                            Text(test.0)
                                .font(.headline)
                                .foregroundColor(isTestCompleted(testName: test.0) ? .gray : .black)
                        }
                        .frame(width: 290, height: 180)
                        .background(isTestCompleted(testName: test.0) ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .disabled(test.0 == "VOMS" || isTestCompleted(testName: test.0))
                    .padding(10)
                }
                
                HStack {
                    Button(action: {
                        resetTests()
                    }) {
                        Text("Redo Tests")
                            .font(.headline)
                            .foregroundColor(allTestsCompleted ? Color.white : Color.accentColor)
                            .padding()
                            .frame(width: 130)
                            .background(allTestsCompleted ? Color.red : Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(10)
                    .disabled(!allTestsCompleted)
                    
                    Button(action: {
                        navigateToResults()
                    }) {
                        Text("Test Results")
                            .font(.headline)
                            .foregroundColor(allTestsCompleted ? Color.white : Color.accentColor)
                            .padding()
                            .frame(width: 130)
                            .background(allTestsCompleted ? Color.blue : Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(10)
                    .disabled(!allTestsCompleted)
                }
            }
        }
    }
    
    private func isTestCompleted(testName: String) -> Bool {
        switch testName {
        case "PLR":
            return VideoResults.plrResults != nil
        case "VOMS":
            return true
        case "SCAT6":
            return Scat6Results.isSCAT6Completed
        default:
            return false
        }
    }
    
    private var allTestsCompleted: Bool {
        tests.allSatisfy { isTestCompleted(testName: $0.0) }
    }
    
    private func navigateToResults() {
        navigationPath.append("CombinedResults")
    }
    
    private func resetTests() {
        VideoResults.reset()
        Scat6Results.reset()
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    @Previewable @State var videoTestResults = VideoTestResults()
    @Previewable @State var scat6Results = NeuroScreenResults()
    TestMenuView(navigationPath: $navigationPath, VideoResults: videoTestResults, Scat6Results: scat6Results)
}
