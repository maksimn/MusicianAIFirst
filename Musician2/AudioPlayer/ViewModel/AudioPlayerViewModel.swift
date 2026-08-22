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

    var track: Track? { get }
    var state: AudioPlayerState { get }
    var progress: Double { get }
    var currentTime: TimeInterval { get }
    var timeDisplay: String { get }
    var progressValue: Double { get }

    /// Starts listening to the NextTrack action, loads the received tracks
    /// and plays them automatically when the action asks for it.
    func start() async

    func play()
}

enum AudioPlayerState: Equatable {
    case initial, loading, loaded, playing, paused, error(WithError)
}

enum AudioPlayerError: Error {
    case invalidUrlFor(Track)
}

@Observable
final class AudioPlayerViewModelImpl: AudioPlayerViewModel {

    private(set) var track: Track?

    private(set) var state: AudioPlayerState = .initial

    private(set) var progress = 0.0

    private(set) var currentTime: TimeInterval = 0.0

    var timeDisplay: String {
        isActive ? formattedTime(currentTime) : (track?.duration ?? "")
    }

    var progressValue: Double {
        isActive ? progress : 1.0
    }

    private var data: Data?

    private let dataLoader: NetworkDataLoader

    private var audioPlayerAPI: AudioPlayerAPI

    private let timerAPI: TimerAPI

    private let nextTrackListener: NextTrackListener

    private let findNextTrackSender: FindNextTrackSender

    private let logger: Logger

    init(
        dataLoader: NetworkDataLoader,
        audioPlayerAPI: AudioPlayerAPI,
        timerAPI: TimerAPI,
        nextTrackListener: NextTrackListener,
        findNextTrackSender: FindNextTrackSender,
        logger: Logger
    ) {
        self.dataLoader = dataLoader
        self.audioPlayerAPI = audioPlayerAPI
        self.timerAPI = timerAPI
        self.nextTrackListener = nextTrackListener
        self.findNextTrackSender = findNextTrackSender
        self.logger = logger
        self.audioPlayerAPI.delegate = self
    }

    // MARK: - Track loading

    @MainActor
    func start() async {
        logger.log("The player has started listening to the NextTrack stream.", level: .info)

        for await trackData in nextTrackListener.trackData {
            await loadTrack(trackData.track)

            if trackData.autoPlay {
                autoPlay()
            }
        }
    }

    @MainActor
    func loadTrack(_ track: Track) async {
        logger.log("The '\(track.name)' track has been received by the player.", level: .info)

        self.track = track
        resetPlayback()

        guard let url = URL(string: track.url) else {
            logger.log("The track url = '\(track.url)' is invalid.", level: .error)
            state = .error(WithError(AudioPlayerError.invalidUrlFor(track)))
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
            state = .error(WithError(error))
        }

        logger.logState(actionName: "loadTrack()", state)
    }

    // MARK: - Playback control

    @MainActor
    func play() {
        logger.log("The user has tapped the play / pause button, current state = \(state).", level: .info)

        togglePlayback()
    }

    /// Starts the playback of the just loaded track without any user interaction.
    @MainActor
    private func autoPlay() {
        guard state == .loaded else {
            logger.log("The track is not loaded, state = \(state), there is nothing to play automatically.", level: .warn)
            return
        }

        logger.log("Playing the received track automatically.", level: .info)

        togglePlayback()
    }

    @MainActor
    private func togglePlayback() {
        guard let data else {
            logger.log("The track has not been loaded yet, the request is ignored.", level: .warn)
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
            state = .error(WithError(error))
        }

        logger.logState(actionName: "togglePlayback()", state)
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

    @MainActor
    private func resetPlayback() {
        timerAPI.stop()
        data = nil
        currentTime = 0
        progress = 0
        state = .initial
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
        if let track {
            logger.log("The track \(String(describing: track)) has finished playing.", level: .info)
        }

        resetPlayback()
        logger.log("Asking the track selector for the next track.", level: .info)
        findNextTrackSender.send()
    }
}
