//
//  AlbumDetailsViewModel.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import Foundation
import Observation

@MainActor
protocol AlbumDetailsViewModel {

    var album: Album { get }

    /// The track of this album which is selected for the playback, if any.
    var selectedTrack: Track? { get }

    /// Starts listening to the NextTrack action to keep the selected track up to date.
    func start() async

    /// Selects the tapped track of this album and starts its playback.
    func selectTrack(_ track: Track)
}

@Observable
@MainActor
final class AlbumDetailsViewModelImpl: AlbumDetailsViewModel {

    let album: Album

    private(set) var selectedTrack: Track?

    private let nextTrackListener: NextTrackListener

    private let currentTrackProvider: CurrentTrackProvider

    private let nextTrackSender: NextTrackSender

    init(
        album: Album,
        nextTrackListener: NextTrackListener,
        currentTrackProvider: CurrentTrackProvider,
        nextTrackSender: NextTrackSender
    ) {
        self.album = album
        self.nextTrackListener = nextTrackListener
        self.currentTrackProvider = currentTrackProvider
        self.nextTrackSender = nextTrackSender
    }

    func start() async {
        select(currentTrackProvider.currentTrack)

        for await trackData in nextTrackListener.trackData {
            select(trackData.track)
        }
    }

    /// The selected track is not changed here: the selection comes back through the NextTrack action,
    /// the same way as the tracks selected by the other features do.
    func selectTrack(_ track: Track) {
        nextTrackSender.send(TrackData(track: track, album: album, autoPlay: true))
    }

    /// Only a track of this album can be shown as selected.
    private func select(_ track: Track?) {
        guard let track, album.tracks.contains(track) else {
            selectedTrack = nil
            return
        }

        selectedTrack = track
    }
}
