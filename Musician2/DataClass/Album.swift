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
