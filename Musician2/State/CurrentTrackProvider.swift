//
//  CurrentTrackProvider.swift
//  Musician2
//
//  Created by Maksim Ivanov on 24.08.2026.
//

import Foundation

/// Provides the track selected before the caller has started listening to the `NextTrack` action.
protocol CurrentTrackProvider {

    var currentTrack: Track? { get }
}

final class CurrentTrackProviderImpl: CurrentTrackProvider {

    static let shared = CurrentTrackProviderImpl(nextTrackListener: NextTrackStream.shared)

    private(set) var currentTrack: Track?

    private let nextTrackListener: NextTrackListener

    private var nextTrackTask: Task<Void, Never>?

    init(nextTrackListener: NextTrackListener) {
        self.nextTrackListener = nextTrackListener
    }

    deinit {
        nextTrackTask?.cancel()
    }

    /// Starts listening to the `NextTrack` action to keep the current track up to date.
    func start() {
        guard nextTrackTask == nil else { return }

        nextTrackTask = Task { [weak self] in
            guard let trackData = self?.nextTrackListener.trackData else { return }

            for await data in trackData {
                self?.currentTrack = data.track
            }
        }
    }
}
