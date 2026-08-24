@testable import Musician2
import Foundation

final class AudioPlayerAPIMock: AudioPlayerAPI {

    weak var delegate: AudioPlayerDelegate?

    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 100
    var initializeError: Error?

    private(set) var initializeCallCount = 0
    private(set) var playCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var lastInitializedData: Data?

    func initialize(with data: Data) throws {
        initializeCallCount += 1
        lastInitializedData = data
        if let initializeError {
            throw initializeError
        }
    }

    func play() {
        playCallCount += 1
    }

    func pause() {
        pauseCallCount += 1
    }

    func simulateFinishPlaying() {
        delegate?.didFinishPlaying()
    }
}

final class NetworkDataLoaderMock: NetworkDataLoader {

    private(set) var downloadMock: (URL) async throws -> Data

    init(_ downloadMock: @escaping (URL) async throws -> Data) {
        self.downloadMock = downloadMock
    }

    func download(_ url: URL) async throws -> Data {
        try await downloadMock(url)
    }
}

final class TimerAPIMock: TimerAPI {

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private var block: (@MainActor () -> Void)?

    func start(block: @escaping @MainActor () -> Void) {
        startCallCount += 1
        self.block = block
    }

    func stop() {
        stopCallCount += 1
        block = nil
    }

    @MainActor
    func fire() {
        block?()
    }
}

final class LoggerMock: Logger {
    func log(_ message: String, level: LogLevel) {
    }
}

final class NextTrackListenerMock: NextTrackListener {

    private let trackDataList: [TrackData]

    init(_ trackDataList: [TrackData]) {
        self.trackDataList = trackDataList
    }

    init(_ tracks: [Track], autoPlay: Bool = false) {
        self.trackDataList = tracks.map { TrackData(track: $0, autoPlay: autoPlay) }
    }

    /// The stream finishes right after the tracks are yielded, so listening to it completes deterministically.
    var trackData: AsyncStream<TrackData> {
        AsyncStream { continuation in
            for trackData in trackDataList {
                continuation.yield(trackData)
            }
            continuation.finish()
        }
    }
}

final class SelectTrackListenerMock: SelectTrackListener {

    private let selections: [TrackSelection]

    init(_ selections: [TrackSelection] = []) {
        self.selections = selections
    }

    /// The stream finishes right after the selections are yielded, so listening to it completes deterministically.
    var selection: AsyncStream<TrackSelection> {
        AsyncStream { continuation in
            for selection in selections {
                continuation.yield(selection)
            }
            continuation.finish()
        }
    }
}

final class FindNextTrackSenderMock: FindNextTrackSender {

    private(set) var sendCallCount = 0

    func send() {
        sendCallCount += 1
    }
}

final class SelectTrackSenderMock: SelectTrackSender {

    private(set) var sentSelections: [TrackSelection] = []

    func send(_ selection: TrackSelection) {
        sentSelections.append(selection)
    }
}

final class CurrentTrackProviderMock: CurrentTrackProvider {

    var currentTrack: Track?

    init(_ currentTrack: Track? = nil) {
        self.currentTrack = currentTrack
    }
}
