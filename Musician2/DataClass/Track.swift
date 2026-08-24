//
//  Track.swift
//  Musician2
//
//  Created by Maksim Ivanov on 05.07.2026.
//

import Foundation

struct Track: Hashable, Decodable, Identifiable {

    let trackId: Int
    let name: String
    let url: String
    let duration: String

    var id: Int { trackId }

    enum CodingKeys: String, CodingKey {
        case trackId, name, url, duration
    }
}

struct TrackData: Equatable {
    let track: Track

    /// The album the track belongs to. It is `nil` when the track comes from a source other than an album.
    let album: Album?

    let autoPlay: Bool
}
