//
//  TrackSelectorReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// Chooses the track the application plays.
///
/// The track selector has no user interface of its own: it listens to the actions of the features —
/// the shown album list, the finished playback, the track the user has picked — and answers
/// every one of them with the NextTrack action.
struct TrackSelectorReducer {

    func reduce(_ state: inout TrackSelectorState, _ action: Action) -> SideEffect {
        switch action {
        case let action as AlbumListAction:
            guard case .albumsLoaded(let albums) = action else { return nil }

            return selectInitialTrack(from: albums, into: &state)

        case let action as AudioPlayerAction:
            guard case .playbackFinished = action else { return nil }

            return selectNextTrack(into: &state)

        case let action as AlbumTracklistAction:
            if case .trackTapped(let track, let album) = action {
                return select(track, of: album, autoPlay: true, into: &state)
            }

            return nil

        default:
            return nil
        }
    }

    /// The initial track of the application is the first track of the first shown album.
    private func selectInitialTrack(from albums: [Album], into state: inout TrackSelectorState) -> SideEffect {
        let albums = albums.sorted(by: { $0.albumYear > $1.albumYear })
        guard let album = albums.first else { return nil }
        guard let track = album.tracks.first else { return nil }

        return select(track, of: album, autoPlay: false, into: &state)
    }

    /// The next track is the one following the selected track in the album the selected track belongs to.
    private func selectNextTrack(into state: inout TrackSelectorState) -> SideEffect {
        guard let album = state.selectedAlbum, let track = state.selectedTrack else { return nil }
        guard let index = album.tracks.firstIndex(where: { $0.trackId == track.trackId }) else { return nil }

        let nextIndex = index + 1 < album.tracks.count ? index + 1 : 0

        return select(album.tracks[nextIndex], of: album, autoPlay: true, into: &state)
    }

    private func select(_ track: Track, of album: Album, autoPlay: Bool,
                        into state: inout TrackSelectorState) -> SideEffectProtocol {
        state.selectedAlbum = album
        state.selectedTrack = track

        return ActionSideEffect(TrackSelectorAction.nextTrack(TrackData(track: track, autoPlay: autoPlay)))
    }
}
