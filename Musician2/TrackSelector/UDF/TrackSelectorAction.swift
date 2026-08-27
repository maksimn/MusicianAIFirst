//
//  TrackSelectorAction.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// The actions of the track selector: the vocabulary it announces its choice to
/// the track lists and the audio player with.
enum TrackSelectorAction: Action {

    /// The track selector has chosen the track to play.
    case nextTrack(TrackData)
}
