//
//  ServerEndpoints.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 3/28/25.
//

import Foundation

struct ServerEndpoints {
    static let baseURL = "http://a8a175088b809630c.awsglobalaccelerator.com:8000/cyclops/"
//    static let baseURL = "http://192.168.4.108:8000/cyclops/"
    static let uploadVideoPLR = baseURL + "upload_video_plr/"
    static let uploadVideoVOMS = baseURL + "upload_video_voms/"
    static let uploadTestResult = baseURL + "upload_test_data/"
}
