//
//  AlbumCacheService.swift
//  Musician2
//
//  Created by Maksim Ivanov on 31.08.2026.
//

import Foundation
import SwiftData

/// The local storage of the album list.
///
/// It replaced the generic file cache because the cached albums are no longer a verbatim copy of the
/// downloaded JSON: tracks carry device-owned data (`isFavorite`, `updatedAt`) that has to survive
/// every refresh of the feed, which needs a merge on save rather than an overwrite of a file.
protocol AlbumCacheService {

    func saveAlbums(_ albums: [Album]) throws

    func loadAlbums() throws -> [Album]
}

/// Stores the albums in a SwiftData database.
///
/// Every call works on its own short-lived `ModelContext` over a shared `ModelContainer`, so the
/// service can be used from the effect queue without being bound to an actor and without keeping
/// managed objects alive between calls — the app outside this file only ever sees `Album` values.
final class SwiftDataAlbumCacheService: AlbumCacheService {

    /// Opening the database is the only failure the service cannot recover from, and it must not take
    /// the app down with it — the album list works without a cache. So the failure is kept here and
    /// reported through the (already throwing) methods instead of a throwing initializer.
    private let container: ModelContainer?
    private let containerError: Error?

    /// The store lives in Application Support rather than in `Library/Caches` the file cache used:
    /// the favorites are user data, and the system is free to purge the caches directory at any time.
    init(configuration: ModelConfiguration = ModelConfiguration("Albums")) {
        do {
            container = try ModelContainer(for: AlbumDAO.self, TrackDAO.self, configurations: configuration)
            containerError = nil
        } catch {
            container = nil
            containerError = error
        }
    }

    /// Merges the albums into the store instead of replacing them: the incoming albums come from the
    /// remote feed, which knows nothing about favorites, so the stored rows are updated in place and
    /// only the albums and tracks that have disappeared from the feed are deleted.
    func saveAlbums(_ albums: [Album]) throws {
        let context = ModelContext(try modelContainer())
        var storedAlbums = try context.fetch(FetchDescriptor<AlbumDAO>())
            .reduce(into: [Int: AlbumDAO]()) { $0[$1.albumId] = $1 }

        for album in albums {
            if let storedAlbum = storedAlbums.removeValue(forKey: album.albumId) {
                storedAlbum.update(with: album)
                merge(album.tracks, into: storedAlbum, in: context)
            } else {
                let storedAlbum = AlbumDAO(album)

                context.insert(storedAlbum)
                merge(album.tracks, into: storedAlbum, in: context)
            }
        }

        for removedAlbum in storedAlbums.values {
            context.delete(removedAlbum)
        }

        try context.save()
    }

    func loadAlbums() throws -> [Album] {
        let context = ModelContext(try modelContainer())

        return try context.fetch(FetchDescriptor<AlbumDAO>()).map { $0.toAlbum() }
    }

    // MARK: - Helpers

    private func modelContainer() throws -> ModelContainer {
        guard let container else {
            throw containerError ?? CocoaError(.fileReadUnknown)
        }

        return container
    }

    private func merge(_ tracks: [Track], into album: AlbumDAO, in context: ModelContext) {
        var storedTracks = album.tracks.reduce(into: [Int: TrackDAO]()) { $0[$1.trackId] = $1 }

        for track in tracks {
            if let storedTrack = storedTracks.removeValue(forKey: track.trackId) {
                storedTrack.update(with: track)
            } else {
                let storedTrack = TrackDAO(track)

                context.insert(storedTrack)
                storedTrack.album = album
            }
        }

        for removedTrack in storedTracks.values {
            context.delete(removedTrack)
        }
    }
}
