//
//  NetworkService.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 3/27/25.
//

import Foundation
import CoreGraphics

class NetworkService {
    @Published var fetchedGraphURL: URL?
    static let shared = NetworkService()
    private init() {}
    
    func uploadDataToServer(results: VideoTestResults, testType: String) {
        let endpoint = ServerEndpoints.uploadTestResult
        guard let serverURL = URL(string: endpoint) else { return }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        // Append testType as "currentView".
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"testType\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(testType)\r\n".data(using: .utf8)!)
        
        // We use a unique ID if needed – here omitted for brevity.
        // Determine which results to send based on testType.
        if testType == "PLR", let plr = results.plrResults {
            // Append video file
            if let videoURL = plr.videoURL, let videoData = try? Data(contentsOf: videoURL) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"videofile\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
                body.append(videoData)
                body.append("\r\n".data(using: .utf8)!)
            }
            // Append plotData
            if let plotData = plr.plotData, let jsonData = try? JSONSerialization.data(withJSONObject: plotData, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"plotData\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(jsonString)\r\n".data(using: .utf8)!)
            }
            // Append fps
            if let fps = plr.fps {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"fps\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(fps)\r\n".data(using: .utf8)!)
            }
            // Append PLR-specific metrics
            if let maxPD = plr.maxPD {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"maxPD\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(maxPD)\r\n".data(using: .utf8)!)
            }
            if let minPD = plr.minPD {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"minPD\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(minPD)\r\n".data(using: .utf8)!)
            }
            if let latency = plr.latency {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"latency\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(latency)\r\n".data(using: .utf8)!)
            }
            if let maxConstriction = plr.maxConstriction {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"maxConstriction\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(maxConstriction)\r\n".data(using: .utf8)!)
            }
            if let seventyFivePercentRecovery = plr.seventyFivePercentRecovery {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"seventyFivePercentRecovery\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(seventyFivePercentRecovery)\r\n".data(using: .utf8)!)
            }
            if let adv = plr.adv {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"adv\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(adv)\r\n".data(using: .utf8)!)
            }
            if let acv = plr.acv {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"acv\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(acv)\r\n".data(using: .utf8)!)
            }
        } else if testType == "VOMS", let voms = results.vomsResults {
            // Append video file for VOMS
            if let videoURL = voms.videoURL, let videoData = try? Data(contentsOf: videoURL) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"videofile\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
                body.append(videoData)
                body.append("\r\n".data(using: .utf8)!)
            }
            // Append plotData and fps for VOMS.
            if let plotData = voms.plotData, let jsonData = try? JSONSerialization.data(withJSONObject: plotData, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"plotData\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(jsonString)\r\n".data(using: .utf8)!)
            }
            if let fps = voms.fps {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"fps\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(fps)\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body as Data
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 120
        sessionConfig.timeoutIntervalForResource = 120
        let session = URLSession(configuration: sessionConfig)
        
        let task = session.uploadTask(with: request, from: body as Data) { data, response, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
            } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Upload successful!")
            } else {
                print("Unexpected response")
            }
        }
        
        print("Request URL: \(serverURL)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        task.resume()
    }
    
    private func uploadVideo(videoURL: URL,
                             currentView: String,
                             id: String) {
        // Select endpoint based on currentView.
        let endpoint: String = (currentView == "PLR") ?
            ServerEndpoints.uploadVideoPLR : ServerEndpoints.uploadVideoVOMS
        
        guard let serverURL = URL(string: endpoint) else { return }
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        // Append currentView field.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"currentView\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(currentView)\r\n".data(using: .utf8)!)
        
        // Append the unique Id field.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"Id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(id)\r\n".data(using: .utf8)!)
        
        // Append the video file.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"videofile\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
        
        if let videoData = try? Data(contentsOf: videoURL) {
            body.append(videoData)
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body as Data
        
        // Debug print the request body as a string.
        if let bodyString = String(data: body as Data, encoding: .utf8) {
            print("Video Upload Request Body:\n\(bodyString)")
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 120
        sessionConfig.timeoutIntervalForResource = 120
        let session = URLSession(configuration: sessionConfig)
        
        let task = session.uploadTask(with: request, from: body as Data) { _, _, error in
            if let error = error {
                print("Error uploading video: \(error)")
            } else {
                print("Video upload completed")
            }
        }
        
        print("Request URL: \(serverURL)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")

        task.resume()
    }
    
    // MARK: - Response Helpers
    
    private func fetchGraph(downloadURL: URL) {
        let task = URLSession.shared.downloadTask(with: downloadURL) { localURL, response, error in
            if let error = error {
                print("Error fetching graph: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Failed to fetch graph: Server returned status code \(httpResponse.statusCode)")
                return
            }
            guard let localURL = localURL else {
                print("No graph downloaded")
                return
            }
            if let movedURL = Helper.moveMediaToDocumentsDirectory(localURL, desiredFileName: "graph.png") {
                DispatchQueue.main.async {
                    self.fetchedGraphURL = movedURL
                    NotificationCenter.default.post(name: .graphFetched, object: movedURL)
                    Helper.saveGraph(url: movedURL)
                    print("Graph fetched and moved successfully: \(movedURL)")
                }
            }
        }
        task.resume()
    }
}
