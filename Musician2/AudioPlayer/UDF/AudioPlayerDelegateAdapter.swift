//
//  AudioPlayerDelegateAdapter.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// Turns the callbacks of the audio player API into the actions of the store.
final class AudioPlayerDelegateAdapter: AudioPlayerDelegate {

    private let dispatcher: ActionDispatcher

    init(dispatcher: ActionDispatcher) {
        self.dispatcher = dispatcher
    }

    func didFinishPlaying() {
        dispatcher.dispatch(AudioPlayerAction.playbackFinished)
    }
}
