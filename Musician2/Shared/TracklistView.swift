//
//  TracklistView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 01.09.2026.
//

import SwiftUI

/// The scrollable list of an album's tracks, marking the one being played.
///
/// It is kept free of any store so that every screen showing tracks can reuse it and decide
/// on its own what a tap on a track means.
struct TracklistView: View {

    let tracks: [Track]

    /// The track being played, whatever album it belongs to: it is highlighted when it is one
    /// of the listed tracks.
    let currentTrack: Track?

    let textColor: Color

    let onTrackTapped: (Track) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(tracks) { track in
                    Button {
                        onTrackTapped(track)
                    } label: {
                        trackRow(track)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func trackRow(_ track: Track) -> some View {
        let isSelected = track.id == currentTrack?.id

        HStack(alignment: .center, spacing: 0) {
            Text(isSelected ? "●" : "")
                .font(.system(size: 12))
                .foregroundColor(textColor)
                .frame(width: 24, alignment: .leading)
                .padding(.leading, 24)

            Text(track.name)
                .font(.system(size: isSelected ? 19 : 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)

            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 11)
        .padding(.bottom, 11)
        .contentShape(Rectangle())
    }
}
