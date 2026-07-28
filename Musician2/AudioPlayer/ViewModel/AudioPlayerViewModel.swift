//
//  AudioPlayerViewModel.swift
//  Musician2
//
//  Created by Maksim Ivanov on 20.07.2026.
//

import Foundation
import Observation

@MainActor
protocol AudioPlayerViewModel {

    var track: Track { get }
    var state: AudioPlayerState { get }
    var progress: Double { get }
    var currentTime: TimeInterval { get }
    var timeDisplay: String { get }
    var progressValue: Double { get }

    func loadTrack() async
    func play()
}

enum AudioPlayerState: Equatable {
    case initial, loading, loaded, playing, paused, error
}

@Observable
final class AudioPlayerViewModelImpl: AudioPlayerViewModel {

    let track: Track

    private(set) var state: AudioPlayerState = .initial

    private(set) var progress = 0.0

    private(set) var currentTime: TimeInterval = 0.0

    var timeDisplay: String {
        isActive ? formattedTime(currentTime) : track.duration
    }

    var progressValue: Double {
        isActive ? progress : 1.0
    }

    private var data: Data?

    private let dataLoader: NetworkDataLoader

    private var audioPlayerAPI: AudioPlayerAPI

    private let timerAPI: TimerAPI

    init(
        track: Track,
        dataLoader: NetworkDataLoader,
        audioPlayerAPI: AudioPlayerAPI,
        timerAPI: TimerAPI
    ) {
        self.track = track
        self.dataLoader = dataLoader
        self.audioPlayerAPI = audioPlayerAPI
        self.timerAPI = timerAPI
        self.audioPlayerAPI.delegate = self
    }

    // MARK: - Track loading

    @MainActor
    func loadTrack() async {
        guard let url = URL(string: track.url) else {
            state = .error
            return
        }

        state = .loading

        do {
            data = try await dataLoader.download(url)
            state = .loaded
        } catch {
            state = .error
        }
    }

    // MARK: - Playback control

    @MainActor
    func play() {
        guard let data else { return }

        do {
            switch state {
            case .loaded, .paused:
                try startPlayback(with: data)

            case .playing:
                pausePlayback()

            default:
                break
            }
        } catch {
            state = .error
        }
    }

    @MainActor
    private func startPlayback(with data: Data) throws {
        if state == .loaded {
            try audioPlayerAPI.initialize(with: data)
        }

        audioPlayerAPI.play()
        state = .playing
        timerAPI.stop()
        startProgressTimer()
    }

    @MainActor
    private func pausePlayback() {
        audioPlayerAPI.pause()
        state = .paused
        timerAPI.stop()
    }

    // MARK: - Progress tracking

    private func startProgressTimer() {
        timerAPI.start { [weak self] in
            self?.updateProgress()
        }
    }

    private func updateProgress() {
        let duration = audioPlayerAPI.duration

        guard duration > 0 else { return }

        currentTime = audioPlayerAPI.currentTime
        progress = currentTime / duration
    }

    // MARK: - Helpers

    private var isActive: Bool {
        state == .playing || state == .paused
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AudioPlayerDelegate

extension AudioPlayerViewModelImpl: AudioPlayerDelegate {

    func didFinishPlaying() {
        state = .initial
        timerAPI.stop()
        currentTime = 0
        progress = 0
    }
}
