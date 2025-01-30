//
//  NeuroScreenResults.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 1/17/25.
//

import SwiftUI

class NeuroScreenResults: ObservableObject {
    @Published var observableSignsCount: Int = 0
    @Published var cervicalSpineSignsCount: Int = 0
    @Published var ocularMotorSignsCount: Int = 0
    @Published var glasgowComaScore: Int = 0
    @Published var maddocksScore: Int = 0
    @Published var isSCAT6Completed = false
    func reset() {
        isSCAT6Completed = false
    }
}

