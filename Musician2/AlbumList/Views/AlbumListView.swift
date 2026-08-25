//
//  AlbumListView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 05.07.2026.
//

import SwiftUI

struct AlbumListView<Details: View>: View {

    let store: ObservableStore<AlbumListState>

    @ViewBuilder let details: () -> Details

    @State private var path: [Album] = []

    private var state: AlbumListState {
        store.state
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if state.isLoading {
                    ProgressView("Loading albums…")
                } else if let error = state.error, state.albums.isEmpty {
                    ContentUnavailableView(
                        "Failed to load albums",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                } else if state.albums.isEmpty {
                    ContentUnavailableView(
                        "No albums",
                        systemImage: "music.note.list",
                        description: Text("Pull to refresh or try again later.")
                    )
                } else {
                    listContent
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Album.self) { _ in
                details()
            }
            .onAppear {
                store.dispatch(AlbumListAction.loadAlbums)
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        List(state.albums) { album in
            Button {
                store.dispatch(AlbumListAction.albumTapped(album))
                path.append(album)
            } label: {
                AlbumRowView(album: album)
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
