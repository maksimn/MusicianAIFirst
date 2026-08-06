//
//  AudioPlayerFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.07.2026.
//

import SwiftUI

// AIF: Logging for the AudioPlayer feature.

struct AudioPlayerFeature: View {

    private let logger: Logger = LoggerImpl(category: "AudioPlayer")

    var body: some View {
        AudioPlayerView(
            viewModel: AudioPlayerViewModelImpl(
                track: Track(trackId: 1, name: "Анна", url: "http://maksimn.github.io/elizarov/notebook/anna.mp3",
                             duration: "1:08"),
                dataLoader: URLSessionNetworkDataLoader(),
                audioPlayerAPI: LoggingAudioPlayerAPI(decorated: AVAudioPlayerAPI(), logger: logger),
                timerAPI: LoggingTimerAPI(decorated: TimerAPIImpl(), logger: logger),
                logger: logger
            )
        )
    }
}
