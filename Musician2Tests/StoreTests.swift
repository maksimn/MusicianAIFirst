@testable import Musician2
import Foundation
import Testing
import UDF

/// The store itself belongs to the UDF library: these are the tests of what the application
/// adds to it — the side effect that dispatches an action and the facade the SwiftUI views work with.
@MainActor
struct StoreTests {

    // MARK: - The side effect that dispatches an action

    @Test func theActionSideEffectDispatchesItsAction() throws {
        let dispatcher = ActionDispatcherMock()

        ActionSideEffect(TestAction.rename("renamed")).execute(with: dispatcher)

        let action = try #require(dispatcher.dispatchedActions.first as? TestAction)

        guard case .rename(let name) = action else {
            Issue.record("Unexpected action: \(action)")
            return
        }

        #expect(name == "renamed")
    }

    // MARK: - The observable store

    @Test func theObservableStoreRepublishesTheStateOfTheStoreItIsMadeOf() async {
        let store = makeStore()
        let observableStore = ObservableStore(store.scope(\.counter))

        store.dispatch(TestAction.increment)

        await poll("the observable store to republish the state") { observableStore.state.count == 1 }
    }

    @Test func theObservableStoreDispatchesTheActionsToTheStoreItIsMadeOf() async {
        let store = makeStore()
        let observableStore = ObservableStore(store.scope(\.counter))

        observableStore.dispatch(TestAction.rename("renamed"))

        await store.waitUntil("the dispatched action to reach the store") { $0.name == "renamed" }
    }

    // MARK: - The test state

    private struct CounterState {
        var count = 0
    }

    private struct TestState {
        var counter = CounterState()
        var name = ""
    }

    private enum TestAction: Action {
        case increment
        case rename(String)
    }

    private func makeStore() -> Store<TestState> {
        Store(state: TestState(), reducer: reducer)
    }

    private var reducer: SideEffectReducer<TestState> {
        { state, action in
            switch action as? TestAction {
            case .increment:
                state.counter.count += 1

            case .rename(let name):
                state.name = name

            case nil:
                break
            }

            return nil
        }
    }
}
