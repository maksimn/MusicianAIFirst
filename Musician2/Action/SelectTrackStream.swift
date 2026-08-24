//
//  SelectTrackStream.swift
//  Musician2
//
//  Created by Maksim Ivanov on 24.08.2026.
//

import Foundation

/// The `SelectTrack` action: a track list notifies the track selector about the track the user has tapped.
nonisolated final class SelectTrackStream: SelectTrackSender, SelectTrackListener, @unchecked Sendable {

    static let shared = SelectTrackStream()

    var selection: AsyncStream<TrackSelection> {
        stream.values
    }

    private let stream = ActionStream<TrackSelection>()

    private init() {}

    func send(_ selection: TrackSelection) {
        stream.send(selection)
    }
}
