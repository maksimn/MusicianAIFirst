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

    init(repository: AlbumRepository, albumListLoadedSender: AlbumListLoadedSender) {
        self.repository = repository
        self.albumListLoadedSender = albumListLoadedSender
        self.albums = repository.loadCachedAlbums()
    }

    @MainActor
    func loadAlbums() async {
        isLoading = true
        error = nil

        do {
            let fetched = try await repository.fetchAlbums()
            albums = fetched
        } catch {
            self.error = error
            // If network fails, keep showing cached albums.
            if albums.isEmpty {
                albums = repository.loadCachedAlbums()
            }
        }

        isLoading = false

        if !albums.isEmpty {
            albumListLoadedSender.send(albums)
        }
    }
}