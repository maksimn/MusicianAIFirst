//
//  ContentView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 30.06.2026.
//

import SwiftUI

struct ContentView: View {

    @State private var trackSelector: TrackSelector

    init(trackSelector: TrackSelector = TrackSelectorImpl(
        albumListLoadedListener: AlbumListLoadedStream.shared,
        findNextTrackListener: FindNextTrackStream.shared,
        nextTrackSender: NextTrackStream.shared,
        logger: LoggerImpl(category: "TrackSelector")
    )) {
        _trackSelector = State(wrappedValue: trackSelector)
    }

    var body: some View {
        VStack(spacing: 2) {
            AlbumListFeature()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task {
                    CurrentTrackProviderImpl.shared.start()
                    trackSelector.start()
                }

            AudioPlayerFeature()
        }
    }
}

#Preview {
    ContentView()
}
