//
//  AudioPlayerState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 24.08.2026.
//

import Foundation

enum AudioPlayerCondition: Equatable {
    case initial, loading, loaded, playing, paused, error(WithError)
}

enum AudioPlayerError: Error {
    case invalidUrlFor(Track)
}

/// The state of the audio player: the track being played and everything the player view shows.
struct AudioPlayerState {

    var track: Track?

    var condition: AudioPlayerCondition = .initial

    /// The downloaded audio data of the current track.
    var data: Data?

    var progress = 0.0

    var currentTime: TimeInterval = 0.0

    var timeDisplay: String {
        isActive ? formattedTime(currentTime) : (track?.duration ?? "")
    }

    var progressValue: Double {
        isActive ? progress : 1.0
    }

    /// Forgets the loaded track data and rewinds the playback back to the very beginning.
    mutating func resetPlayback() {
        data = nil
        currentTime = 0
        progress = 0
        condition = .initial
    }

    // MARK: - Helpers

    private var isActive: Bool {
        condition == .playing || condition == .paused
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
