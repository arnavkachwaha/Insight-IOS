//
//  CustomBackButton.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 2/16/25.
//
import SwiftUI

struct CustomBackButton: View {
    let label: String?  // Customize the label text if needed
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing : 4) {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.blue)
                    .font(.subheadline)
//                if let label = label {
//                    Text(label)
//                        .foregroundColor(.blue)
//                        .font(.title)
//                }
            }.padding(.leading, 10)
        }
    }
}

extension View {
    func withCustomBackButton(label: String? = "Back") -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CustomBackButton(label: label)
                }
            }
    }
}


#Preview {
    CustomBackButton(label: "Back")
}
