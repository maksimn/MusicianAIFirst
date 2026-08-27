# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Musician2: a SwiftUI iOS music player app. It loads an album/track list from a remote JSON
endpoint (`http://maksimn.github.io/albums.json`), caches it locally, and lets the user browse
albums, pick tracks, and play them with a mini audio player.

## Build & test

There is no CocoaPods/SPM-local setup beyond the one remote package (`UDF`, resolved from
`https://github.com/inDriver/UDF`). Open `Musician2.xcodeproj` in Xcode, or use `xcodebuild`:

```bash
# Build
xcodebuild -project Musician2.xcodeproj -scheme Musician2 -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests
xcodebuild -project Musician2.xcodeproj -scheme Musician2 -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run a single test (Swift Testing syntax, not XCTest)
xcodebuild -project Musician2.xcodeproj -scheme Musician2 -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:Musician2Tests/AlbumListReducerTests/loadAlbumsStartsTheLoading
```

Tests use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`), not XCTest.
Reducer tests are `@MainActor struct`s; shared mocks live in `Musician2Tests/Mocks.swift`
(`AlbumRepositoryMock`, `NetworkDataLoaderMock`, `AudioPlayerAPIMock`, `TimerAPIMock`,
`ActionDispatcherMock`). `ActionDispatcherMock.nextDispatchedAction()` lets async side effects be
awaited deterministically instead of polled/slept.

## Architecture: UDF (unidirectional data flow)

The app follows a Redux-like UDF architecture, using the `UDF` package (state container +
reducer/side-effect plumbing: `Store`, `Action`, `SideEffectProtocol`, `ActionDispatcher`).
This is a from-scratch rewrite of an earlier Clean-MVVM version of the same app — the UDF
rewrite is the current architecture; don't reintroduce MVVM/ViewModel patterns.

**One `Store<AppState>`** is built once in `App/AppBuilder.swift` and lives for the app's
lifetime (`Musician2App.swift`). `AppState` (`App/AppState.swift`) is a flat struct composing
each feature's own state:

```swift
struct AppState {
    var albumList = AlbumListState()
    var albumDetails = AlbumDetailsState()
    var audioPlayer = AudioPlayerState()
    var trackSelector = TrackSelectorState()
}
```

`AppReducer` (`App/AppReducer.swift`) is the single reducer registered with the store. On every
dispatched action it runs **every** feature reducer against the whole action, each mutating only
its own slice of `AppState`, and combines any returned side effects via `CombineSideEffect`.

### Cross-feature communication: shared action vocabulary, not shared state

Features never read each other's state directly. Instead:

- **Every feature reducer sees every action.** A feature reacts to actions from *other*
  features by switch/casting on their action enum, e.g. `AlbumDetailsReducer` reacts to
  `AlbumListAction.albumTapped` and `TrackSelectorAction.nextTrack`; `AudioPlayerReducer` reacts
  to `TrackSelectorAction.nextTrack` and `AlbumDetailsAction.trackTapped`; `TrackSelectorReducer`
  reacts to `AlbumListAction`, `AudioPlayerAction`, and `AlbumDetailsAction`.
- **Every action belongs to the feature that announces it** — there is no app-wide action enum.
  A feature announces something to the others through its own `...Action` enum, dispatched via
  `ActionSideEffect` (`UDF/ActionSideEffect.swift`); `TrackSelectorAction.nextTrack(TrackData)`
  is the one action several features listen to.
- Some "features" are pure logic with no UI at all — **`TrackSelector`** has a reducer/state but
  no view; it just listens to album-loaded/track-tapped/playback-finished actions and decides
  which track plays next, announcing it via `TrackSelectorAction.nextTrack`.

### Per-feature file layout

Each feature under `Musician2/<FeatureName>/` follows the same shape (not every feature has
every piece — `TrackSelector` has no UI, `AlbumList` additionally owns a `Repository/`):

```
<FeatureName>/
  <FeatureName>Feature.swift       # SwiftUI View: owns/scopes the Store, wires it into ObservableStore, renders the *View
  UDF/
    <FeatureName>Action.swift      # enum ...: Action — this feature's own actions
    <FeatureName>State.swift       # struct ...State — this feature's slice of AppState
    <FeatureName>Reducer.swift     # struct ...Reducer — reduce(_:_:) -> SideEffect; reacts to own + other features' actions
    <FeatureName>SideEffects.swift # SideEffectProtocol structs doing the actual async/IO work
  Views/ or View/
    <FeatureName>View.swift        # dumb-ish SwiftUI view driven by ObservableStore<...State>
```

`<FeatureName>Feature.swift` is the seam between the app-wide `Store<AppState>` and a feature:
it calls `store.scope(\.someFeatureState)` to get a `Store<FeatureState>`, wraps it in an
`ObservableStore` (`UDF/ObservableStore.swift`, `@Observable`) so SwiftUI observes state changes,
and hands that down to the plain `...View`. Views dispatch actions with
`store.dispatch(SomeAction.foo(...))`; they never touch the reducer or side effects directly.

Reducers are pure: `reduce(_ state: inout State, _ action: Action) -> SideEffect`. All IO
(networking, caching, the audio player, timers) happens in `SideEffectProtocol` structs returned
by the reducer and executed later by the store on a separate effect queue — reducers themselves
must stay side-effect-free. Side effects report back only by dispatching further actions.

### Feature responsibilities

- **AlbumList** — fetches albums via `AlbumRepository` (network + `FileCacheService` disk
  cache fallback in `Library/Caches`), sorts them newest year first, shows
  loading/error/empty/list states.
- **AlbumDetails** — shows the tapped album's tracks and highlights the currently playing one;
  gets its data purely from `AlbumListAction.albumTapped` / `TrackSelectorAction.nextTrack`, holds no
  fetching logic of its own.
- **AudioPlayer** — downloads a track's audio data, drives `AudioPlayerAPI` (AVFoundation
  wrapper, decorated with `LoggingAudioPlayerAPI`) and `TimerAPI` for progress ticks; its
  `AudioPlayerDelegateAdapter` turns the AV delegate callback (`didFinishPlaying`) into
  `AudioPlayerAction.playbackFinished`.
- **TrackSelector** — no UI; owns "what track is queued/next" logic (initial track = first
  track of the newest album; next track = next in album, wrapping to the first; user tap
  overrides the queue).

### Shared pieces

- `Musician2/DataClass/` — `Album`, `Track` (plain `Decodable`/`Hashable`/`Identifiable`
  structs matching the JSON schema), plus `TrackData`/`TrackSelection` DTOs used in actions.
- `Musician2/Core/` — cross-cutting utilities: `Networking/Networking.swift`
  (`NetworkDataLoader` protocol + `URLSessionNetworkDataLoader`, injected into repositories/side
  effects for testability), `WithError` (type-erased `Equatable` error wrapper, needed because
  plain `Error` isn't `Equatable` but reducer state/actions need to be),
  `Logger/` (protocol + impl + decorators like `LoggingAudioPlayerAPI`/`LoggingTimerAPI`),
  `isDevelopment()`, `Color.swift` (hex-string ↔ `Color` helpers used for album accent colors).
- `Musician2/Shared/` — `AlbumRowView` and `Album+Colors` reused between `AlbumList` and
  `AlbumDetails`.

### Debugging

`AppBuilder` wires a debug-only action logger (`store.onAction`) that `debugPrint`s every
dispatched action except the noisy `AudioPlayerAction.progress` ticks — check there when adding
new actions you don't want spamming the console.

## Conventions worth preserving

- New cross-feature events go through the `Action` enum of the feature that announces them —
  the one that owns the decision — even when several features react to it (see
  `TrackSelectorAction.nextTrack`); don't add an app-wide action enum for them.
- Reducers must stay pure; put any new IO in a `SideEffectProtocol` struct in that feature's
  `...SideEffects.swift`, not inline in the reducer.
- Match the existing doc-comment style: a `///` summary sentence on every type/enum case
  explaining *why*, not just *what*.
