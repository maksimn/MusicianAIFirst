//
//  AlbumListView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 05.07.2026.
//

import SwiftUI

struct AlbumListView: View {
    @State private var viewModel: AlbumListViewModel

    init(viewModel: AlbumListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Albums")
            .refreshable {
                await viewModel.loadAlbums()
            }
            .task {
                await viewModel.loadAlbums()
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        List(viewModel.albums) { album in
            AlbumRowView(album: album)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}

// MARK: - Album Row

private struct AlbumRowView: View {
    let album: Album

    var body: some View {
        let albumColor = Color(hex: album.albumMedianColor) ?? .clear
        let textColor = albumTextColor(for: albumColor)

        HStack(alignment: .top, spacing: 0) {
            AsyncImage(url: URL(string: album.albumCover)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderImage
            }
            .frame(width: 96, height: 96)
            .padding(.top, 24)
            .padding(.leading, 24)

            VStack(alignment: .leading, spacing: 0) {
                Text(album.albumName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.top, 24)
                    .padding(.leading, 24)
                    .padding(.trailing, 24)

                Spacer()

                Text("Альбом, \(album.albumYear)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.bottom, 24)
                    .padding(.leading, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 144)
        .background(albumColor)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
            }
    }
}

func albumTextColor(for color: Color) -> Color {
    color.isBright ? Color(red: 0.15, green: 0.15, blue: 0.15) : .white
}

// MARK: - Album Detail

private struct AlbumDetailView: View {
    let album: Album

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: album.albumName)
                LabeledContent("Year", value: "\(album.albumYear)")
            }

            Section("Tracks") {
                ForEach(album.tracks) { track in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.name)
                            .font(.body)
                        Text(track.duration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(album.albumName)
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
