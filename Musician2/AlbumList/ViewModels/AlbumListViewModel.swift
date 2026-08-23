//
//  AlbumListViewModel.swift
//  Musician2
//
//  Created by Maksim Ivanov on 05.07.2026.
//

import Foundation
import Observation

@Observable
final class AlbumListViewModel {
    private(set) var albums: [Album] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let repository: AlbumRepository

    private let albumListLoadedSender: AlbumListLoadedSender

    private let isReversed: Bool

    init(repository: AlbumRepository, albumListLoadedSender: AlbumListLoadedSender, isReversed: Bool = true) {
        self.repository = repository
        self.albumListLoadedSender = albumListLoadedSender
        self.isReversed = isReversed
    }

    @MainActor
    func loadAlbums() async {
        guard albums.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            let fetched = try await repository.fetchAlbums()
            albums = isReversed ? fetched.reversed() : fetched
        } catch {
            self.error = error
            // If network fails, keep showing cached albums.
            if albums.isEmpty {
                let cached = repository.loadCachedAlbums()

                albums = isReversed ? cached.reversed() : cached
            }
        }

        isLoading = false

        if !albums.isEmpty {
            albumListLoadedSender.send(albums)
        }
    }
}
