@testable import Musician2
import Foundation
import Testing

@MainActor
struct AudioPlayerViewModelTests {

    private enum TestError: Error {
        case failed
    }

    let testDuration = "1:01"

    private func makeSUT(
        url: String = "https://example.com/track.mp3",
        downloadData: Data = Data([1, 2, 3]),
        downloadError: Error? = nil,
        audioPlayerAPI: AudioPlayerAPIMock = AudioPlayerAPIMock(),
        timerAPI: TimerAPIMock = TimerAPIMock()
    ) -> (
        AudioPlayerViewModelImpl,
        AudioPlayerAPIMock,
        TimerAPIMock,
        NetworkDataLoaderMock
    ) {
        let track = Track(trackId: 1, name: "Test Track", url: url, duration: testDuration)
        let dataLoader = NetworkDataLoaderMock { _ in
            if let downloadError {
                throw downloadError
            }
            return downloadData
        }

        let viewModel = AudioPlayerViewModelImpl(
            track: track,
            dataLoader: dataLoader,
            audioPlayerAPI: audioPlayerAPI,
            timerAPI: timerAPI,
            logger: LoggerMock()
        )

        return (viewModel, audioPlayerAPI, timerAPI, dataLoader)
    }

    private func makeLoadedViewModel(
        downloadData: Data = Data([1, 2, 3]),
        audioPlayerAPI: AudioPlayerAPIMock = .init(),
        timerAPI: TimerAPIMock = .init()
    ) async -> (
        AudioPlayerViewModelImpl,
        AudioPlayerAPIMock,
        TimerAPIMock
    ) {
        let (viewModel, audioMock, timerMock, _) = makeSUT(
            downloadData: downloadData,
            audioPlayerAPI: audioPlayerAPI,
            timerAPI: timerAPI
        )
        await viewModel.loadTrack()
        return (viewModel, audioMock, timerMock)
    }

    private func makePlayingViewModel(
        audioPlayerAPI: AudioPlayerAPIMock = .init(),
        timerAPI: TimerAPIMock = .init()
    ) async -> (
        AudioPlayerViewModelImpl,
        AudioPlayerAPIMock,
        TimerAPIMock
    ) {
        let (viewModel, audioMock, timerMock) = await makeLoadedViewModel(
            audioPlayerAPI: audioPlayerAPI,
            timerAPI: timerAPI
        )
        viewModel.play()
        return (viewModel, audioMock, timerMock)
    }

    private func makePlayingViewModel(
        currentTime: TimeInterval,
        duration: TimeInterval = 100
    ) async -> (
        AudioPlayerViewModelImpl,
        AudioPlayerAPIMock,
        TimerAPIMock
    ) {
        let audioMock = AudioPlayerAPIMock()
        audioMock.currentTime = currentTime
        audioMock.duration = duration
        return await makePlayingViewModel(
            audioPlayerAPI: audioMock,
            timerAPI: TimerAPIMock()
        )
    }

    // MARK: - Initial state

    @Test func initialStateIsInitial() {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.state == .initial)
    }

    @Test func initialTimeDisplayShowsTrackDuration() {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.timeDisplay == testDuration)
    }

    @Test func initialProgressValueIsOne() {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.progressValue == 1.0)
    }

    @Test func initialProgressIsZero() {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.progress == 0)
    }

    @Test func initialCurrentTimeIsZero() {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.currentTime == 0)
    }

    @Test func initExposesInjectedTrack() {
        let (viewModel, _, _, _) = makeSUT(url: "https://example.com/other.mp3")

        #expect(viewModel.track.url == "https://example.com/other.mp3")
    }

    @Test func initSetsItselfAsAudioPlayerDelegate() {
        let (viewModel, audioMock, _, _) = makeSUT()

        #expect(audioMock.delegate === viewModel)
    }

    // MARK: - Track loading

    @Test func loadTrackWithInvalidURLSetsErrorState() async {
        let (viewModel, _, _, _) = makeSUT(url: "")

        await viewModel.loadTrack()

        #expect(viewModel.state == .error)
    }

    @Test func loadTrackSuccessSetsLoadedState() async {
        let (viewModel, _, _, _) = makeSUT()

        await viewModel.loadTrack()

        #expect(viewModel.state == .loaded)
    }

    @Test func loadTrackFailureSetsErrorState() async {
        let (viewModel, _, _, _) = makeSUT(downloadError: TestError.failed)

        await viewModel.loadTrack()

        #expect(viewModel.state == .error)
    }

    @Test func loadTrackSetsLoadingStateWhileDownloading() async {
        var stateDuringDownload: AudioPlayerState?
        var loadingViewModel: AudioPlayerViewModelImpl?
        let dataLoader = NetworkDataLoaderMock { _ in
            stateDuringDownload = loadingViewModel?.state
            return Data([1, 2, 3])
        }
        let track = Track(trackId: 1, name: "Test Track", url: "https://example.com/track.mp3", duration: testDuration)
        let viewModel = AudioPlayerViewModelImpl(
            track: track,
            dataLoader: dataLoader,
            audioPlayerAPI: AudioPlayerAPIMock(),
            timerAPI: TimerAPIMock(),
            logger: LoggerMock()
        )
        loadingViewModel = viewModel

        await viewModel.loadTrack()

        #expect(stateDuringDownload == .loading)
    }

    @Test func loadTrackTwiceSucceedsAndKeepsLoadedState() async {
        let (viewModel, _, _, _) = makeSUT()

        await viewModel.loadTrack()
        await viewModel.loadTrack()

        #expect(viewModel.state == .loaded)
    }

    @Test func loadedStateTimeDisplayShowsTrackDuration() async {
        let (viewModel, _, _) = await makeLoadedViewModel()

        #expect(viewModel.timeDisplay == testDuration)
    }

    @Test func loadedStateProgressValueIsOne() async {
        let (viewModel, _, _) = await makeLoadedViewModel()

        #expect(viewModel.progressValue == 1.0)
    }

    @Test func errorStateTimeDisplayShowsTrackDuration() async {
        let (viewModel, _, _, _) = makeSUT(downloadError: TestError.failed)

        await viewModel.loadTrack()

        #expect(viewModel.timeDisplay == testDuration)
    }

    // MARK: - Playback control

    @Test func playWithoutLoadedDataDoesNotCallPlay() {
        let (viewModel, audioMock, _, _) = makeSUT()

        viewModel.play()

        #expect(audioMock.playCallCount == 0)
    }

    @Test func playWithoutLoadedDataKeepsInitialState() {
        let (viewModel, _, _, _) = makeSUT()

        viewModel.play()

        #expect(viewModel.state == .initial)
    }

    @Test func playWithoutLoadedDataDoesNotStartTimer() {
        let (viewModel, _, timerMock, _) = makeSUT()

        viewModel.play()

        #expect(timerMock.startCallCount == 0)
    }

    @Test func playFromLoadedStateSetsPlayingState() async {
        let (viewModel, _, _) = await makeLoadedViewModel()

        viewModel.play()

        #expect(viewModel.state == .playing)
    }

    @Test func playFromLoadedStateCallsPlay() async {
        let (viewModel, audioMock, _) = await makeLoadedViewModel()

        viewModel.play()

        #expect(audioMock.playCallCount == 1)
    }

    @Test func playFromLoadedStateInitializesOnce() async {
        let (viewModel, audioMock, _) = await makeLoadedViewModel()

        viewModel.play()

        #expect(audioMock.initializeCallCount == 1)
    }

    @Test func playFromLoadedStateStartsProgressTimer() async {
        let (viewModel, _, timerMock) = await makeLoadedViewModel()

        viewModel.play()

        #expect(timerMock.startCallCount == 1)
    }

    @Test func playWhilePlayingSetsPausedState() async {
        let (viewModel, _, _) = await makePlayingViewModel()

        viewModel.play()

        #expect(viewModel.state == .paused)
    }

    @Test func playWhilePlayingCallsPause() async {
        let (viewModel, audioMock, _) = await makePlayingViewModel()

        viewModel.play()

        #expect(audioMock.pauseCallCount == 1)
    }

    @Test func playWhilePlayingDoesNotCallPlayAgain() async {
        let (viewModel, audioMock, _) = await makePlayingViewModel()

        viewModel.play()

        #expect(audioMock.playCallCount == 1)
    }

    @Test func playWhilePlayingStopsProgressTimer() async {
        let (viewModel, _, timerMock) = await makePlayingViewModel()
        let stopsBeforePause = timerMock.stopCallCount

        viewModel.play()

        #expect(timerMock.stopCallCount == stopsBeforePause + 1)
    }

    @Test func playWhilePlayingDoesNotRestartTimer() async {
        let (viewModel, _, timerMock) = await makePlayingViewModel()

        viewModel.play()

        #expect(timerMock.startCallCount == 1)
    }

    @Test func playFromPausedStateSetsPlayingState() async {
        let (viewModel, _, _) = await makePlayingViewModel()
        viewModel.play()

        viewModel.play()

        #expect(viewModel.state == .playing)
    }

    @Test func playFromPausedStateDoesNotReinitialize() async {
        let (viewModel, audioMock, _) = await makePlayingViewModel()
        viewModel.play()

        viewModel.play()

        #expect(audioMock.initializeCallCount == 1)
    }

    @Test func playFromPausedStateCallsPlayAgain() async {
        let (viewModel, audioMock, _) = await makePlayingViewModel()
        viewModel.play()

        viewModel.play()

        #expect(audioMock.playCallCount == 2)
    }

    @Test func playFromPausedStateRestartsProgressTimer() async {
        let (viewModel, _, timerMock) = await makePlayingViewModel()
        viewModel.play()

        viewModel.play()

        #expect(timerMock.startCallCount == 2)
    }

    @Test func playWhenInitializeFailsSetsErrorState() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.initializeError = TestError.failed
        let (viewModel, _, _) = await makeLoadedViewModel(audioPlayerAPI: audioMock)

        viewModel.play()

        #expect(viewModel.state == .error)
    }

    @Test func playWhenInitializeFailsDoesNotCallPlay() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.initializeError = TestError.failed
        let (viewModel, _, _) = await makeLoadedViewModel(audioPlayerAPI: audioMock)

        viewModel.play()

        #expect(audioMock.playCallCount == 0)
    }

    @Test func playWhenInitializeFailsDoesNotStartTimer() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.initializeError = TestError.failed
        let (viewModel, _, timerMock) = await makeLoadedViewModel(audioPlayerAPI: audioMock)

        viewModel.play()

        #expect(timerMock.startCallCount == 0)
    }

    @Test func playFromErrorStateDoesNotRetryInitialize() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.initializeError = TestError.failed
        let (viewModel, _, _) = await makeLoadedViewModel(audioPlayerAPI: audioMock)
        viewModel.play()

        viewModel.play()

        #expect(audioMock.initializeCallCount == 1)
    }

    @Test func playFromErrorStateKeepsErrorState() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.initializeError = TestError.failed
        let (viewModel, _, _) = await makeLoadedViewModel(audioPlayerAPI: audioMock)
        viewModel.play()

        viewModel.play()

        #expect(viewModel.state == .error)
    }

    @Test func playAfterLoadFailureDoesNotCallPlay() async {
        let (viewModel, audioMock, _, _) = makeSUT(downloadError: TestError.failed)

        await viewModel.loadTrack()
        viewModel.play()

        #expect(audioMock.playCallCount == 0)
    }

    @Test func playAfterLoadFailureKeepsErrorState() async {
        let (viewModel, _, _, _) = makeSUT(downloadError: TestError.failed)

        await viewModel.loadTrack()
        viewModel.play()

        #expect(viewModel.state == .error)
    }

    @Test func playWhileLoadingDoesNotCallPlay() async {
        var playCountDuringLoad = 0
        var loadingViewModel: AudioPlayerViewModelImpl?
        let audioMock = AudioPlayerAPIMock()
        let dataLoader = NetworkDataLoaderMock { _ in
            loadingViewModel?.play()
            playCountDuringLoad = audioMock.playCallCount
            return Data([1, 2, 3])
        }
        let track = Track(trackId: 1, name: "Test Track", url: "https://example.com/track.mp3", duration: testDuration)
        let viewModel = AudioPlayerViewModelImpl(
            track: track,
            dataLoader: dataLoader,
            audioPlayerAPI: audioMock,
            timerAPI: TimerAPIMock(),
            logger: LoggerMock()
        )
        loadingViewModel = viewModel

        await viewModel.loadTrack()

        #expect(playCountDuringLoad == 0)
    }

    // MARK: - Progress tracking

    @Test func progressTimerUpdatesProgress() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.duration = 100
        audioMock.currentTime = 30
        let timerMock = TimerAPIMock()
        let (viewModel, _, _) = await makePlayingViewModel(
            audioPlayerAPI: audioMock,
            timerAPI: timerMock
        )

        timerMock.fire()

        #expect(viewModel.progress == 0.3)
    }

    @Test func progressTimerUpdatesTimeDisplay() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.duration = 100
        audioMock.currentTime = 30
        let timerMock = TimerAPIMock()
        let (viewModel, _, _) = await makePlayingViewModel(
            audioPlayerAPI: audioMock,
            timerAPI: timerMock
        )

        timerMock.fire()

        #expect(viewModel.timeDisplay == "0:30")
    }

    @Test func progressTimerWithZeroDurationKeepsProgressAtZero() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.duration = 0
        audioMock.currentTime = 10
        let timerMock = TimerAPIMock()
        let (viewModel, _, _) = await makePlayingViewModel(
            audioPlayerAPI: audioMock,
            timerAPI: timerMock
        )

        timerMock.fire()

        #expect(viewModel.progress == 0)
    }

    // MARK: - Did finish playing

    @Test func didFinishPlayingResetsStateToInitial() async {
        let (viewModel, audioMock, _) = await makePlayingViewModel()

        audioMock.simulateFinishPlaying()

        #expect(viewModel.state == .initial)
    }

    @Test func didFinishPlayingStopsTimer() async {
        let (_, audioMock, timerMock) = await makePlayingViewModel()

        audioMock.simulateFinishPlaying()

        #expect(timerMock.stopCallCount >= 1)
    }
}
