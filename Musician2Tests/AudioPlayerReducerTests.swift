@testable import Musician2
import Foundation
import Testing
import UDF

@MainActor
struct AudioPlayerReducerTests {

    private enum TestError: Error {
        case failed
    }

    private let audioPlayerAPI = AudioPlayerAPIMock()

    private let timerAPI = TimerAPIMock()

    private let testDuration = "1:01"

    // MARK: - Initial state

    @Test func initialStateIsInitial() {
        #expect(makeStore().state.condition == .initial)
    }

    @Test func initialTrackIsNil() {
        #expect(makeStore().state.track == nil)
    }

    @Test func initialTimeDisplayIsEmptyString() {
        #expect(makeStore().state.timeDisplay == "")
    }

    @Test func initialProgressValueIsOne() {
        #expect(makeStore().state.progressValue == 1.0)
    }

    @Test func initialProgressIsZero() {
        #expect(makeStore().state.progress == 0)
    }

    @Test func initialCurrentTimeIsZero() {
        #expect(makeStore().state.currentTime == 0)
    }

    // MARK: - Track loading

    @Test func nextTrackActionExposesTheReceivedTrack() async {
        let store = await makeLoadedStore(url: "https://example.com/other.mp3")

        #expect(store.state.track?.url == "https://example.com/other.mp3")
    }

    @Test func loadTrackWithInvalidURLSetsErrorState() async {
        let store = await makeLoadedStore(url: "")

        #expect(isError(store.state.condition))
    }

    @Test func loadTrackSuccessSetsLoadedState() async {
        let store = await makeLoadedStore()

        #expect(store.state.condition == .loaded)
    }

    @Test func loadTrackFailureSetsErrorState() async {
        let store = await makeLoadedStore(downloadError: TestError.failed)

        #expect(isError(store.state.condition))
    }

    @Test func loadTrackSetsLoadingStateWhileDownloading() async {
        let store = makeStore(finishesDownloading: false)

        await store.dispatchAndSettle(AppAction.nextTrack(TrackData(track: makeTrack(), autoPlay: false)))

        #expect(store.state.condition == .loading)
    }

    @Test func loadTrackTwiceSucceedsAndKeepsLoadedState() async {
        let store = await makeLoadedStore()

        store.dispatch(AppAction.nextTrack(TrackData(track: makeTrack(), autoPlay: false)))
        await waitUntilLoaded(store)

        #expect(store.state.condition == .loaded)
    }

    @Test func loadedStateTimeDisplayShowsTrackDuration() async {
        let store = await makeLoadedStore()

        #expect(store.state.timeDisplay == testDuration)
    }

    @Test func loadedStateProgressValueIsOne() async {
        let store = await makeLoadedStore()

        #expect(store.state.progressValue == 1.0)
    }

    @Test func errorStateTimeDisplayShowsTrackDuration() async {
        let store = await makeLoadedStore(downloadError: TestError.failed)

        #expect(store.state.timeDisplay == testDuration)
    }

    // MARK: - Playback control

    @Test func playWithoutLoadedDataDoesNotCallPlay() async {
        let store = makeStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.playCallCount == 0)
    }

    @Test func playWithoutLoadedDataKeepsInitialState() async {
        let store = makeStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(store.state.condition == .initial)
    }

    @Test func playWithoutLoadedDataDoesNotStartTimer() async {
        let store = makeStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(timerAPI.startCallCount == 0)
    }

    @Test func playFromLoadedStateSetsPlayingState() async {
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(store.state.condition == .playing)
    }

    @Test func playFromLoadedStateCallsPlay() async {
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.playCallCount == 1)
    }

    @Test func playFromLoadedStateInitializesOnce() async {
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.initializeCallCount == 1)
    }

    @Test func playFromLoadedStateStartsProgressTimer() async {
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(timerAPI.startCallCount == 1)
    }

    @Test func playWhilePlayingSetsPausedState() async {
        let store = await makePlayingStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(store.state.condition == .paused)
    }

    @Test func playWhilePlayingCallsPause() async {
        let store = await makePlayingStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.pauseCallCount == 1)
    }

    @Test func playWhilePlayingDoesNotCallPlayAgain() async {
        let store = await makePlayingStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.playCallCount == 1)
    }

    @Test func playWhilePlayingStopsProgressTimer() async {
        let store = await makePlayingStore()
        let stopsBeforePause = timerAPI.stopCallCount

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(timerAPI.stopCallCount == stopsBeforePause + 1)
    }

    @Test func playWhilePlayingDoesNotRestartTimer() async {
        let store = await makePlayingStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(timerAPI.startCallCount == 1)
    }

    @Test func playFromPausedStateSetsPlayingState() async {
        let store = await makePausedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(store.state.condition == .playing)
    }

    @Test func playFromPausedStateDoesNotReinitialize() async {
        let store = await makePausedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.initializeCallCount == 1)
    }

    @Test func playFromPausedStateCallsPlayAgain() async {
        let store = await makePausedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.playCallCount == 2)
    }

    @Test func playFromPausedStateRestartsProgressTimer() async {
        let store = await makePausedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(timerAPI.startCallCount == 2)
    }

    @Test func playWhenInitializeFailsSetsErrorState() async {
        audioPlayerAPI.initializeError = TestError.failed
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(isError(store.state.condition))
    }

    @Test func playWhenInitializeFailsDoesNotCallPlay() async {
        audioPlayerAPI.initializeError = TestError.failed
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.playCallCount == 0)
    }

    @Test func playWhenInitializeFailsDoesNotStartTimer() async {
        audioPlayerAPI.initializeError = TestError.failed
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(timerAPI.startCallCount == 0)
    }

    @Test func playFromErrorStateDoesNotRetryInitialize() async {
        audioPlayerAPI.initializeError = TestError.failed
        let store = await makeLoadedStore()
        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.initializeCallCount == 1)
    }

    @Test func playFromErrorStateKeepsErrorState() async {
        audioPlayerAPI.initializeError = TestError.failed
        let store = await makeLoadedStore()
        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(isError(store.state.condition))
    }

    @Test func playAfterLoadFailureDoesNotCallPlay() async {
        let store = await makeLoadedStore(downloadError: TestError.failed)

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.playCallCount == 0)
    }

    @Test func playAfterLoadFailureKeepsErrorState() async {
        let store = await makeLoadedStore(downloadError: TestError.failed)

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(isError(store.state.condition))
    }

    @Test func playWhileLoadingDoesNotCallPlay() async {
        let store = makeStore(finishesDownloading: false)

        await store.dispatchAndSettle(AppAction.nextTrack(TrackData(track: makeTrack(), autoPlay: false)))
        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        #expect(audioPlayerAPI.playCallCount == 0)
    }

    // MARK: - Track selection by the user

    @Test func selectingTheLoadedTrackStartsItsPlayback() async {
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AlbumDetailsAction.trackTapped(makeTrack(), makeAlbum()))

        #expect(store.state.condition == .playing)
    }

    @Test func selectingTheAlreadyPlayingTrackChangesNothing() async {
        let store = await makePlayingStore()

        await store.dispatchAndSettle(AlbumDetailsAction.trackTapped(makeTrack(), makeAlbum()))

        #expect(store.state.condition == .playing)
        #expect(audioPlayerAPI.playCallCount == 1)
    }

    @Test func selectingAnotherTrackResetsThePlayback() async {
        let store = await makePlayingStore()
        let anotherTrack = makeTrack(id: 2, url: "https://example.com/2.mp3")

        await store.dispatchAndSettle(AlbumDetailsAction.trackTapped(anotherTrack, makeAlbum()))

        #expect(store.state.condition == .initial)
        #expect(audioPlayerAPI.pauseCallCount == 1)
    }

    // MARK: - Progress tracking

    @Test func progressTimerUpdatesProgress() async {
        audioPlayerAPI.duration = 100
        audioPlayerAPI.currentTime = 30
        let store = await makePlayingStore()

        timerAPI.fire()
        await store.settled()

        #expect(store.state.progress == 0.3)
    }

    @Test func progressTimerUpdatesTimeDisplay() async {
        audioPlayerAPI.duration = 100
        audioPlayerAPI.currentTime = 30
        let store = await makePlayingStore()

        timerAPI.fire()
        await store.settled()

        #expect(store.state.timeDisplay == "0:30")
    }

    @Test func progressTimerWithZeroDurationKeepsProgressAtZero() async {
        audioPlayerAPI.duration = 0
        audioPlayerAPI.currentTime = 10
        let store = await makePlayingStore()

        timerAPI.fire()
        await store.settled()

        #expect(store.state.progress == 0)
    }

    // MARK: - Playback finishing

    @Test func playbackFinishedResetsStateToInitial() async {
        let store = await makePlayingStore()

        await store.dispatchAndSettle(AudioPlayerAction.playbackFinished)

        #expect(store.state.condition == .initial)
    }

    @Test func playbackFinishedStopsTimer() async {
        let store = await makePlayingStore()
        let stopsBeforeFinish = timerAPI.stopCallCount

        await store.dispatchAndSettle(AudioPlayerAction.playbackFinished)

        #expect(timerAPI.stopCallCount == stopsBeforeFinish + 1)
    }

    @Test func theDelegateOfTheAudioPlayerAPIDispatchesThePlaybackFinishedAction() throws {
        let dispatcher = ActionDispatcherMock()
        let delegate = AudioPlayerDelegateAdapter(dispatcher: dispatcher)

        audioPlayerAPI.delegate = delegate
        audioPlayerAPI.simulateFinishPlaying()

        let action = try #require(dispatcher.dispatchedActions.first as? AudioPlayerAction)

        guard case .playbackFinished = action else {
            Issue.record("Unexpected action: \(action)")
            return
        }
    }

    // MARK: - The next track

    @Test func nextTrackReplacesThePreviousOne() async {
        let store = await makeLoadedStore()

        store.dispatch(AppAction.nextTrack(TrackData(track: makeTrack(id: 2), autoPlay: false)))
        await waitUntilLoaded(store)

        #expect(store.state.track?.trackId == 2)
    }

    @Test func nextTrackIsLoaded() async {
        let store = await makeLoadedStore()

        store.dispatch(AppAction.nextTrack(TrackData(track: makeTrack(id: 2), autoPlay: false)))
        await waitUntilLoaded(store)

        #expect(store.state.condition == .loaded)
    }

    @Test func nextTrackResetsProgress() async {
        audioPlayerAPI.duration = 100
        audioPlayerAPI.currentTime = 30
        let store = await makePlayingStore()
        timerAPI.fire()
        await store.settled()

        store.dispatch(AppAction.nextTrack(TrackData(track: makeTrack(id: 2), autoPlay: false)))
        await waitUntilLoaded(store)

        #expect(store.state.progress == 0)
    }

    // MARK: - Auto play

    @Test func autoPlayTrackSetsPlayingState() async {
        let store = await makeLoadedStore(autoPlay: true)

        #expect(store.state.condition == .playing)
    }

    @Test func autoPlayTrackCallsPlay() async {
        _ = await makeLoadedStore(autoPlay: true)

        #expect(audioPlayerAPI.playCallCount == 1)
    }

    @Test func autoPlayTrackInitializesPlayerOnce() async {
        _ = await makeLoadedStore(autoPlay: true)

        #expect(audioPlayerAPI.initializeCallCount == 1)
    }

    @Test func autoPlayTrackStartsProgressTimer() async {
        _ = await makeLoadedStore(autoPlay: true)

        #expect(timerAPI.startCallCount == 1)
    }

    @Test func trackWithoutAutoPlayKeepsLoadedState() async {
        let store = await makeLoadedStore(autoPlay: false)

        #expect(store.state.condition == .loaded)
    }

    @Test func trackWithoutAutoPlayDoesNotCallPlay() async {
        _ = await makeLoadedStore(autoPlay: false)

        #expect(audioPlayerAPI.playCallCount == 0)
    }

    @Test func autoPlayAfterLoadFailureDoesNotCallPlay() async {
        _ = await makeLoadedStore(autoPlay: true, downloadError: TestError.failed)

        #expect(audioPlayerAPI.playCallCount == 0)
    }

    @Test func autoPlayAfterLoadFailureKeepsErrorState() async {
        let store = await makeLoadedStore(autoPlay: true, downloadError: TestError.failed)

        #expect(isError(store.state.condition))
    }

    @Test func autoPlayWithInvalidURLDoesNotCallPlay() async {
        _ = await makeLoadedStore(url: "", autoPlay: true)

        #expect(audioPlayerAPI.playCallCount == 0)
    }

    @Test func autoPlayAppliesOnlyToTheTracksThatAskForIt() async {
        let store = await makeLoadedStore(autoPlay: true)

        store.dispatch(AppAction.nextTrack(TrackData(track: makeTrack(id: 2), autoPlay: false)))
        await waitUntilLoaded(store)

        #expect(audioPlayerAPI.playCallCount == 1)
    }

    @Test func autoPlayOfTheSecondTrackInitializesThePlayerAgain() async {
        let store = await makeLoadedStore(autoPlay: true)

        store.dispatch(AppAction.nextTrack(TrackData(track: makeTrack(id: 2), autoPlay: true)))
        await waitUntilLoaded(store)

        #expect(audioPlayerAPI.initializeCallCount == 2)
    }

    // MARK: - Helpers

    /// - Parameter finishesDownloading: Pass `false` to keep the player downloading its track forever,
    ///   which is the only way to look at the state of the player while the downloading is in progress.
    private func makeStore(
        downloadData: Data = Data([1, 2, 3]),
        downloadError: Error? = nil,
        finishesDownloading: Bool = true
    ) -> Store<AudioPlayerState> {
        let dataLoader = NetworkDataLoaderMock { _ in
            if let downloadError {
                throw downloadError
            }

            if !finishesDownloading {
                try await Task.sleep(for: .seconds(60))
            }

            return downloadData
        }

        return Store(
            state: AudioPlayerState(),
            reducer: AudioPlayerReducer(
                dataLoader: dataLoader,
                audioPlayerAPI: audioPlayerAPI,
                timerAPI: timerAPI
            ).reduce
        )
    }

    /// Sends the track to the player and waits until the downloading of its data has finished.
    private func makeLoadedStore(
        url: String = "https://example.com/track.mp3",
        autoPlay: Bool = false,
        downloadError: Error? = nil
    ) async -> Store<AudioPlayerState> {
        let store = makeStore(downloadError: downloadError)

        store.dispatch(AppAction.nextTrack(TrackData(track: makeTrack(url: url), autoPlay: autoPlay)))
        await waitUntilLoaded(store)

        return store
    }

    private func makePlayingStore() async -> Store<AudioPlayerState> {
        let store = await makeLoadedStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        return store
    }

    private func makePausedStore() async -> Store<AudioPlayerState> {
        let store = await makePlayingStore()

        await store.dispatchAndSettle(AudioPlayerAction.playPauseTapped)

        return store
    }

    /// Waits until the downloading of the track has finished and the player has done
    /// everything the downloaded track has made it do, such as starting the playback.
    ///
    /// The player is given a track it has to download, so it passes through the initial and
    /// the loading conditions before it reaches the one the test is waiting for.
    private func waitUntilLoaded(_ store: Store<AudioPlayerState>) async {
        await store.waitUntil("the downloading of the track to finish") {
            $0.condition != .initial && $0.condition != .loading
        }

        await store.settled()
    }

    private func isError(_ condition: AudioPlayerCondition) -> Bool {
        if case .error = condition {
            return true
        }

        return false
    }

    private func makeTrack(id: Int = 1, url: String = "https://example.com/track.mp3") -> Track {
        Track(trackId: id, name: "Test Track", url: url, duration: testDuration)
    }

    private func makeAlbum() -> Album {
        Album(
            albumId: 1,
            albumName: "Test Album",
            albumYear: 2026,
            albumCover: "",
            albumMedianColor: "#2E4272",
            tracks: [makeTrack()]
        )
    }
}
