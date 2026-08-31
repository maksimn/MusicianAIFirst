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
    var isFavorite: Bool
    var updatedAt: Int /// Time of the latest update of this object as a Unix timestamp

    var id: Int { trackId }

    enum CodingKeys: String, CodingKey {
        case trackId, name, url, duration, isFavorite, updatedAt
    }
}

extension Track {

    /// Declared in an extension so that the memberwise initializer stays synthesized: the locally owned
    /// properties are absent from the remote JSON and fall back to "not a favorite, never updated".
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        trackId = try container.decode(Int.self, forKey: .trackId)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        duration = try container.decode(String.self, forKey: .duration)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        updatedAt = try container.decodeIfPresent(Int.self, forKey: .updatedAt) ?? 0
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
