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

    private static let cacheFileName = "albums.json"

    private let dataLoader: NetworkDataLoader
    private let cacheService: CacheService

    init(dataLoader: NetworkDataLoader, cacheService: CacheService) {
        self.dataLoader = dataLoader
        self.cacheService = cacheService
    }

    func fetchAlbums() async throws -> [Album] {
        let url = URL(string: "http://maksimn.github.io/albums.json")!
        let data = try await dataLoader.download(url)
        let albums = try JSONDecoder().decode([Album].self, from: data)

        try cacheService.save(data, to: Self.cacheFileName)

        return albums
    }

    func loadCachedAlbums() -> [Album] {
        (try? cacheService.load([Album].self, from: Self.cacheFileName)) ?? []
    }
}
