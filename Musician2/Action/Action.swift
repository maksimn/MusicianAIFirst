//
//  Action.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

protocol AlbumListLoadedSender {

    func send(_ albums: [Album])
}

protocol AlbumListLoadedListener {

    var albumList: AsyncStream<[Album]> { get }
}

protocol FindNextTrackSender {

    func send()
}

protocol FindNextTrackListener {

    var notification: AsyncStream<Void> { get }
}

protocol NextTrackSender {

    func send(_ trackData: TrackData)
}

protocol NextTrackListener {

    var trackData: AsyncStream<TrackData> { get }
}
