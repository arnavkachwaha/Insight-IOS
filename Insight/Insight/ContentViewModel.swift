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
    @Published var isFetchingVideo: Bool = false
    @Published var isVideoFetched: Bool = false
    @Published var fetchedVideoURL: URL?
    @Published var fetchedGraphURL: URL?
    @Published var recordedVideoURL: URL?

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
    }

    func stopRecording() {
        isRecording = false
        frameHandler.stopRecording()
    }

    func restartSession() {
        resetFlags()
        frameHandler.startSession()
    }
    
    func resetFlags() {
        isVideoFetched = false
        isFetchingVideo = false
        isRecording = true
    }
    
    func uploadAndFetchVideo() {
        isFetchingVideo = true
        frameHandler.uploadVideoToServer(videoURL: recordedVideoURL!)
    }

    private func setupRecordingFinishedListener() {
        NotificationCenter.default.publisher(for: .videoRecorded)
            .sink { [weak self] _ in
                self?.recordedVideoURL = self?.frameHandler.recordedVideoURL
                self?.isRecording = false
            }
            .store(in: &cancellables)
    }
    
    private func fetchingVideoFinishedListener() {
        NotificationCenter.default.publisher(for: .videoFetched)
            .sink { [weak self] _ in
                self?.fetchedVideoURL = self?.frameHandler.fetchedVideoURL
                self?.fetchedGraphURL = self?.frameHandler.fetchedGraphURL
                self?.isFetchingVideo = false
                self?.isVideoFetched = true
            }
            .store(in: &cancellables)
    }
}
