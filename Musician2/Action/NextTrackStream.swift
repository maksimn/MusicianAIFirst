//
//  NextTrackStream.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

import Foundation

/// The `NextTrack` action: the track selector notifies its listeners about the track to play next.
nonisolated final class NextTrackStream: NextTrackSender, NextTrackListener, @unchecked Sendable {

    static let shared = NextTrackStream()

    var trackData: AsyncStream<TrackData> {
        stream.values
    }

    private let stream = ActionStream<TrackData>()

    private init() {}

    func send(_ trackData: TrackData) {
        stream.send(trackData)
    }
}
