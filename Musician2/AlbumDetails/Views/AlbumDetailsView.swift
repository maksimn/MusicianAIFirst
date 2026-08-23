//
//  AlbumDetailsView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import SwiftUI

struct AlbumDetailsView: View {

    @State private var viewModel: AlbumDetailsViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: some AlbumDetailsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        let album = viewModel.album

        VStack(spacing: 0) {
            AlbumRowView(album: album) {
                dismiss()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(album.tracks) { track in
                        trackRow(track, textColor: album.textColor)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(album.color)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.start()
        }
    }

    @ViewBuilder
    private func trackRow(_ track: Track, textColor: Color) -> some View {
        let isSelected = track == viewModel.selectedTrack

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
        .padding(.top, 22)
    }
}
