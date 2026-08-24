@testable import Musician2
import Foundation
import Testing

@MainActor
struct AlbumDetailsViewModelTests {

    private let albumTracks = [
        Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
        Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
    ]

    private let foreignTrack = Track(
        trackId: 3, name: "Foreign", url: "https://example.com/3.mp3", duration: "3:03"
    )

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

    private func makeSUT(
        currentTrack: Track? = nil,
        streamedTracks: [Track] = [],
        selectTrackSender: SelectTrackSender = SelectTrackSenderMock()
    ) -> AlbumDetailsViewModelImpl {
        AlbumDetailsViewModelImpl(
            album: makeAlbum(),
            nextTrackListener: NextTrackListenerMock(streamedTracks),
            currentTrackProvider: CurrentTrackProviderMock(currentTrack),
            selectTrackSender: selectTrackSender
        )
    }

    @Test
    func selectedTrackIsNilWhenNothingHasBeenSelected() async {
        let viewModel = makeSUT()

        await viewModel.start()

        #expect(viewModel.state.selectedTrack == nil)
    }

    @Test
    func trackSelectedBeforeStartIsShownAsSelected() async {
        let viewModel = makeSUT(currentTrack: albumTracks[1])

        await viewModel.start()

        #expect(viewModel.state.selectedTrack == albumTracks[1])
    }

    @Test
    func trackReceivedFromTheNextTrackStreamIsShownAsSelected() async {
        let viewModel = makeSUT(streamedTracks: [albumTracks[0], albumTracks[1]])

        await viewModel.start()

        #expect(viewModel.state.selectedTrack == albumTracks[1])
    }

    @Test
    func trackOfAnotherAlbumIsNotShownAsSelected() async {
        let viewModel = makeSUT(currentTrack: albumTracks[0], streamedTracks: [foreignTrack])

        await viewModel.start()

        #expect(viewModel.state.selectedTrack == nil)
    }
}
