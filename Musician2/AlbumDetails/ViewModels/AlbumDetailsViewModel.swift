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

    var state: AlbumDetailsState { get }

    /// Starts listening to the NextTrack action to keep the selected track up to date.
    func start() async

    /// Asks the track selector to select the tapped track and to start its playback.
    func selectTrack(_ track: Track)
}

@Observable
@MainActor
final class AlbumDetailsViewModelImpl: AlbumDetailsViewModel {

    private(set) var state: AlbumDetailsState

    private let nextTrackListener: NextTrackListener

    private let currentTrackProvider: CurrentTrackProvider

    private let selectTrackSender: SelectTrackSender

    init(
        album: Album,
        nextTrackListener: NextTrackListener,
        currentTrackProvider: CurrentTrackProvider,
        selectTrackSender: SelectTrackSender
    ) {
        self.state = AlbumDetailsState(album: album)
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
        selectTrackSender.send(TrackSelection(album: state.album, track: track))
    }

    /// Only a track of this album can be shown as selected.
    private func select(_ track: Track?) {
        guard let track, state.album.tracks.contains(track) else {
            state.selectedTrack = nil
            return
        }

        state.selectedTrack = track
    }
}
