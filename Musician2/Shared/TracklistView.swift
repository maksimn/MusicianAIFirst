//
//  TracklistView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 01.09.2026.
//

import SwiftUI

/// The scrollable list of an album's tracks, marking the one being played and the favorite ones.
///
/// It is kept free of any store so that every screen showing tracks can reuse it and decide
/// on its own what a tap on a track or a swipe over it means.
struct TracklistView: View {

    let tracks: [Track]

    /// The track being played, whatever album it belongs to: it is highlighted when it is one
    /// of the listed tracks.
    let currentTrack: Track?

    let textColor: Color

    let onTrackTapped: (Track) -> Void

    /// Called for a completed leading swipe over a track, which is how the user marks a track as
    /// a favorite one — or takes the mark off, because the same swipe means both.
    let onToggleIsFavorite: (Track) -> Void

    /// A `List` and not a `LazyVStack`, because the swipe actions are the ones a list row offers:
    /// its own styling is hidden so that the album's color keeps showing through the rows.
    var body: some View {
        List(tracks) { track in
            Button {
                onTrackTapped(track)
            } label: {
                trackRow(track)
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    onToggleIsFavorite(track)
                } label: {
                    Image(systemName: track.isFavorite ? "star.slash" : "star")
                }
                .tint(.yellow)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.vertical, 0)
    }

    @ViewBuilder
    private func trackRow(_ track: Track) -> some View {
        let isSelected = track.id == currentTrack?.id

        HStack(alignment: .center, spacing: 4) {
            Text(isSelected ? "●" : "")
                .font(.system(size: 12))
                .foregroundColor(textColor)
                .frame(width: 24, alignment: .leading)
                .padding(.leading, 24)

            Text(track.name)
                .font(.system(size: isSelected ? 19 : 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)

            Spacer(minLength: 16)

            Text(track.isFavorite ? "★" : "  ")
                .font(.system(size: isSelected ? 19 : 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)
                .padding(.trailing, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 0)
        .padding(.bottom, 0)
        .contentShape(Rectangle())
    }
}
