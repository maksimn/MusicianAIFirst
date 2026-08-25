//
//  AppAction.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// The actions that belong to the application itself rather than to a single feature:
/// they are the vocabulary the track lists, the track selector and the audio player share.
enum AppAction: Action {

    /// The track selector has chosen the track to play.
    case nextTrack(TrackData)
}
