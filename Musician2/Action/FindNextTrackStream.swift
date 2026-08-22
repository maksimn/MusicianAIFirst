//
//  FindNextTrackStream.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

import Foundation

/// The `FindNextTrack` action: the audio player asks the track selector for the track to play next.
nonisolated final class FindNextTrackStream: FindNextTrackSender, FindNextTrackListener, @unchecked Sendable {

    static let shared = FindNextTrackStream()

    var notification: AsyncStream<Void> {
        stream.values
    }

    private let stream = ActionStream<Void>()

    private init() {}

    func send() {
        stream.send(())
    }
}
