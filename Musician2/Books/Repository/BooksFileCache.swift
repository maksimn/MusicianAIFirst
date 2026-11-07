//
//  BooksFileCache.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import Foundation

/// The local file cache of the books feed.
///
/// It keeps the downloaded content of the books list as a verbatim copy of the remote JSON, so
/// the user can still browse the books when the network is not available.
struct BooksFileCache {

    /// The cache lives in the caches directory: it is a disposable copy of the feed, and the
    /// system is free to purge the directory at any time.
    private let url: URL

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        url = cachesDirectory.appendingPathComponent("books.json")
    }

    /// Writes the downloaded content of the books list to the cache file.
    func save(_ data: Data) throws {
        try data.write(to: url, options: .atomic)
    }

    /// Reads the cached content of the books list, written by the previous successful fetching.
    func load() throws -> [Book] {
        let data = try Data(contentsOf: url)

        return try JSONDecoder().decode([Book].self, from: data)
    }
}
