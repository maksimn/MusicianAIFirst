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
/// the shown album list, the finished playback, the track the user has picked in a track list — and
/// answers every one of them with the NextTrack action. Every track list announces the list the track
/// has been picked in together with the track, because that list is the one the playback goes on
/// through: the selector keeps it as the queue instead of reading it from the announcing feature.
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
                return selectPicked(track, from: .album(album), into: &state)
            }

            return nil

        case let action as FavoritesAction:
            if case .trackTapped(let track, let tracks) = action {
                return selectPicked(track, from: .favorites(tracks), into: &state)
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

        return select(track, from: .album(album), autoPlay: false, into: &state)
    }

    /// The next track is the one following the selected track in the queue the selected track has been
    /// picked from, the first track of the queue following its last one.
    private func selectNextTrack(into state: inout TrackSelectorState) -> SideEffect {
        guard let queue = state.queue, let track = state.selectedTrack else { return nil }
        guard let index = queue.tracks.firstIndex(where: { $0.trackId == track.trackId }) else { return nil }

        let nextIndex = index + 1 < queue.tracks.count ? index + 1 : 0

        return select(queue.tracks[nextIndex], from: queue, autoPlay: true, into: &state)
    }

    /// The track the user has picked overrides whatever was queued next and starts playing at once.
    ///
    /// The very track already playing from that very queue is left alone: a tap on it means the
    /// pausing — or the resuming — the audio player makes of it, not a reselection.
    private func selectPicked(_ track: Track, from queue: TrackQueue,
                              into state: inout TrackSelectorState) -> SideEffect {
        if state.queue == queue && state.selectedTrack == track {
            return nil
        }

        return select(track, from: queue, autoPlay: true, into: &state)
    }

    private func select(_ track: Track, from queue: TrackQueue, autoPlay: Bool,
                        into state: inout TrackSelectorState) -> SideEffect {
        state.queue = queue
        state.selectedTrack = track

        return ActionSideEffect(TrackSelectorAction.nextTrack(TrackData(track: track, autoPlay: autoPlay)))
    }
}
