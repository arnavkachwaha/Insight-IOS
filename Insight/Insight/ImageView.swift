//
//  ImageView.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 2/1/25.
//

import SwiftUI

struct ImageView: View {
    var imageUrl: URL?
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 385, height: 250)
                .cornerRadius(20)
            
            if let imageUrl = imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 375, height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
        }
        .padding(.all, 2.5)
    }
}

#Preview {
    ImageView()
}
