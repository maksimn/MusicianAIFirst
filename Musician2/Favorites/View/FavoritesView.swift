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

    /// A swipe over a track is the only thing the list does here, and it means one thing only: the
    /// track leaves the favorites. A tap does nothing — a track is played from the tracklist of its
    /// album, which is the feature that owns the picking of a track to play.
    private var tracklist: some View {
        TracklistView(
            tracks: store.state.tracks,
            currentTrack: store.state.currentTrack,
            textColor: .white
        ) { _ in
        } onToggleIsFavorite: { track in
            store.dispatch(FavoritesAction.removeFromFavorites(track))
        }
        .padding(.top, 10)
    }
}
