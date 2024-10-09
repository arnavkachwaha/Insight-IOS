//
//  FormView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 10/7/24.
//

import SwiftUI

struct FormView: View {
    @ObservedObject var frameHandler: FrameHandler
    @State private var age = ""
    @State private var selectedSex = "Male"
    @State private var concussionHistory = "No"
    let sex = ["Male", "Female"]
    let history = ["Yes", "No"]
    
    var body: some View {
        VStack{
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Age", text: $age)
                    Picker("Sex", selection: $selectedSex) {
                        ForEach(sex, id: \.self) {
                            Text($0)
                        }
                    }
                    Picker("Concussion History", selection: $concussionHistory) {
                        ForEach(history, id: \.self) {
                            Text($0)
                        }
                    }
                    Button(action: submit) {
                      Text("Submit")
                            .frame(width: 100, height: 30, alignment: .center)
                            .padding(.leading, 65)
                    }
                }
            }.frame(width: 300,height: 240, alignment: .center)
        }
    }
    
    func submit() {
        frameHandler.saveVideoToPhotos(age: age, sex: selectedSex, history: concussionHistory)
    }
}

#Preview {
    FormView(frameHandler: FrameHandler())
}
