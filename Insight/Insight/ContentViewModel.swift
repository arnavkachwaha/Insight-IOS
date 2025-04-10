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
    case localOutput(testResults: VideoTestResults, testType: String)
    case loading
}

class ContentViewModel: ObservableObject {
    @Published var captureState: CaptureState = .loading
    @Published var currentView: String
    @Published var recordedVideoURL: URL?
    @Published var processedVideoURL: URL?
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
        recordingFinishedListener()
        videoProcessingFinishedListener()
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
    
    func uploadDataToServer() {
        DispatchQueue.global(qos: .background).async {
            NetworkService.shared.uploadDataToServer(results: self.testResults, testType: self.currentView)
        }
    }
    
    private func recordingFinishedListener() {
        NotificationCenter.default.publisher(for: .videoRecorded)
            .sink { [weak self] _ in
                if let recordedURL = self?.frameHandler.recordedVideoURL {
                    self?.recordedVideoURL = recordedURL
                    self?.captureState = .loading
                }
            }
            .store(in: &cancellables)
    }
    
    private func videoProcessingFinishedListener() {
        NotificationCenter.default.publisher(for: .videoProcessed)
            .sink { [weak self] _ in
                if let processedVidURL = self?.frameHandler.processedVideoURL,
                    let recordedVidURL = self?.frameHandler.recordedVideoURL,
                    let plotData = self?.frameHandler.plotData,
                    let irisBoundingBoxes = self?.frameHandler.irisBoundingBoxes,
                    let pupilBoundingBoxes = self?.frameHandler.pupilBoundingBoxes {
                    
                    switch self?.currentView {
                    case "PLR":
                        let (maxPD, minPD, latency, maxConstriction, seventyFivePercentRecovery, adv, acv) =
                        self?.frameHandler.getPlrMetrics(frameRadius: plotData) ?? (0.0, 0.0, "0", 0.0, "0", 0.0, 0.0)
                        self?.testResults.plrResults = VideoTestResults.PLRResults(videoURL: recordedVidURL, processedVideoURL: processedVidURL, plotData: plotData, maxPD: maxPD, minPD: minPD, latency: latency, maxConstriction: maxConstriction, seventyFivePercentRecovery: seventyFivePercentRecovery, adv: adv, acv: acv, irisData : irisBoundingBoxes, pupilData: pupilBoundingBoxes)
                        
                    case "VOMS":
                        self?.testResults.vomsResults = VideoTestResults.VOMSResults(videoURL: recordedVidURL, processedVideoURL: processedVidURL, plotData: plotData, irisData : irisBoundingBoxes, pupilData: pupilBoundingBoxes)
                        
                    default:
                        break
                    }
                    
                    self?.captureState = .localOutput(testResults : self?.testResults ?? VideoTestResults(), testType: self?.currentView ?? "PLR")
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchingVideoFinishedListener() {
        NotificationCenter.default.publisher(for: .graphFetched)
            .sink { [weak self] _ in
                if let videoURL = self?.processedVideoURL, let graphURL = NetworkService.shared.fetchedGraphURL {
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
