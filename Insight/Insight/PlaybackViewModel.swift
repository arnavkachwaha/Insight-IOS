//
//  PlaybackViewModel.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 9/19/24.
//

import Foundation
import CoreImage
import AVFoundation

class PlaybackViewModel: ObservableObject {
    let videoURL: URL
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
}
//    func uploadRecordedVideo() {
//        self.uploadVideoToServer(videoURL: videoURL) { success in
//            if success {
//                print("Video uploaded successfully")
//            } else {
//                print("Failed to upload video")
//            }
//        }
//    }
//
//    // Sends the recorded video to the server
//    private func uploadVideoToServer(videoURL: URL, completion: @escaping (Bool) -> Void) {
//        let serverURL = URL(string: "http://192.168.4.108:8000/cyclops/upload/")!
////        let serverURL = URL(string: "http://10.243.44.193:8000/cyclops/upload/")!
//        var request = URLRequest(url: serverURL)
//        request.httpMethod = "POST"
//        
//        let boundary = UUID().uuidString
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        let body = NSMutableData()
//        
//        // Append the file as multipart form data
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"videofile\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
//        body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
//
//        // Add the video data
//        if let videoData = try? Data(contentsOf: videoURL) {
//            body.append(videoData)
//        }
//
//        body.append("\r\n".data(using: .utf8)!)
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//
//        request.httpBody = body as Data
//        
//        let task = URLSession.shared.uploadTask(with: request, from: body as Data) { data, response, error in
//            if let error = error {
//                print("Error uploading video: \(error)")
//                completion(false)
//            } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
//                print("Upload successful")
//                completion(true)
//            } else {
//                print("Upload failed with unexpected response")
//                completion(false)
//            }
//        }
//        
//        task.resume()
//    }



