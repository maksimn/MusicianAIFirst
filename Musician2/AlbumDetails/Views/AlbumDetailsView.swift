//
//  AlbumDetailsView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import SwiftUI

struct AlbumDetailsView: View {

    let store: ObservableStore<AlbumDetailsState>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let album = store.state.album {
                content(of: album)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(store.state.album?.color ?? .clear)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func content(of album: Album) -> some View {
        VStack(spacing: 0) {
            AlbumRowView(album: album) {
                dismiss()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(album.tracks) { track in
                        Button {
                            store.dispatch(AlbumDetailsAction.trackTapped(track, album))
                        } label: {
                            trackRow(track, textColor: album.textColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.top, 18)
        }
    }

    @ViewBuilder
    private func trackRow(_ track: Track, textColor: Color) -> some View {
        let isSelected = track.id == store.state.currentTrack?.id

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
