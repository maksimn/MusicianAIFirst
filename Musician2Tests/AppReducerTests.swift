@testable import Musician2
import Foundation
import Testing
import UDF

@MainActor
struct AppReducerTests {

    private let repository = AlbumRepositoryMock()

    private let tracks = [
        Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
        Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
    ]

    // MARK: - The common store

    /// The features share the actions, not the state: the same action changes the parts
    /// of the state that belong to different features.
    @Test func oneActionReachesEveryFeatureThatIsInterestedInIt() async {
        let store = makeStore()

        await store.dispatchAndSettle(AppAction.nextTrack(TrackData(track: tracks[0], autoPlay: false)))

        #expect(store.state.audioPlayer.track == tracks[0])
        #expect(store.state.albumDetails.currentTrack == tracks[0])
    }

    @Test func aFeatureSeesOnlyItsOwnPartOfTheState() async {
        let store = makeStore()
        let albumDetails = store.scope(\.albumDetails)
        let audioPlayer = store.scope(\.audioPlayer)

        await store.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        #expect(albumDetails.state.album == makeAlbum())
        #expect(audioPlayer.state.track == nil)
    }

    @Test func aFeatureDispatchesTheActionsOfTheOtherFeaturesThroughItsOwnStore() async {
        let store = makeStore()
        let albumDetails = store.scope(\.albumDetails)

        await albumDetails.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        #expect(store.state.albumDetails.album == makeAlbum())
    }

    // MARK: - The chains of the actions

    /// The loaded album list makes the track selector choose the initial track,
    /// which the audio player and the album details learn from the NextTrack action.
    @Test func theLoadedAlbumListStartsTheTrackSelection() async {
        let store = makeStore()

        await store.dispatchAndSettle(AlbumListAction.albumsLoaded([makeAlbum()]))

        #expect(store.state.trackSelector.selectedTrack == tracks[0])
        #expect(store.state.audioPlayer.track == tracks[0])
        #expect(store.state.albumDetails.currentTrack == tracks[0])
    }

    @Test func theTrackTappedInTheAlbumDetailsIsSelectedAndPlayed() async {
        let store = makeStore()
        await store.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        await store.dispatchAndSettle(AlbumDetailsAction.trackTapped(tracks[1], makeAlbum()))

        #expect(store.state.trackSelector.selectedTrack == tracks[1])
        #expect(store.state.audioPlayer.track == tracks[1])
        #expect(store.state.albumDetails.currentTrack == tracks[1])
    }

    @Test func theFinishedPlaybackMakesTheTrackSelectorChooseTheNextTrack() async {
        let store = makeStore()
        await store.dispatchAndSettle(AlbumListAction.albumsLoaded([makeAlbum()]))

        await store.dispatchAndSettle(AudioPlayerAction.playbackFinished)

        #expect(store.state.trackSelector.selectedTrack == tracks[1])
        #expect(store.state.audioPlayer.track == tracks[1])
    }

    // MARK: - Helpers

    private func makeStore() -> Store<AppState> {
        let reducer = AppReducer(
            albumListReducer: AlbumListReducer(repository: repository),
            albumDetailsReducer: AlbumDetailsReducer(),
            audioPlayerReducer: AudioPlayerReducer(
                dataLoader: NetworkDataLoaderMock { _ in Data([1, 2, 3]) },
                audioPlayerAPI: AudioPlayerAPIMock(),
                timerAPI: TimerAPIMock()
            ),
            trackSelectorReducer: TrackSelectorReducer()
        )

        return Store(state: AppState(), reducer: reducer.reduce)
    }

    private func makeAlbum() -> Album {
        Album(
            albumId: 1,
            albumName: "Test Album",
            albumYear: 2026,
            albumCover: "",
            albumMedianColor: "#2E4272",
            tracks: tracks
        )
    }
}
