//
//  AudioPlayerAction.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import Foundation
import UDF

/// The actions of the audio player feature.
enum AudioPlayerAction: Action {

    /// The user has tapped the play / pause button.
    case playPauseTapped

    /// The audio data of the current track has been downloaded.
    case trackLoaded(Data, autoPlay: Bool)

    /// The downloading of the current track has failed.
    case trackLoadingFailed(WithError)

    /// The audio player API has started playing the current track.
    case playbackStarted

    /// The audio player API has failed to start the playback.
    case playbackFailed(WithError)

    /// The progress timer has fired.
    case progress(currentTime: TimeInterval, duration: TimeInterval)

    /// The current track has been played to its end.
    case playbackFinished
}
