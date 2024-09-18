//
//  ContentViewModel.swift
//  Insight
//
//  Created by Arnav Singh Kachwaha on 9/16/24.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    @Published var isRecording: Bool = true
    @Published var videoURL: URL?

    var frameHandler: FrameHandler

    private var cancellables = Set<AnyCancellable>()

    init(frameHandler: FrameHandler) {
        self.frameHandler = frameHandler
        startRecording()
        setupRecordingFinishedListener()
    }

    func startRecording() {
        frameHandler.startRecording()
    }

    func stopRecording() {
        frameHandler.stopRecording()
    }

    func stopSession() {
        frameHandler.stopSession()
    }
    
    func restartSession() {
        frameHandler.startSession()
        isRecording = true
    }

    private func setupRecordingFinishedListener() {
        NotificationCenter.default.publisher(for: .recordingFinished)
            .sink { [weak self] _ in
                self?.videoURL = self?.frameHandler.recordedVideoURL
                self?.isRecording = false
            }
            .store(in: &cancellables)
    }
}
