@testable import Musician2
import Foundation
import Testing
import UDF

@MainActor
struct AlbumDetailsReducerTests {

    private let albumTracks = [
        Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
        Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
    ]

    // MARK: - The shown album

    @Test func theTappedAlbumIsShown() async {
        let store = makeStore()

        await store.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        #expect(store.state.album == makeAlbum())
    }

    @Test func noAlbumIsShownUntilOneIsTapped() {
        #expect(makeStore().state.album == nil)
    }

    // MARK: - The current track

    @Test func theCurrentTrackIsNilWhenNothingHasBeenSelected() async {
        let store = makeStore()

        await store.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        #expect(store.state.currentTrack == nil)
    }

    @Test func theTrackReceivedFromTheNextTrackActionBecomesTheCurrentOne() async {
        let store = makeStore()
        await store.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        await store.dispatchAndSettle(AppAction.nextTrack(TrackData(track: albumTracks[1], autoPlay: false)))

        #expect(store.state.currentTrack == albumTracks[1])
    }

    /// The album details feature reads the current track from the common state,
    /// so a track selected before the album has been opened is the current one as well.
    @Test func theTrackSelectedBeforeTheAlbumIsShownIsTheCurrentOne() async {
        let store = makeStore()
        await store.dispatchAndSettle(AppAction.nextTrack(TrackData(track: albumTracks[1], autoPlay: false)))

        await store.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        #expect(store.state.currentTrack == albumTracks[1])
    }

    // MARK: - The track selection by the user

    /// The tapped track becomes the current one only when the selection comes back
    /// from the track selector through the NextTrack action.
    @Test func theTappedTrackDoesNotBecomeTheCurrentOneRightAway() async {
        let store = makeStore()
        await store.dispatchAndSettle(AlbumListAction.albumTapped(makeAlbum()))

        await store.dispatchAndSettle(AlbumDetailsAction.trackTapped(albumTracks[0], makeAlbum()))

        #expect(store.state.currentTrack == nil)
    }

    // MARK: - Helpers

    private func makeStore() -> Store<AlbumDetailsState> {
        Store(state: AlbumDetailsState(), reducer: AlbumDetailsReducer().reduce)
    }

    private func makeAlbum() -> Album {
        Album(
            albumId: 1,
            albumName: "Test Album",
            albumYear: 2026,
            albumCover: "https://example.com/cover.png",
            albumMedianColor: "#2E4272",
            tracks: albumTracks
        )
    }
}
