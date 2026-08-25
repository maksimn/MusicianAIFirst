@testable import Musician2
import Foundation
import Testing
import UDF

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

final class AlbumRepositoryMock: AlbumRepository {

    var fetchResult: Result<[Album], Error> = .success([])

    var cachedAlbums: [Album] = []

    private(set) var fetchCallCount = 0
    private(set) var loadCachedCallCount = 0

    func fetchAlbums() async throws -> [Album] {
        fetchCallCount += 1

        return try fetchResult.get()
    }

    func loadCachedAlbums() -> [Album] {
        loadCachedCallCount += 1

        return cachedAlbums
    }
}

final class ActionDispatcherMock: ActionDispatcher {

    private(set) var dispatchedActions: [Action] = []

    private let continuation: AsyncStream<Action>.Continuation

    private var iterator: AsyncStream<Action>.AsyncIterator

    init() {
        let (stream, continuation) = AsyncStream<Action>.makeStream()

        self.continuation = continuation
        self.iterator = stream.makeAsyncIterator()
    }

    func dispatch(_ action: Action) {
        dispatchedActions.append(action)
        continuation.yield(action)
    }

    /// Waits for the next dispatched action, so the asynchronous side effects are tested deterministically.
    func nextDispatchedAction() async -> Action? {
        await iterator.next()
    }
}

/// Executes the side effect and returns the actions it has dispatched right away.
@MainActor
func dispatchedActions(of sideEffect: SideEffect) -> [Action] {
    let dispatcher = ActionDispatcherMock()

    sideEffect?.execute(with: dispatcher)

    return dispatcher.dispatchedActions
}
