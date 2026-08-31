//
//  AlbumDAO.swift
//  Musician2
//
//  Created by Maksim Ivanov on 31.08.2026.
//

import Foundation
import SwiftData

/// The SwiftData entity behind `Album`. It exists separately from the `Album` value type so that
/// the rest of the app keeps working with immutable structs and never leaks persistence into the
/// UDF state, which must stay `Equatable` and free of managed objects.
@Model
final class AlbumDAO {

    /// Albums are addressed by their remote id everywhere in the app, so the store enforces it as a key.
    #Unique<AlbumDAO>([\.albumId])

    var albumId: Int = 0
    var albumName: String = ""
    var albumYear: Int = 0
    var albumCover: String = ""
    var albumMedianColor: String = ""

    /// Cascading, because a track only ever exists as part of its album — dropping an album that has
    /// disappeared from the feed must not leave its tracks orphaned in the store.
    @Relationship(deleteRule: .cascade, inverse: \TrackDAO.album)
    var tracks: [TrackDAO] = []

    init(albumId: Int, albumName: String, albumYear: Int, albumCover: String, albumMedianColor: String) {
        self.albumId = albumId
        self.albumName = albumName
        self.albumYear = albumYear
        self.albumCover = albumCover
        self.albumMedianColor = albumMedianColor
    }

    convenience init(_ album: Album) {
        self.init(
            albumId: album.albumId,
            albumName: album.albumName,
            albumYear: album.albumYear,
            albumCover: album.albumCover,
            albumMedianColor: album.albumMedianColor
        )
    }

    /// Overwrites the fields the remote feed owns, leaving the relationship to the caller: the tracks
    /// are merged separately so that locally owned track data is not lost on a refresh.
    func update(with album: Album) {
        albumName = album.albumName
        albumYear = album.albumYear
        albumCover = album.albumCover
        albumMedianColor = album.albumMedianColor
    }

    /// The track order of the feed is meaningful (it is the playback order), and SwiftData does not
    /// preserve the order of a to-many relationship, so it is restored by track id here.
    func toAlbum() -> Album {
        Album(
            albumId: albumId,
            albumName: albumName,
            albumYear: albumYear,
            albumCover: albumCover,
            albumMedianColor: albumMedianColor,
            tracks: tracks.sorted { $0.trackId < $1.trackId }.map { $0.toTrack() }
        )
    }
}
