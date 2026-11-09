//
//  BooksRepository.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import Foundation

/// The source of the books feed: it fetches the books from the remote list and keeps a local
/// copy of the downloaded content for the times the network is not available.
protocol BooksRepository {

    func loadBooks() async throws -> [Book]
}

/// The remote address of the books list.
enum BooksFeed {

    static let url = URL(string: "http://maksimn.github.io/elizarov/books.json")!
}

/// Loads the books from the network and stores the downloaded content in the local file cache.
///
/// On a network failure it falls back to the cached copy of the feed, so the user still sees the
/// books downloaded during a previous session; when there is no cache yet, the failure is thrown.
struct RemoteBooksRepository: BooksRepository {

    let dataLoader: NetworkDataLoader

    let fileCache: BooksFileCache

    func loadBooks() async throws -> [Book] {
        do {
            let data = try await dataLoader.download(BooksFeed.url)
            let books = try JSONDecoder().decode([Book].self, from: data)

            try? fileCache.save(data)

            return books
        } catch {
            return try fileCache.load()
        }
    }
}
