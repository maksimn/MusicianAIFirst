@testable import Musician2
import Foundation
import Testing

@MainActor
struct AudioPlayerViewModelTests {

    private enum TestError: Error {
        case failed
    }

    private func isError(_ state: AudioPlayerState) -> Bool {
        if case .error = state {
            return true
        }
        return false
    }

    let testDuration = "1:01"

    private func makeTrack(url: String = "https://example.com/track.mp3") -> Track {
        Track(trackId: 1, name: "Test Track", url: url, duration: testDuration)
    }

    private func makeSUT(
        url: String = "https://example.com/track.mp3",
        downloadData: Data = Data([1, 2, 3]),
        downloadError: Error? = nil,
        autoPlay: Bool = false,
        audioPlayerAPI: AudioPlayerAPIMock = AudioPlayerAPIMock(),
        timerAPI: TimerAPIMock = TimerAPIMock(),
        findNextTrackSender: FindNextTrackSenderMock = FindNextTrackSenderMock()
    ) -> (
        AudioPlayerViewModelImpl,
        AudioPlayerAPIMock,
        TimerAPIMock,
        NetworkDataLoaderMock
    ) {
        let dataLoader = NetworkDataLoaderMock { _ in
            if let downloadError {
                throw downloadError
            }
            return downloadData
        }

        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: dataLoader,
            audioPlayerAPI: audioPlayerAPI,
            timerAPI: timerAPI,
            nextTrackListener: NextTrackListenerMock([makeTrack(url: url)], autoPlay: autoPlay),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: findNextTrackSender,
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
        await viewModel.start()
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

    @Test func initialTrackIsNil() {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.track == nil)
    }

    @Test func initialTimeDisplayIsEmptyString() {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.timeDisplay == "")
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

    @Test func startExposesTrackReceivedFromNextTrackAction() async {
        let (viewModel, _, _, _) = makeSUT(url: "https://example.com/other.mp3")

        await viewModel.start()

        #expect(viewModel.track?.url == "https://example.com/other.mp3")
    }

    @Test func initSetsItselfAsAudioPlayerDelegate() {
        let (viewModel, audioMock, _, _) = makeSUT()

        #expect(audioMock.delegate === viewModel)
    }

    // MARK: - Track loading

    @Test func loadTrackWithInvalidURLSetsErrorState() async {
        let (viewModel, _, _, _) = makeSUT(url: "")

        await viewModel.start()

        #expect(isError(viewModel.state))
    }

    @Test func loadTrackSuccessSetsLoadedState() async {
        let (viewModel, _, _, _) = makeSUT()

        await viewModel.start()

        #expect(viewModel.state == .loaded)
    }

    @Test func loadTrackFailureSetsErrorState() async {
        let (viewModel, _, _, _) = makeSUT(downloadError: TestError.failed)

        await viewModel.start()

        #expect(isError(viewModel.state))
    }

    @Test func loadTrackSetsLoadingStateWhileDownloading() async {
        var stateDuringDownload: AudioPlayerState?
        var loadingViewModel: AudioPlayerViewModelImpl?
        let dataLoader = NetworkDataLoaderMock { _ in
            stateDuringDownload = loadingViewModel?.state
            return Data([1, 2, 3])
        }
        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: dataLoader,
            audioPlayerAPI: AudioPlayerAPIMock(),
            timerAPI: TimerAPIMock(),
            nextTrackListener: NextTrackListenerMock([makeTrack()]),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: FindNextTrackSenderMock(),
            logger: LoggerMock()
        )
        loadingViewModel = viewModel

        await viewModel.start()

        #expect(stateDuringDownload == .loading)
    }

    @Test func loadTrackTwiceSucceedsAndKeepsLoadedState() async {
        let (viewModel, _, _, _) = makeSUT()

        await viewModel.start()
        await viewModel.start()

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

        await viewModel.start()

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

        #expect(isError(viewModel.state))
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

        #expect(isError(viewModel.state))
    }

    @Test func playAfterLoadFailureDoesNotCallPlay() async {
        let (viewModel, audioMock, _, _) = makeSUT(downloadError: TestError.failed)

        await viewModel.start()
        viewModel.play()

        #expect(audioMock.playCallCount == 0)
    }

    @Test func playAfterLoadFailureKeepsErrorState() async {
        let (viewModel, _, _, _) = makeSUT(downloadError: TestError.failed)

        await viewModel.start()
        viewModel.play()

        #expect(isError(viewModel.state))
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
        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: dataLoader,
            audioPlayerAPI: audioMock,
            timerAPI: TimerAPIMock(),
            nextTrackListener: NextTrackListenerMock([makeTrack()]),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: FindNextTrackSenderMock(),
            logger: LoggerMock()
        )
        loadingViewModel = viewModel

        await viewModel.start()

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

    @Test func didFinishPlayingSendsFindNextTrackRequest() async {
        let audioMock = AudioPlayerAPIMock()
        let findNextTrackSender = FindNextTrackSenderMock()
        let (viewModel, _, _, _) = makeSUT(
            audioPlayerAPI: audioMock,
            findNextTrackSender: findNextTrackSender
        )
        await viewModel.start()
        viewModel.play()

        audioMock.simulateFinishPlaying()

        #expect(findNextTrackSender.sendCallCount == 1)
    }

    @Test func didNotFinishPlayingDoesNotSendFindNextTrackRequest() async {
        let findNextTrackSender = FindNextTrackSenderMock()
        let (viewModel, _, _, _) = makeSUT(findNextTrackSender: findNextTrackSender)

        await viewModel.start()
        viewModel.play()

        #expect(findNextTrackSender.sendCallCount == 0)
    }

    // MARK: - Next track action

    @Test func nextTrackReplacesThePreviousOne() async {
        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: NetworkDataLoaderMock { _ in Data([1, 2, 3]) },
            audioPlayerAPI: AudioPlayerAPIMock(),
            timerAPI: TimerAPIMock(),
            nextTrackListener: NextTrackListenerMock([
                Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
                Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
            ]),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: FindNextTrackSenderMock(),
            logger: LoggerMock()
        )

        await viewModel.start()

        #expect(viewModel.track?.trackId == 2)
    }

    @Test func nextTrackIsLoaded() async {
        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: NetworkDataLoaderMock { _ in Data([1, 2, 3]) },
            audioPlayerAPI: AudioPlayerAPIMock(),
            timerAPI: TimerAPIMock(),
            nextTrackListener: NextTrackListenerMock([
                Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
                Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
            ]),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: FindNextTrackSenderMock(),
            logger: LoggerMock()
        )

        await viewModel.start()

        #expect(viewModel.state == .loaded)
    }

    @Test func nextTrackResetsProgress() async {
        let audioMock = AudioPlayerAPIMock()
        audioMock.currentTime = 30
        audioMock.duration = 100
        let timerMock = TimerAPIMock()
        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: NetworkDataLoaderMock { _ in Data([1, 2, 3]) },
            audioPlayerAPI: audioMock,
            timerAPI: timerMock,
            nextTrackListener: NextTrackListenerMock([
                Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01")
            ]),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: FindNextTrackSenderMock(),
            logger: LoggerMock()
        )
        await viewModel.start()
        viewModel.play()
        timerMock.fire()

        await viewModel.start()

        #expect(viewModel.progress == 0)
    }

    // MARK: - Auto play

    @Test func autoPlayTrackSetsPlayingState() async {
        let (viewModel, _, _, _) = makeSUT(autoPlay: true)

        await viewModel.start()

        #expect(viewModel.state == .playing)
    }

    @Test func autoPlayTrackCallsPlay() async {
        let (viewModel, audioMock, _, _) = makeSUT(autoPlay: true)

        await viewModel.start()

        #expect(audioMock.playCallCount == 1)
    }

    @Test func autoPlayTrackInitializesPlayerOnce() async {
        let (viewModel, audioMock, _, _) = makeSUT(autoPlay: true)

        await viewModel.start()

        #expect(audioMock.initializeCallCount == 1)
    }

    @Test func autoPlayTrackStartsProgressTimer() async {
        let (viewModel, _, timerMock, _) = makeSUT(autoPlay: true)

        await viewModel.start()

        #expect(timerMock.startCallCount == 1)
    }

    @Test func trackWithoutAutoPlayKeepsLoadedState() async {
        let (viewModel, _, _, _) = makeSUT(autoPlay: false)

        await viewModel.start()

        #expect(viewModel.state == .loaded)
    }

    @Test func trackWithoutAutoPlayDoesNotCallPlay() async {
        let (viewModel, audioMock, _, _) = makeSUT(autoPlay: false)

        await viewModel.start()

        #expect(audioMock.playCallCount == 0)
    }

    @Test func autoPlayAfterLoadFailureDoesNotCallPlay() async {
        let (viewModel, audioMock, _, _) = makeSUT(downloadError: TestError.failed, autoPlay: true)

        await viewModel.start()

        #expect(audioMock.playCallCount == 0)
    }

    @Test func autoPlayAfterLoadFailureKeepsErrorState() async {
        let (viewModel, _, _, _) = makeSUT(downloadError: TestError.failed, autoPlay: true)

        await viewModel.start()

        #expect(isError(viewModel.state))
    }

    @Test func autoPlayWithInvalidURLDoesNotCallPlay() async {
        let (viewModel, audioMock, _, _) = makeSUT(url: "", autoPlay: true)

        await viewModel.start()

        #expect(audioMock.playCallCount == 0)
    }

    @Test func autoPlayAppliesOnlyToTheTracksThatAskForIt() async {
        let audioMock = AudioPlayerAPIMock()
        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: NetworkDataLoaderMock { _ in Data([1, 2, 3]) },
            audioPlayerAPI: audioMock,
            timerAPI: TimerAPIMock(),
            nextTrackListener: NextTrackListenerMock([
                TrackData(
                    track: Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
                    autoPlay: true
                ),
                TrackData(
                    track: Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02"),
                    autoPlay: false
                )
            ]),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: FindNextTrackSenderMock(),
            logger: LoggerMock()
        )

        await viewModel.start()

        #expect(audioMock.playCallCount == 1)
    }

    @Test func autoPlayOfTheSecondTrackInitializesThePlayerAgain() async {
        let audioMock = AudioPlayerAPIMock()
        let viewModel = AudioPlayerViewModelImpl(
            dataLoader: NetworkDataLoaderMock { _ in Data([1, 2, 3]) },
            audioPlayerAPI: audioMock,
            timerAPI: TimerAPIMock(),
            nextTrackListener: NextTrackListenerMock([
                Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
                Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
            ], autoPlay: true),
            selectTrackListener: SelectTrackListenerMock(),
            findNextTrackSender: FindNextTrackSenderMock(),
            logger: LoggerMock()
        )

        await viewModel.start()

        #expect(audioMock.initializeCallCount == 2)
    }
}
