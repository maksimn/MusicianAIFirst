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

    /// Asks the track selector to select the tapped track and to start its playback.
    func selectTrack(_ track: Track)
}

@Observable
@MainActor
final class AlbumDetailsViewModelImpl: AlbumDetailsViewModel {

    let album: Album

    private(set) var selectedTrack: Track?

    private let nextTrackListener: NextTrackListener

    private let currentTrackProvider: CurrentTrackProvider

    private let selectTrackSender: SelectTrackSender

    init(
        album: Album,
        nextTrackListener: NextTrackListener,
        currentTrackProvider: CurrentTrackProvider,
        selectTrackSender: SelectTrackSender
    ) {
        self.album = album
        self.nextTrackListener = nextTrackListener
        self.currentTrackProvider = currentTrackProvider
        self.selectTrackSender = selectTrackSender
    }

    func start() async {
        select(currentTrackProvider.currentTrack)

        for await trackData in nextTrackListener.trackData {
            select(trackData.track)
        }
    }

    /// The selected track is not changed here: it is updated when the selection
    /// comes back from the track selector through the NextTrack action.
    func selectTrack(_ track: Track) {
        selectTrackSender.send(TrackSelection(album: album, track: track))
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
