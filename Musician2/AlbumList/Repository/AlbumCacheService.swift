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

    /// Writes back the device-owned data of a single track — the favorite flag the user has just
    /// changed — leaving the rest of the stored album alone.
    func saveTrack(_ track: Track) throws

    func loadAlbums() throws -> [Album]

    /// Reads a single stored album, with the device-owned data of its tracks as it is right now: the
    /// storage is the only place where the favorite flags changed since the list was loaded are up to date.
    func loadAlbum(albumId: Int) throws -> Album

    /// Reads the tracks marked as favorite ones out of every stored album at once, the one marked
    /// last coming first: the favorites belong to no single album, and the storage is the only place
    /// holding the flags of all the albums together.
    func loadFavoriteTracks() throws -> [Track]
}

/// The failures of the album storage that are its own rather than the database's.
enum AlbumCacheError: Error {

    /// A track missing from the store has been changed: it can only happen if the album the track
    /// belongs to has disappeared from the feed while its tracklist was on the screen.
    case trackNotFound(trackId: Int)

    /// An album missing from the store has been asked for: it can only happen if the album has
    /// disappeared from the feed, or never got into the store, after it was shown in the list.
    case albumNotFound(albumId: Int)
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

    /// Unlike the albums of the feed, the track is looked up on its own and not through its album:
    /// nothing but the data the device owns changes here, so there is nothing to merge.
    func saveTrack(_ track: Track) throws {
        let context = ModelContext(try modelContainer())
        let trackId = track.trackId
        var descriptor = FetchDescriptor<TrackDAO>(predicate: #Predicate { $0.trackId == trackId })

        descriptor.fetchLimit = 1

        guard let storedTrack = try context.fetch(descriptor).first else {
            throw AlbumCacheError.trackNotFound(trackId: trackId)
        }

        storedTrack.updateDeviceOwnedData(with: track)

        try context.save()
    }

    func loadAlbums() throws -> [Album] {
        let context = ModelContext(try modelContainer())

        return try context.fetch(FetchDescriptor<AlbumDAO>()).map { $0.toAlbum() }
    }

    func loadAlbum(albumId: Int) throws -> Album {
        let context = ModelContext(try modelContainer())
        var descriptor = FetchDescriptor<AlbumDAO>(predicate: #Predicate { $0.albumId == albumId })

        descriptor.fetchLimit = 1

        guard let storedAlbum = try context.fetch(descriptor).first else {
            throw AlbumCacheError.albumNotFound(albumId: albumId)
        }

        return storedAlbum.toAlbum()
    }

    /// The tracks are fetched on their own and not through their albums, because the favorites are a
    /// list of tracks and not of albums; they are ordered by the moment the flag was last changed,
    /// which is exactly what `updatedAt` is stored for.
    func loadFavoriteTracks() throws -> [Track] {
        let context = ModelContext(try modelContainer())
        let descriptor = FetchDescriptor<TrackDAO>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try context.fetch(descriptor).map { $0.toTrack() }
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
