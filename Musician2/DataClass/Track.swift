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
    let autoPlay: Bool
}

/// A track the user has picked in a track list, together with the album the track belongs to.
struct TrackSelection: Equatable {
    let album: Album
    let track: Track
}
