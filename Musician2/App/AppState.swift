//
//  AppState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

/// The state of the whole application: every feature owns its own part of it
/// and works with that part through a scoped store of the common store.
struct AppState {

    var albumList = AlbumListState()

    var albumDetails = AlbumDetailsState()

    var audioPlayer = AudioPlayerState()

    var trackSelector = TrackSelectorState()
}
