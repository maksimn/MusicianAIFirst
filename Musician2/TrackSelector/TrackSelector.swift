//
//  TrackSelector.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

import Foundation

protocol TrackSelector: AnyObject {

    /// Starts listening to the actions the track selection is based on.
    func start()
}

final class TrackSelectorImpl: TrackSelector {

    private var selectedAlbum: Album?

    private var selectedTrack: Track?

    private let albumListLoadedListener: AlbumListLoadedListener

    private let findNextTrackListener: FindNextTrackListener

    private let nextTrackSender: NextTrackSender

    private let logger: Logger

    private var albumListTask: Task<Void, Never>?

    private var findNextTrackTask: Task<Void, Never>?

    init(
        albumListLoadedListener: AlbumListLoadedListener,
        findNextTrackListener: FindNextTrackListener,
        nextTrackSender: NextTrackSender,
        logger: Logger
    ) {
        self.albumListLoadedListener = albumListLoadedListener
        self.findNextTrackListener = findNextTrackListener
        self.nextTrackSender = nextTrackSender
        self.logger = logger
    }

    deinit {
        albumListTask?.cancel()
        findNextTrackTask?.cancel()
    }

    func start() {
        startListeningToAlbumList()
        startListeningToFindNextTrack()
    }

    // MARK: - Initial track selection

    private func startListeningToAlbumList() {
        guard albumListTask == nil else { return }

        albumListTask = Task { [weak self] in
            guard let albumList = self?.albumListLoadedListener.albumList else { return }

            for await albums in albumList {
                self?.selectInitialTrack(from: albums)
            }
        }
    }

    /// The initial track of the application is the first track of the last loaded album.
    private func selectInitialTrack(from albums: [Album]) {
        logger.log("Received \(albums.count) album(s) from the AlbumListLoaded stream.", level: .info)

        guard let album = albums.last else {
            logger.log("The loaded album list is empty, there is nothing to select.", level: .warn)
            return
        }

        guard let track = album.tracks.first else {
            logger.log("The '\(album.albumName)' album has no tracks, there is nothing to select.", level: .warn)
            return
        }

        selectedAlbum = album
        select(track, of: album, autoPlay: false)
    }

    // MARK: - Next track selection

    private func startListeningToFindNextTrack() {
        guard findNextTrackTask == nil else { return }

        findNextTrackTask = Task { [weak self] in
            guard let notification = self?.findNextTrackListener.notification else { return }

            for await _ in notification {
                self?.selectNextTrack()
            }
        }
    }

    /// The next track is the one following the selected track in the album the selected track belongs to.
    private func selectNextTrack() {
        logger.log("Received a FindNextTrack request.", level: .info)

        guard let album = selectedAlbum, let track = selectedTrack else {
            logger.log("No track has been selected yet, there is no next track to find.", level: .warn)
            return
        }

        guard let index = album.tracks.firstIndex(where: { $0.trackId == track.trackId }) else {
            logger.log("The '\(track.name)' track is not found in the '\(album.albumName)' album.", level: .error)
            return
        }

        let nextIndex = index + 1 < album.tracks.count ? index + 1 : 0

        select(album.tracks[nextIndex], of: album, autoPlay: true)
    }

    // MARK: - Helpers

    private func select(_ track: Track, of album: Album, autoPlay: Bool) {
        selectedTrack = track
        logger.log("The '\(track.name)' track of the '\(album.albumName)' album has been selected.", level: .info)

        nextTrackSender.send(TrackData(track: track, autoPlay: autoPlay))
    }
}
