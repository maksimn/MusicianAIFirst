//
//  AudioPlayerFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.07.2026.
//

import SwiftUI

struct AudioPlayerFeature: View {

    var body: some View {
        AudioPlayerView(
            viewModel: AudioPlayerViewModelImpl(
                track: Track(trackId: 1, name: "Анна", url: "http://maksimn.github.io/elizarov/notebook/anna.mp3",
                             duration: "1:08"),
                dataLoader: URLSessionNetworkDataLoader(),
                audioPlayerAPI: AVAudioPlayerAPI(),
                timerAPI: TimerAPIImpl()
            )
        )
    }
}
