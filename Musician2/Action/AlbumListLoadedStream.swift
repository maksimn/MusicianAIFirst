//
//  AlbumListLoadedStream.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

import Foundation

/// The `AlbumListLoaded` action: the album list feature notifies its listeners about the loaded albums.
nonisolated final class AlbumListLoadedStream: AlbumListLoadedSender, AlbumListLoadedListener, @unchecked Sendable {

    static let shared = AlbumListLoadedStream()

    var albumList: AsyncStream<[Album]> {
        stream.values
    }

    private let stream = ActionStream<[Album]>()

    private init() {}

    func send(_ albums: [Album]) {
        stream.send(albums)
    }
}
