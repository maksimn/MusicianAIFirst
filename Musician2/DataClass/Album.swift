//
//  Album.swift
//  Musician2
//
//  Created by Maksim Ivanov on 05.07.2026.
//

import Foundation

struct Album: Hashable, Decodable, Identifiable {

    let albumId: Int
    let albumName: String
    let albumYear: Int
    let albumCover: String
    let albumMedianColor: String
    let tracks: [Track]

    var id: Int { albumId }

    enum CodingKeys: String, CodingKey {
        case albumId, albumName, albumYear, albumCover, albumMedianColor, tracks
    }
}

extension Album: CustomStringConvertible {
    var description: String {
        return "Album(id: \(id), name: \(albumName)), year: \(albumYear))"
    }
}

extension Album {

    /// Returns the album whose track has been replaced by its changed version.
    ///
    /// The tracks of an album are immutable value copies of the stored ones, so a change of a single
    /// track — the user marking it as a favorite one — has to be carried into the album holding it.
    func replacing(_ track: Track) -> Album {
        guard let index = tracks.firstIndex(where: { $0.trackId == track.trackId }) else { return self }

        var tracks = tracks

        tracks[index] = track

        return Album(
            albumId: albumId,
            albumName: albumName,
            albumYear: albumYear,
            albumCover: albumCover,
            albumMedianColor: albumMedianColor,
            tracks: tracks
        )
    }
}
