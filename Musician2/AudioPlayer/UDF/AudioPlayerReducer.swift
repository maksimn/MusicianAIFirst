//
//  AudioPlayerReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import Foundation
import UDF

/// Produces the new state of the audio player for every dispatched action.
///
/// The reducer never touches the audio player API itself: every call to it, as well as
/// the downloading of a track, is made by the side effects the reducer returns.
struct AudioPlayerReducer {

    let dataLoader: NetworkDataLoader

    let audioPlayerAPI: AudioPlayerAPI

    let timerAPI: TimerAPI

    func reduce(_ state: inout AudioPlayerState, _ action: Action) -> SideEffect {
        switch action {
        case let action as AppAction:
            return reduce(&state, action)

        case let action as AudioPlayerAction:
            return reduce(&state, action)

        case let action as AlbumDetailsAction:
            if case .trackTapped(let track, _) = action {
                return apply(track, to: &state)
            }

            return nil

        default:
            return nil
        }
    }

    // MARK: - The application actions

    private func reduce(_ state: inout AudioPlayerState, _ action: AppAction) -> SideEffect {
        switch action {
        case .nextTrack(let trackData):
            return load(trackData, into: &state)
        }
    }

    /// The received track replaces the current one and is downloaded right away.
    private func load(_ trackData: TrackData, into state: inout AudioPlayerState) -> SideEffect {
        let track = trackData.track
        let stopPlayback = stopPlaybackSideEffect(for: state)

        state.resetPlayback()
        state.track = track

        guard let url = URL(string: track.url) else {
            state.condition = .error(WithError(AudioPlayerError.invalidUrlFor(track)))

            return stopPlayback
        }

        state.condition = .loading

        let loadTrack = LoadTrackSideEffect(
            url: url,
            autoPlay: trackData.autoPlay,
            dataLoader: dataLoader
        )

        return combine {
            stopPlayback
            loadTrack
        }
    }

    /// The current track is either played or left alone, another track is only reset here:
    /// it comes back to the player through the NextTrack action and is loaded and played then.
    private func apply(_ selectionTrack: Track, to state: inout AudioPlayerState) -> SideEffect {
        guard selectionTrack == state.track else {
            let stopPlayback = stopPlaybackSideEffect(for: state)

            state.resetPlayback()

            return stopPlayback
        }

        switch state.condition {
        case .loaded, .paused:
            return togglePlayback(&state)

        default:
            return nil
        }
    }

    // MARK: - The audio player actions

    private func reduce(_ state: inout AudioPlayerState, _ action: AudioPlayerAction) -> SideEffect {
        switch action {
        case .playPauseTapped:
            return togglePlayback(&state)

        case .trackLoaded(let data, let autoPlay):
            state.data = data
            state.condition = .loaded

            guard autoPlay else { return nil }

            return togglePlayback(&state)

        case .trackLoadingFailed(let error):
            state.condition = .error(error)

            return nil

        case .playbackStarted:
            state.condition = .playing

            return nil

        case .playbackFailed(let error):
            state.condition = .error(error)

            return nil

        case .progress(let currentTime, let duration):
            guard duration > 0 else { return nil }

            state.currentTime = currentTime
            state.progress = currentTime / duration

            return nil

        case .playbackFinished:
            return finishPlayback(&state)
        }
    }

    /// The track to play next is chosen by the track selector, which reacts
    /// to the PlaybackFinished action itself.
    private func finishPlayback(_ state: inout AudioPlayerState) -> SideEffect {
        let stopPlayback = stopPlaybackSideEffect(for: state)

        state.resetPlayback()

        return stopPlayback
    }

    // MARK: - Playback control

    /// A loaded or paused track starts playing, a playing one is paused.
    private func togglePlayback(_ state: inout AudioPlayerState) -> SideEffect {
        guard let data = state.data else { return nil }

        switch state.condition {
        case .loaded, .paused:
            // The state stays as it is: it becomes `playing` when the playback has actually started.
            return StartPlaybackSideEffect(
                data: data,
                initializesPlayer: state.condition == .loaded,
                audioPlayerAPI: audioPlayerAPI,
                timerAPI: timerAPI
            )

        case .playing:
            state.condition = .paused

            return StopPlaybackSideEffect(
                pausesPlayback: true,
                audioPlayerAPI: audioPlayerAPI,
                timerAPI: timerAPI
            )

        default:
            return nil
        }
    }

    private func stopPlaybackSideEffect(for state: AudioPlayerState) -> SideEffectProtocol {
        StopPlaybackSideEffect(
            pausesPlayback: state.condition == .playing,
            audioPlayerAPI: audioPlayerAPI,
            timerAPI: timerAPI
        )
    }
}
