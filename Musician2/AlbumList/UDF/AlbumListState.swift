//
//  AlbumListState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 24.08.2026.
//

import Foundation

/// The state of the album list: the loaded albums and the progress of their loading.
struct AlbumListState {

    var albums: [Album] = []

    var isLoading = false

    var error: Error?
}
