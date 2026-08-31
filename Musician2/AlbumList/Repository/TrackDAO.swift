//
//  TrackDAO.swift
//  Musician2
//
//  Created by Maksim Ivanov on 31.08.2026.
//

import Foundation
import SwiftData

/// The SwiftData entity behind `Track`. Besides the fields of the remote JSON it stores the two
/// device-owned ones — `isFavorite` and `updatedAt` — which is the reason the cache had to become a
/// database instead of a dump of the downloaded JSON.
@Model
final class TrackDAO {

    var trackId: Int = 0
    var name: String = ""
    var url: String = ""
    var duration: String = ""
    var isFavorite: Bool = false
    var updatedAt: Int = 0

    /// Optional because SwiftData requires the inverse side of a relationship to be nullable; a track
    /// without an album is never created by the app.
    var album: AlbumDAO?

    init(trackId: Int, name: String, url: String, duration: String, isFavorite: Bool, updatedAt: Int) {
        self.trackId = trackId
        self.name = name
        self.url = url
        self.duration = duration
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }

    convenience init(_ track: Track) {
        self.init(
            trackId: track.trackId,
            name: track.name,
            url: track.url,
            duration: track.duration,
            isFavorite: track.isFavorite,
            updatedAt: track.updatedAt
        )
    }

    /// Only the fields the feed owns are refreshed: `isFavorite` and `updatedAt` are set by the user on
    /// this device, and a re-download of the album list must not silently reset them.
    func update(with track: Track) {
        name = track.name
        url = track.url
        duration = track.duration
    }

    func toTrack() -> Track {
        Track(
            trackId: trackId,
            name: name,
            url: url,
            duration: duration,
            isFavorite: isFavorite,
            updatedAt: updatedAt
        )
    }
}
