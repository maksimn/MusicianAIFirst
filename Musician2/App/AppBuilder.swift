//
//  AppAssembly.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// Assembles the application: the common store with the reducers of all the features,
/// their dependencies and the objects that connect the store to the outer world.
final class AppBuilder {

    /// The audio player API keeps a weak reference to its delegate, so the adapter is kept alive here.
    private var audioPlayerDelegate: AudioPlayerDelegate?

    private var disposable: Disposable?

    private let disposer = Disposer()

    deinit {
        disposable?.dispose(on: disposer)
    }

    func build() -> Store<AppState> {
        let audioPlayerLogger = LoggerImpl(category: "AudioPlayer")
        var audioPlayerAPI: AudioPlayerAPI = LoggingAudioPlayerAPI(
            decorated: AVAudioPlayerAPI(),
            logger: audioPlayerLogger
        )

        // The album list and the tracklist share the storage: they work with the same albums,
        // one saving them from the feed and the other writing the favorite flags back.
        let albumCacheService = SwiftDataAlbumCacheService()

        let reducer = AppReducer(
            albumListReducer: AlbumListReducer(
                dataLoader: URLSessionNetworkDataLoader(),
                cacheService: albumCacheService
            ),
            albumTracklistReducer: AlbumTracklistReducer(
                cacheService: albumCacheService,
                logger: LoggerImpl(category: "AlbumTracklist")
            ),
            audioPlayerReducer: AudioPlayerReducer(
                dataLoader: URLSessionNetworkDataLoader(),
                audioPlayerAPI: audioPlayerAPI,
                timerAPI: LoggingTimerAPI(decorated: TimerAPIImpl(), logger: audioPlayerLogger)
            ),
            trackSelectorReducer: TrackSelectorReducer()
        )

        let store = Store(state: AppState(), reducer: reducer.reduce)
        let audioPlayerDelegate = AudioPlayerDelegateAdapter(dispatcher: store)

        audioPlayerAPI.delegate = audioPlayerDelegate
        self.audioPlayerDelegate = audioPlayerDelegate

        if isDevelopment() {
            disposable = store.onAction(with: { (state, action) in
                if case AudioPlayerAction.progress(_, _) = action {
                    return
                }

                debugPrint(Action.self, action)
                print()
            })
        }

        return store
    }
}
