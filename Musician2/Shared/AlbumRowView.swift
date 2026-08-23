//
//  AlbumRowView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import SwiftUI

/// The album header used both as a row of the album list and as a header of the album details.
/// When `onBack` is given, the row gets a left margin with the back button in it.
struct AlbumRowView: View {

    let album: Album

    let onBack: (() -> Void)?

    init(album: Album, onBack: (() -> Void)? = nil) {
        self.album = album
        self.onBack = onBack
    }

    var body: some View {
        let albumColor = album.color
        let textColor = albumColor.toCharacterColor

        HStack(alignment: .top, spacing: 0) {
            if let onBack {
                backButton(onBack, textColor: textColor)
            }

            AsyncImage(url: URL(string: album.albumCover)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderImage
            }
            .frame(width: 96, height: 96)
            .padding(.top, 24)
            .padding(.leading, onBack == nil ? 24 : 0)

            VStack(alignment: .leading, spacing: 0) {
                Text(album.albumName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.top, 24)
                    .padding(.leading, 24)
                    .padding(.trailing, 24)

                Spacer()

                Text("Альбом, \(album.albumYear)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.bottom, 24)
                    .padding(.leading, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 144)
        .background(albumColor)
    }

    private func backButton(_ onBack: @escaping () -> Void, textColor: Color) -> some View {
        Button(action: onBack) {
            Text("‹")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(textColor)
                .frame(width: 44, height: 96, alignment: .center)
        }
        .accessibilityLabel("Back")
        .padding(.top, 24)
        .padding(.leading, 8)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
            }
    }
}
