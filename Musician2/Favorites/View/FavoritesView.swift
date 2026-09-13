//
//  FavoritesView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 27.08.2026.
//

import SwiftUI

/// The tracks the user has marked as favorite ones, gathered from all the albums.
///
/// The screen belongs to no album, unlike the tracklist an album's own colors are taken from, so it
/// is drawn in the colors of the system: the listed tracks come from albums of different colors.
struct FavoritesView: View {

    let store: ObservableStore<FavoritesState>

    /// A `ZStack` and not a `Group`, because the modifiers of a group are applied to each of its
    /// branches: the loading would be asked for again every time the empty list gives way to the
    /// tracks, and the background would be drawn by the list rather than behind it.
    var body: some View {
        ZStack {
            Color(.black)

            if store.state.tracks.isEmpty {
                Text("Нет избранных треков")
                    .foregroundColor(.white)
            } else {
                tracklist
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            store.dispatch(FavoritesAction.loadFavoriteTracks)
        }
    }

    /// A tap on a track plays it, and the playback goes on through the list from there, so the whole
    /// list travels with the tapped track: the track selector takes the next track out of it. A swipe
    /// over a track means one thing only here — the track leaves the favorites.
    private var tracklist: some View {
        TracklistView(
            tracks: store.state.tracks,
            currentTrack: store.state.currentTrack,
            textColor: .white
        ) { track in
            store.dispatch(FavoritesAction.trackTapped(track, store.state.tracks))
        } onToggleIsFavorite: { track in
            store.dispatch(FavoritesAction.removeFromFavorites(track))
        }
        .padding(.top, 10)
    }
}
