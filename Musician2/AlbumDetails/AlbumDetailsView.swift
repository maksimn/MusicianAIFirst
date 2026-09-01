//
//  AlbumDetailsView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import SwiftUI

struct AlbumDetailsView: View {

    let store: ObservableStore<AlbumTracklistState>

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

            AlbumTracklistView(store: store)
        }
    }
}
