//
//  BookRowView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import SwiftUI

/// The row of the books list: the book cover on the left and the book data on the right.
///
/// The height of the item is equal to the height of the cover image — the texts are laid out
/// beside it and never stretch the row.
struct BookRowView: View {

    let book: Book

    /// The size of the cover image: the height of the image is the height of the whole item.
    static let coverSize = CGSize(width: 153.6, height: 230.4)

    var body: some View {
        let backgroundColor = Color(hex: book.medianColor) ?? .clear
        let textColor = backgroundColor.toCharacterColor

        HStack(alignment: .top, spacing: 0) {
            AsyncImage(url: book.cover) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderImage
            }
            .frame(width: Self.coverSize.width, height: Self.coverSize.height)
            .clipped()

            VStack(alignment: .leading, spacing: 0) {
                Text(book.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                Text("\(book.type), \(book.year)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(textColor)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)

                Spacer()

                if let storeUrl = book.storeUrl {
                    Link("В магазин", destination: storeUrl)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(textColor)
                        .underline()
                        .padding(.bottom, 16)
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.coverSize.height)
        .background(backgroundColor)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "book")
                    .foregroundStyle(.secondary)
            }
    }
}
