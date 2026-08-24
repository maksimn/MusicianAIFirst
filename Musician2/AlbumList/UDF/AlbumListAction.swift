//
//  AlbumListAction.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

/// The actions of the album list feature.
enum AlbumListAction: Action {

    /// The album list has been shown and needs its albums.
    case loadAlbums

    /// The albums have been fetched from the network.
    case albumsLoaded([Album])

    /// The fetching of the albums has failed.
    case loadingFailed(Error)

    /// The albums have been read from the cache after a failed fetching.
    case cachedAlbumsLoaded([Album])
}
