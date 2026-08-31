//
//  AlbumRepository.swift
//  Musician2
//
//  Created by Maksim Ivanov on 05.07.2026.
//

import Foundation

protocol AlbumRepository {

    func fetchAlbums() async throws -> [Album]

    func loadCachedAlbums() -> [Album]
}

final class AlbumRepositoryImpl: AlbumRepository {

    private let dataLoader: NetworkDataLoader
    private let cacheService: AlbumCacheService

    init(dataLoader: NetworkDataLoader, cacheService: AlbumCacheService) {
        self.dataLoader = dataLoader
        self.cacheService = cacheService
    }

    /// The albums are returned as they come from the cache, not as they were decoded: saving merges
    /// the feed with the locally owned track data, so only a re-read carries the favorites along.
    func fetchAlbums() async throws -> [Album] {
        let url = URL(string: "http://maksimn.github.io/albums.json")!
        let data = try await dataLoader.download(url)
        let albums = try JSONDecoder().decode([Album].self, from: data)

        try cacheService.saveAlbums(albums)

        return (try? cacheService.loadAlbums()) ?? albums
    }

    func loadCachedAlbums() -> [Album] {
        (try? cacheService.loadAlbums()) ?? []
    }
}
