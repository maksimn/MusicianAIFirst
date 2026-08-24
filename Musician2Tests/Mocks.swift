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

/// Records what has been logged and lets a test wait for a message. The listeners run in tasks
/// of their own, so waiting for what they log is the way to tell that they have handled a value.
final class LoggerMock: Logger {

    private(set) var messages: [String] = []

    private let logged: AsyncStream<String>

    private let continuation: AsyncStream<String>.Continuation

    init() {
        (logged, continuation) = AsyncStream.makeStream()
    }

    func log(_ message: String, level: LogLevel) {
        messages.append(message)
        continuation.yield(message)
    }

    /// Returns as soon as a message containing the given text has been logged, whether it has
    /// been logged before or after the call.
    func waitForMessage(containing text: String) async {
        guard !messages.contains(where: { $0.contains(text) }) else { return }

        var iterator = logged.makeAsyncIterator()

        while let message = await iterator.next() {
            if message.contains(text) {
                return
            }
        }
    }
}

final class NextTrackListenerMock: NextTrackListener {

    private let trackDataList: [TrackData]

    init(_ trackDataList: [TrackData]) {
        self.trackDataList = trackDataList
    }

    init(_ tracks: [Track], album: Album? = nil, autoPlay: Bool = false) {
        self.trackDataList = tracks.map { TrackData(track: $0, album: album, autoPlay: autoPlay) }
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

final class FindNextTrackSenderMock: FindNextTrackSender {

    private(set) var sendCallCount = 0

    func send() {
        sendCallCount += 1
    }
}

final class CurrentTrackProviderMock: CurrentTrackProvider {

    var currentTrack: Track?

    init(_ currentTrack: Track? = nil) {
        self.currentTrack = currentTrack
    }
}

/// A listener whose stream is driven by the test: the values are yielded on demand
/// and the stream stays open until the mock is released.
final class AlbumListLoadedListenerMock: AlbumListLoadedListener {

    let albumList: AsyncStream<[Album]>

    private let continuation: AsyncStream<[Album]>.Continuation

    init() {
        (albumList, continuation) = AsyncStream.makeStream()
    }

    func send(_ albums: [Album]) {
        continuation.yield(albums)
    }
}

final class FindNextTrackListenerMock: FindNextTrackListener {

    let notification: AsyncStream<Void>

    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (notification, continuation) = AsyncStream.makeStream()
    }

    func send() {
        continuation.yield(())
    }
}

/// Records what its owner sends as a stream, so a test may await the sent values in order.
final class NextTrackSenderMock: NextTrackSender {

    let sentTrackData: AsyncStream<TrackData>

    private let continuation: AsyncStream<TrackData>.Continuation

    init() {
        (sentTrackData, continuation) = AsyncStream.makeStream()
    }

    func send(_ trackData: TrackData) {
        continuation.yield(trackData)
    }
}
