//
//  AudioPlayerSideEffects.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import Foundation
import UDF

/// Downloads the audio data of the track and dispatches the result back to the store.
struct LoadTrackSideEffect: SideEffectProtocol {

    let url: URL

    let autoPlay: Bool

    let dataLoader: NetworkDataLoader

    func execute(with dispatcher: ActionDispatcher) {
        Task {
            do {
                let data = try await dataLoader.download(url)

                dispatcher.dispatch(AudioPlayerAction.trackLoaded(data, autoPlay: autoPlay))
            } catch {
                dispatcher.dispatch(AudioPlayerAction.trackLoadingFailed(WithError(error)))
            }
        }
    }
}

/// Starts or resumes the playback and the progress timer.
///
/// The state is not changed here: the store learns whether the playback has actually started
/// from the action this side effect dispatches back.
///
/// The store executes the side effects on a queue of its own, while both the audio player
/// and the progress timer belong to the main run loop, so the work is moved back to it.
struct StartPlaybackSideEffect: SideEffectProtocol {

    let data: Data

    /// The audio player API is initialized with the data of the track that has just been loaded,
    /// while a paused track is resumed by the already initialized API.
    let initializesPlayer: Bool

    let audioPlayerAPI: AudioPlayerAPI

    let timerAPI: TimerAPI

    func execute(with dispatcher: ActionDispatcher) {
        DispatchQueue.main.async {
            start(dispatching: dispatcher)
        }
    }

    private func start(dispatching dispatcher: ActionDispatcher) {
        do {
            if initializesPlayer {
                try audioPlayerAPI.initialize(with: data)
            }

            audioPlayerAPI.play()
            dispatcher.dispatch(AudioPlayerAction.playbackStarted)

            timerAPI.stop()
            startProgressTimer(dispatching: dispatcher)
        } catch {
            dispatcher.dispatch(AudioPlayerAction.playbackFailed(WithError(error)))
        }
    }

    private func startProgressTimer(dispatching dispatcher: ActionDispatcher) {
        timerAPI.start {
            dispatcher.dispatch(
                AudioPlayerAction.progress(
                    currentTime: audioPlayerAPI.currentTime,
                    duration: audioPlayerAPI.duration
                )
            )
        }
    }
}

/// Stops the playback and the progress timer.
///
/// Just as the starting of the playback, the stopping of it is done on the main run loop
/// the audio player and the progress timer belong to.
struct StopPlaybackSideEffect: SideEffectProtocol {

    /// Only a playing track is paused: there is nothing to pause otherwise.
    let pausesPlayback: Bool

    let audioPlayerAPI: AudioPlayerAPI

    let timerAPI: TimerAPI

    func execute(with dispatcher: ActionDispatcher) {
        DispatchQueue.main.async {
            if pausesPlayback {
                audioPlayerAPI.pause()
            }

            timerAPI.stop()
        }
    }
}
