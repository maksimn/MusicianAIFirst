//
//  Book.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import Foundation

/// The data of a single book of the books feed.
///
/// The struct mirrors the JSON schema of `http://maksimn.github.io/elizarov/books.json` verbatim:
/// the feed speaks snake_case, so the coding keys translate it to the camelCase properties.
struct Book: Decodable, Hashable, Identifiable {

    let name: String

    /// The type of the book — a novel, a collection of stories and so on.
    let type: String

    /// The year of the publication as it is written in the feed.
    let year: String

    /// The address of the store selling the book as it is written in the feed; empty when there is
    /// no store page.
    let urlToStore: String

    /// The address of the book cover image as it is written in the feed.
    let coverUrl: String

    /// The median color of the book cover as a hex string — the background color of the book views.
    let medianColor: String

    var id: String { name }

    /// The address of the store selling the book, or `nil` when the feed gives no store page.
    var storeUrl: URL? {
        URL(string: urlToStore)
    }

    /// The address of the book cover image, or `nil` when the feed gives an invalid address.
    var cover: URL? {
        URL(string: coverUrl)
    }

    private enum CodingKeys: String, CodingKey {

        case name
        case type
        case year
        case urlToStore = "url_to_store"
        case coverUrl = "cover_url"
        case medianColor = "median_color"
    }
}
