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

// MARK: - Waiting for the store

extension Store {

    /// Dispatches the action and waits until the store has reduced it together with every action
    /// the side effects dispatch in answer to it.
    ///
    /// The store reduces the actions on a queue of its own, so nothing has happened yet
    /// by the time `dispatch` returns.
    @MainActor
    func dispatchAndSettle(_ action: Action, sourceLocation: SourceLocation = #_sourceLocation) async {
        dispatch(action)

        await settled(sourceLocation: sourceLocation)
    }

    /// Waits until the store has reduced everything that has been dispatched to it,
    /// so a test may assert that an action has changed nothing.
    @MainActor
    func settled(sourceLocation: SourceLocation = #_sourceLocation) async {
        let recorder = ActionRecorder()
        let disposer = Disposer()

        // Nothing the store has already reduced can be reported before the observer is subscribed:
        // the store reports the actions on the main queue, which this test occupies until it awaits.
        onAction { _, action in recorder.record(action) }.dispose(on: disposer)

        for _ in 0..<50 {
            recorder.startRoundTrip()
            dispatch(SettleAction())

            // The queue of the store is serial, so by the time it has reduced the settling action
            // it has reduced everything dispatched before it.
            await poll("the store to reduce the settling action", sourceLocation: sourceLocation) {
                recorder.hasReducedSettleAction
            }

            // A side effect runs on another queue, so the action it dispatches reaches the store
            // some time after the action that has caused it has been reduced.
            try? await Task.sleep(for: quietTimeUntilSettled)

            if recorder.otherActionCount == 0 { return }
        }

        Issue.record("The store keeps dispatching the actions and never settles.", sourceLocation: sourceLocation)
    }

    /// Waits until the state of the store satisfies the condition.
    ///
    /// This is how a test waits for a side effect that works asynchronously by itself,
    /// such as the downloading of a track.
    @MainActor
    func waitUntil(
        _ description: String,
        _ condition: (State) -> Bool,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        await poll(description, sourceLocation: sourceLocation) { condition(state) }
    }
}

/// The time a side effect is given to reach the queue of the store with the action it dispatches.
/// The store that has stayed quiet for that long is considered settled.
private let quietTimeUntilSettled = Duration.milliseconds(25)

/// An action that changes nothing: it is only dispatched to find out whether the store
/// has finished the work of the actions dispatched before it.
private struct SettleAction: Action { }

/// Remembers the actions the store reduces during a round trip of the settling action.
private final class ActionRecorder {

    private(set) var otherActionCount = 0

    private(set) var hasReducedSettleAction = false

    func record(_ action: Action) {
        if action is SettleAction {
            hasReducedSettleAction = true
        } else {
            otherActionCount += 1
        }
    }

    func startRoundTrip() {
        otherActionCount = 0
        hasReducedSettleAction = false
    }
}

/// Waits for the condition to hold, giving the queues of the store a chance to run.
@MainActor
func poll(
    _ description: String,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: () -> Bool
) async {
    for _ in 0..<1000 {
        if condition() { return }

        try? await Task.sleep(for: .milliseconds(1))
    }

    Issue.record("Timed out waiting for \(description).", sourceLocation: sourceLocation)
}
