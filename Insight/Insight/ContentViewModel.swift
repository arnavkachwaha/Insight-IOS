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
    @Published var currentView: String = "PLR"
    @Published var recordedVideoURL: URL?
    @Published var fetchedVideoURL: URL?
    @Published var fetchedGraphURL: URL?

    var frameHandler: FrameHandler
    private var cancellables = Set<AnyCancellable>()

    init(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
        startRecording()
        setupRecordingFinishedListener()
        fetchingVideoFinishedListener()
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
                    self?.captureState = .output(videoURL: videoURL, graphURL: graphURL)
                }
            }
            .store(in: &cancellables)
    }
}
