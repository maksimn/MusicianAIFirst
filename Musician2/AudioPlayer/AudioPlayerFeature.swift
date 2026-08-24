//
//  AudioPlayerFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.07.2026.
//

import SwiftUI

struct AudioPlayerFeature: View {

    private let logger: Logger = LoggerImpl(category: "AudioPlayer")

    var body: some View {
        AudioPlayerView(
            viewModel: AudioPlayerViewModelImpl(
                dataLoader: URLSessionNetworkDataLoader(),
                audioPlayerAPI: LoggingAudioPlayerAPI(decorated: AVAudioPlayerAPI(), logger: logger),
                timerAPI: LoggingTimerAPI(decorated: TimerAPIImpl(), logger: logger),
                nextTrackListener: NextTrackStream.shared,
                selectTrackListener: SelectTrackStream.shared,
                findNextTrackSender: FindNextTrackStream.shared,
                logger: logger
            )
        )
    }
}
