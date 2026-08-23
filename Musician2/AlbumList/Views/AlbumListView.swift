//
//  AlbumListView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 05.07.2026.
//

import SwiftUI

struct AlbumListView: View {
    @State private var viewModel: AlbumListViewModel

    @State private var path: [Album] = []

    init(viewModel: AlbumListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading albums…")
                } else if let error = viewModel.error, viewModel.albums.isEmpty {
                    ContentUnavailableView(
                        "Failed to load albums",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                } else if viewModel.albums.isEmpty {
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
            .navigationDestination(for: Album.self) { album in
                AlbumDetailsFeature(album: album)
            }
            .task {
                await viewModel.loadAlbums()
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        List(viewModel.albums) { album in
            Button {
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

#Preview {
    let repository = AlbumRepository(
        dataLoader: URLSessionNetworkDataLoader(),
        cacheService: FileCacheService()
    )
    let viewModel = AlbumListViewModel(
        repository: repository,
        albumListLoadedSender: AlbumListLoadedStream.shared
    )

    return AlbumListView(viewModel: viewModel)
}
