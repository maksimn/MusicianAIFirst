@testable import Musician2
import Foundation
import Testing

@MainActor
struct AlbumListReducerTests {

    private let repository = AlbumRepositoryMock()
    private let sender = AlbumListLoadedSenderMock()

    private var reducer: AlbumListReducer {
        AlbumListReducer(repository: repository, albumListLoadedSender: sender)
    }

    // MARK: - Reducer

    @Test func loadAlbumsStartsTheLoading() {
        var state = AlbumListState(error: TestError.some)

        let sideEffect = reducer.reduce(&state, AlbumListAction.loadAlbums)

        #expect(state.isLoading)
        #expect(state.error == nil)
        #expect(sideEffect is LoadAlbumsSideEffect)
    }

    @Test func loadAlbumsIsIgnoredWhenTheAlbumsAreAlreadyLoaded() {
        var state = AlbumListState(albums: [album(1)])

        let sideEffect = reducer.reduce(&state, AlbumListAction.loadAlbums)

        #expect(!state.isLoading)
        #expect(sideEffect == nil)
    }

    @Test func loadAlbumsIsIgnoredWhileTheLoadingIsInProgress() {
        var state = AlbumListState(isLoading: true)

        let sideEffect = reducer.reduce(&state, AlbumListAction.loadAlbums)

        #expect(sideEffect == nil)
    }

    @Test func loadedAlbumsAreReversedAndSent() throws {
        var state = AlbumListState(isLoading: true)

        let sideEffect = reducer.reduce(&state, AlbumListAction.albumsLoaded([album(1), album(2)]))

        #expect(!state.isLoading)
        #expect(state.albums.map(\.id) == [2, 1])

        let loadedSideEffect = try #require(sideEffect as? AlbumListLoadedSideEffect)

        #expect(loadedSideEffect.albums.map(\.id) == [2, 1])
    }

    @Test func loadedAlbumsKeepTheirOrderWhenTheReducerIsNotReversed() {
        var state = AlbumListState()
        let reducer = AlbumListReducer(repository: repository, albumListLoadedSender: sender, isReversed: false)

        _ = reducer.reduce(&state, AlbumListAction.albumsLoaded([album(1), album(2)]))

        #expect(state.albums.map(\.id) == [1, 2])
    }

    @Test func anEmptyAlbumListIsNotSent() {
        var state = AlbumListState()

        let sideEffect = reducer.reduce(&state, AlbumListAction.albumsLoaded([]))

        #expect(sideEffect == nil)
    }

    @Test func failedLoadingFallsBackToTheCache() {
        var state = AlbumListState(isLoading: true)

        let sideEffect = reducer.reduce(&state, AlbumListAction.loadingFailed(TestError.some))

        #expect(!state.isLoading)
        #expect(state.error != nil)
        #expect(sideEffect is LoadCachedAlbumsSideEffect)
    }

    @Test func failedLoadingKeepsTheAlreadyShownAlbums() {
        var state = AlbumListState(albums: [album(1)], isLoading: true)

        let sideEffect = reducer.reduce(&state, AlbumListAction.loadingFailed(TestError.some))

        #expect(state.albums.map(\.id) == [1])
        #expect(state.error != nil)
        #expect(sideEffect == nil)
    }

    @Test func cachedAlbumsAreShownAndSent() {
        var state = AlbumListState(error: TestError.some)

        let sideEffect = reducer.reduce(&state, AlbumListAction.cachedAlbumsLoaded([album(1), album(2)]))

        #expect(state.albums.map(\.id) == [2, 1])
        #expect(sideEffect is AlbumListLoadedSideEffect)
    }

    // MARK: - Side effects

    @Test func loadAlbumsSideEffectDispatchesTheFetchedAlbums() async throws {
        let dispatcher = ActionDispatcherMock()

        repository.fetchResult = .success([album(1)])
        LoadAlbumsSideEffect(repository: repository).execute(with: dispatcher)

        let action = try #require(await dispatcher.nextDispatchedAction() as? AlbumListAction)

        guard case .albumsLoaded(let albums) = action else {
            Issue.record("Unexpected action: \(action)")
            return
        }

        #expect(albums.map(\.id) == [1])
    }

    @Test func loadAlbumsSideEffectDispatchesTheFetchingError() async throws {
        let dispatcher = ActionDispatcherMock()

        repository.fetchResult = .failure(TestError.some)
        LoadAlbumsSideEffect(repository: repository).execute(with: dispatcher)

        let action = try #require(await dispatcher.nextDispatchedAction() as? AlbumListAction)

        guard case .loadingFailed = action else {
            Issue.record("Unexpected action: \(action)")
            return
        }
    }

    @Test func loadCachedAlbumsSideEffectDispatchesTheCachedAlbums() throws {
        let dispatcher = ActionDispatcherMock()

        repository.cachedAlbums = [album(1)]
        LoadCachedAlbumsSideEffect(repository: repository).execute(with: dispatcher)

        let action = try #require(dispatcher.dispatchedActions.first as? AlbumListAction)

        guard case .cachedAlbumsLoaded(let albums) = action else {
            Issue.record("Unexpected action: \(action)")
            return
        }

        #expect(albums.map(\.id) == [1])
    }

    // MARK: - The store

    @Test func theStoreNotifiesTheSubscribersAndRunsTheSideEffects() {
        let store = Store(initialState: AlbumListState(), reducer: reducer.reduce)
        var states: [AlbumListState] = []

        let subscription = store.subscribe { states.append($0) }

        store.dispatch(AlbumListAction.albumsLoaded([album(1), album(2)]))

        #expect(states.count == 2)
        #expect(states.first?.albums.isEmpty == true)
        #expect(states.last?.albums.map(\.id) == [2, 1])
        #expect(sender.sentAlbumLists.map { $0.map(\.id) } == [[2, 1]])

        subscription.cancel()

        store.dispatch(AlbumListAction.albumsLoaded([album(3)]))

        #expect(states.count == 2)
    }

    // MARK: - Helpers

    private func album(_ id: Int) -> Album {
        Album(
            albumId: id,
            albumName: "Album \(id)",
            albumYear: 2026,
            albumCover: "",
            albumMedianColor: "#000000",
            tracks: []
        )
    }
}

private enum TestError: Error {
    case some
}
