//
//  CustomNavigationTitle .swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 2/16/25.
//

import SwiftUI

struct CustomNavigationTitle: View {
    let mainTitle: String
    let subtitle: String?
    
    var body: some View {
        VStack(spacing: 10) {
            Text(mainTitle)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.primary)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
            }
        }.padding(.horizontal, 10)
    }
}

extension View {
    func withCustomNavigationTitle(mainTitle: String, subtitle: String? = nil) -> some View {
        self.toolbar {
            ToolbarItem(placement: .principal) {
                CustomNavigationTitle(mainTitle: mainTitle, subtitle: subtitle)
            }
        }
    }
}


#Preview {
    CustomNavigationTitle(mainTitle: "Hello", subtitle: "World")
}
