//
//  TestMenuView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/27/25.
//

import SwiftUI

struct TestMenuView: View {
    @State private var tests = [
        ("PLR", "eye", false),
        ("VOMS", "hand.point.up", false),
        ("SCAT6", "doc.text", false)
    ]
    @StateObject private var results = NeuroScreenResults()
    @StateObject private var viewModel = ContentViewModel(frameHandler: FrameHandler())
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Assessments")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.all, 10)
                
                // Loop through the test buttons
                ForEach(tests.indices, id: \.self) { index in
                    NavigationLink(
                        destination: getDestination(for: tests[index].0)
                            .onDisappear {
                                tests[index].2 = true // Mark test as completed when navigating back
                            }
                    ) {
                        VStack {
                            Image(systemName: tests[index].1)
                                .resizable()
                                .frame(width: index == 0 ? 160 : 80, height: 100)
                                .padding(.all, 10)
                            Text(tests[index].0)
                                .font(.headline)
                                .foregroundColor(tests[index].2 ? .gray : .primary)
                        }
                        .frame(width: 290, height: 180)
                        .background(tests[index].2 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .disabled(tests[index].2)
                    .padding(.all, 10)
                }
                
                // Test Results and Redo Tests Buttons
                HStack {
                    // Redo Tests Button
                    Button(action: {
                        resetTests()
                    }) {
                        Text("Redo Tests")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 130)
                            .background(tests.allSatisfy({ $0.2 }) ? Color.red : Color.gray)
                            .cornerRadius(10)
                    }
                    .padding(.all, 10)
                    .disabled(!tests.allSatisfy({ $0.2 }))
                    
                    // Test Results Button
                    Button(action: {
                        navigateToResults()
                    }) {
                        Text("Test Results")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 130)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.all, 10)
                }
            }
        }
    }
    
    private func getDestination(for test: String) -> some View {
        switch test {
        case "PLR", "VOMS":
            return AnyView(CaptureView(viewModel: viewModel))
        case "SCAT6":
            return AnyView(
                NavigationStack {
                    ObservableSignsView(results: results)
                        .navigationBarBackButtonHidden(true)
                }
            )
        default:
            return AnyView(Text("Unknown Test"))
        }
    }

    
    private func navigateToResults() {
        print("Navigating to Test Results")
    }
    
    private func resetTests() {
        for index in tests.indices {
            tests[index].2 = false
        }
    }
}

#Preview {
    NavigationStack {
        TestMenuView()
    }
}
