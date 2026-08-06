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

    private let logger: Logger

    init(
        track: Track,
        dataLoader: NetworkDataLoader,
        audioPlayerAPI: AudioPlayerAPI,
        timerAPI: TimerAPI,
        logger: Logger
    ) {
        self.track = track
        self.dataLoader = dataLoader
        self.audioPlayerAPI = audioPlayerAPI
        self.timerAPI = timerAPI
        self.logger = logger
        self.audioPlayerAPI.delegate = self
    }

    // MARK: - Track loading

    @MainActor
    func loadTrack() async {
        logger.log("The user has opened the player for the '\(track.name)' track.", level: .info)

        guard let url = URL(string: track.url) else {
            logger.log("The track url = '\(track.url)' is invalid.", level: .error)
            state = .error
            return
        }

        state = .loading
        logger.log("Downloading the track from \(url) ...", level: .info)

        do {
            let data = try await dataLoader.download(url)

            self.data = data
            state = .loaded
            logger.log("The track has been downloaded, \(data.count) bytes.", level: .info)
        } catch {
            logger.log("\(error)", level: .error)
            state = .error
        }

        logger.logState(actionName: "loadTrack()", state)
    }

    // MARK: - Playback control

    @MainActor
    func play() {
        logger.log("The user has tapped the play / pause button, current state = \(state).", level: .info)

        guard let data else {
            logger.log("The track has not been loaded yet, the tap is ignored.", level: .warn)
            return
        }

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
            logger.log("\(error)", level: .error)
            state = .error
        }

        logger.logState(actionName: "play()", state)
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
        logger.log("The track \(track) has finished playing.", level: .info)

        state = .initial
        timerAPI.stop()
        currentTime = 0
        progress = 0
    }
}
