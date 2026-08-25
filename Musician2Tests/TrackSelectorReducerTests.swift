@testable import Musician2
import Foundation
import Testing
import UDF

@MainActor
struct TrackSelectorReducerTests {

    private let reducer = TrackSelectorReducer()

    private let tracks = [
        Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
        Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
    ]

    // MARK: - The initial track

    @Test func theInitialTrackIsTheFirstTrackOfTheNewestAlbum() throws {
        var state = TrackSelectorState()

        let sideEffect = reducer.reduce(&state, AlbumListAction.albumsLoaded([makeAlbum(), makeAlbum(id: 2)]))

        #expect(state.selectedTrack == tracks[0])
        #expect(state.selectedAlbum == makeAlbum(id: 2))

        let trackData = try #require(nextTrack(of: sideEffect))

        #expect(trackData == TrackData(track: tracks[0], autoPlay: false))
    }

    @Test func anEmptyAlbumListSelectsNothing() {
        var state = TrackSelectorState()

        let sideEffect = reducer.reduce(&state, AlbumListAction.albumsLoaded([]))

        #expect(state.selectedTrack == nil)
        #expect(sideEffect == nil)
    }

    @Test func anAlbumWithoutTracksSelectsNothing() {
        var state = TrackSelectorState()

        let sideEffect = reducer.reduce(&state, AlbumListAction.albumsLoaded([makeAlbum(tracks: [])]))

        #expect(state.selectedTrack == nil)
        #expect(sideEffect == nil)
    }

    // MARK: - The next track

    @Test func theNextTrackFollowsTheSelectedOneAndPlaysAutomatically() throws {
        var state = makeSelectedState(track: tracks[0])

        let sideEffect = reducer.reduce(&state, AudioPlayerAction.playbackFinished)

        #expect(state.selectedTrack == tracks[1])

        let trackData = try #require(nextTrack(of: sideEffect))

        #expect(trackData == TrackData(track: tracks[1], autoPlay: true))
    }

    @Test func theTrackAfterTheLastOneIsTheFirstTrackOfTheAlbum() {
        var state = makeSelectedState(track: tracks[1])

        _ = reducer.reduce(&state, AudioPlayerAction.playbackFinished)

        #expect(state.selectedTrack == tracks[0])
    }

    @Test func theFinishedPlaybackWithoutASelectedTrackIsIgnored() {
        var state = TrackSelectorState()

        let sideEffect = reducer.reduce(&state, AudioPlayerAction.playbackFinished)

        #expect(sideEffect == nil)
    }

    @Test func aSelectedTrackThatIsNotFoundInItsAlbumIsIgnored() {
        var state = TrackSelectorState(
            selectedAlbum: makeAlbum(tracks: [tracks[0]]),
            selectedTrack: tracks[1]
        )

        let sideEffect = reducer.reduce(&state, AudioPlayerAction.playbackFinished)

        #expect(sideEffect == nil)
    }

    // MARK: - The track picked by the user

    @Test func theTrackPickedByTheUserIsSelectedAndPlaysAutomatically() throws {
        var state = makeSelectedState(track: tracks[0])

        let sideEffect = reducer.reduce(&state, AlbumDetailsAction.trackTapped(tracks[1], makeAlbum()))

        #expect(state.selectedTrack == tracks[1])

        let trackData = try #require(nextTrack(of: sideEffect))

        #expect(trackData == TrackData(track: tracks[1], autoPlay: true))
    }

    @Test func theSameTrackOfAnotherAlbumIsSelectedAgain() {
        var state = makeSelectedState(track: tracks[0])

        let sideEffect = reducer.reduce(&state, AlbumDetailsAction.trackTapped(tracks[0], makeAlbum(id: 2)))

        #expect(state.selectedAlbum == makeAlbum(id: 2))
        #expect(sideEffect != nil)
    }

    // MARK: - Helpers

    private func nextTrack(of sideEffect: SideEffect) -> TrackData? {
        guard case .nextTrack(let trackData)? = dispatchedActions(of: sideEffect).first as? AppAction else {
            return nil
        }

        return trackData
    }

    private func makeSelectedState(track: Track) -> TrackSelectorState {
        TrackSelectorState(selectedAlbum: makeAlbum(), selectedTrack: track)
    }

    private func makeAlbum(id: Int = 1, tracks: [Track]? = nil) -> Album {
        Album(
            albumId: id,
            albumName: "Album \(id)",
            albumYear: 2000 + id,
            albumCover: "",
            albumMedianColor: "#2E4272",
            tracks: tracks ?? self.tracks
        )
    }
}
