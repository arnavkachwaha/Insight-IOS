//
//  ContentViewModel.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 9/16/24.
//

import SwiftUI
import Combine

enum CaptureState {
    case recording
    case playback(videoURL: URL)
    case output(videoURL: URL, graphURL: URL)
    case loading
}

class ContentViewModel: ObservableObject {
    @Published var captureState: CaptureState = .loading
    @Published var currentView: String
    @Published var recordedVideoURL: URL?
    @Published var fetchedVideoURL: URL?
    @Published var fetchedGraphURL: URL?
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = "Internal Server Error: Restarting the current Session"
    
    var frameHandler: FrameHandler
    var testResults: VideoTestResults
    private var cancellables = Set<AnyCancellable>()
    
    init(frameHandler: FrameHandler, currentView: String, testResults: VideoTestResults) {
        self.frameHandler = frameHandler
        self.currentView = currentView
        self.testResults = testResults
        
        $currentView
            .sink { [weak self] newView in
                self?.frameHandler.currentView = newView
            }
            .store(in: &cancellables)
        startRecording()
        setupRecordingFinishedListener()
        fetchingVideoFinishedListener()
        setupTimeoutListener()
    }
    
    func startRecording() {
        frameHandler.startRecording()
        captureState = .recording
    }
    
    func stopRecording() {
        frameHandler.stopRecording()
    }
    
    func restartSession() {
        frameHandler.startSession()
        captureState = .recording
    }
    
    func switchViews(view: String) {
        currentView = view
        frameHandler.currentView = view
        restartSession()
    }
    
    func uploadAndFetchVideo() {
        frameHandler.uploadVideoToServer(videoURL: recordedVideoURL!, currentView: currentView)
        captureState = .loading
    }
    
    private func setupRecordingFinishedListener() {
        NotificationCenter.default.publisher(for: .videoRecorded)
            .sink { [weak self] _ in
                if let recordedURL = self?.frameHandler.recordedVideoURL {
                    self?.recordedVideoURL = recordedURL
                    self?.captureState = .playback(videoURL: recordedURL)
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchingVideoFinishedListener() {
        NotificationCenter.default.publisher(for: .videoFetched)
            .sink { [weak self] _ in
                if let videoURL = self?.frameHandler.fetchedVideoURL, let graphURL = self?.frameHandler.fetchedGraphURL {
                    switch self?.currentView {
                    case "PLR":
                        self?.testResults.plrResults = VideoTestResults.PLRResults(videoURL: videoURL, graphURL: graphURL)
                    case "VOMS":
                        self?.testResults.vomsResults = VideoTestResults.VOMSResults(videoURL: videoURL, graphURL: graphURL)
                    default:
                        break
                    }
                    self?.captureState = .output(videoURL: videoURL, graphURL: graphURL)
                }
            }
            .store(in: &cancellables)
    }
    
    func setupTimeoutListener() {
        NotificationCenter.default.publisher(for: .uploadTimeoutOccurred)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let message = notification.userInfo?["message"] as? String {
                    self?.alertMessage = message
                } else {
                    self?.alertMessage = "An unknown error occurred. Please try again."
                }
                self?.showAlert = true
            }
            .store(in: &cancellables)
    }
}
