//
//  LoggingAudioPlayerAPI.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

import Foundation

/// Adds logging to an `AudioPlayerAPI` without changing its implementation.
///
/// The decorator substitutes itself for the delegate of the decorated API, so the playback
/// callbacks are logged as well before being passed to the real delegate.
final class LoggingAudioPlayerAPI: AudioPlayerAPI {

    weak var delegate: AudioPlayerDelegate?

    private var decorated: AudioPlayerAPI

    private let logger: Logger

    init(decorated: AudioPlayerAPI, logger: Logger) {
        self.decorated = decorated
        self.logger = logger
        self.decorated.delegate = self
    }

    // `currentTime` and `duration` are polled by the progress timer several times per second,
    // so they are deliberately not logged.

    var currentTime: TimeInterval {
        decorated.currentTime
    }

    var duration: TimeInterval {
        decorated.duration
    }

    func initialize(with data: Data) throws {
        logger.log("AudioPlayerAPI.initialize(with:) called for \(data.count) bytes of audio data.", level: .info)

        do {
            try decorated.initialize(with: data)
            logger.log("AudioPlayerAPI has been initialized, track duration = \(decorated.duration) s.", level: .info)
        } catch {
            logger.log("\(error)", level: .error)
            throw error
        }
    }

    func play() {
        logger.log("AudioPlayerAPI.play() called at \(decorated.currentTime) s.", level: .info)
        decorated.play()
    }

    func pause() {
        logger.log("AudioPlayerAPI.pause() called at \(decorated.currentTime) s.", level: .info)
        decorated.pause()
    }
}

// MARK: - AudioPlayerDelegate

extension LoggingAudioPlayerAPI: AudioPlayerDelegate {

    func didFinishPlaying() {
        logger.log("AudioPlayerAPI has finished playing the track.", level: .info)
        delegate?.didFinishPlaying()
    }
}
