@testable import Musician2
import Foundation
import Testing

@MainActor
struct TrackSelectorTests {

    private let firstAlbum = Album(
        albumId: 1,
        albumName: "First Album",
        albumYear: 2026,
        albumCover: "https://example.com/first.png",
        albumMedianColor: "#2E4272",
        tracks: [
            Track(trackId: 1, name: "First", url: "https://example.com/1.mp3", duration: "1:01"),
            Track(trackId: 2, name: "Second", url: "https://example.com/2.mp3", duration: "2:02")
        ]
    )

    private let secondAlbum = Album(
        albumId: 2,
        albumName: "Second Album",
        albumYear: 2026,
        albumCover: "https://example.com/second.png",
        albumMedianColor: "#42722E",
        tracks: [
            Track(trackId: 3, name: "Third", url: "https://example.com/3.mp3", duration: "3:03"),
            Track(trackId: 4, name: "Fourth", url: "https://example.com/4.mp3", duration: "4:04")
        ]
    )

    private let trackWithoutAlbum = Track(
        trackId: 5, name: "Fifth", url: "https://example.com/5.mp3", duration: "5:05"
    )

    private struct SUT {
        let albumListLoadedListener: AlbumListLoadedListenerMock
        let findNextTrackListener: FindNextTrackListenerMock
        let nextTrackSender: NextTrackSenderMock
        let logger: LoggerMock
        let selector: TrackSelector

        /// Returns once the selector has handled the given track of the NextTrack stream.
        func waitUntilSelectionOf(_ track: Track) async {
            await logger.waitForMessage(containing: "'\(track.name)' track has been received")
        }
    }

    /// The tracks given to the `NextTrack` listener are the ones the other features have selected.
    private func makeSUT(selectedElsewhere: [TrackData] = []) -> SUT {
        let albumListLoadedListener = AlbumListLoadedListenerMock()
        let findNextTrackListener = FindNextTrackListenerMock()
        let nextTrackSender = NextTrackSenderMock()
        let logger = LoggerMock()

        return SUT(
            albumListLoadedListener: albumListLoadedListener,
            findNextTrackListener: findNextTrackListener,
            nextTrackSender: nextTrackSender,
            logger: logger,
            selector: TrackSelectorImpl(
                albumListLoadedListener: albumListLoadedListener,
                findNextTrackListener: findNextTrackListener,
                nextTrackListener: NextTrackListenerMock(selectedElsewhere),
                nextTrackSender: nextTrackSender,
                logger: logger
            )
        )
    }

    // MARK: - Initial track selection

    @Test
    func initialTrackIsTheFirstTrackOfTheFirstAlbumAndDoesNotPlay() async {
        let sut = makeSUT()
        sut.selector.start()
        var sentTrackData = sut.nextTrackSender.sentTrackData.makeAsyncIterator()

        sut.albumListLoadedListener.send([firstAlbum, secondAlbum])

        #expect(await sentTrackData.next() == TrackData(track: firstAlbum.tracks[0], album: firstAlbum, autoPlay: false))
    }

    @Test
    func nextTrackOfTheInitialSelectionIsTheSecondTrackOfTheFirstAlbum() async {
        let sut = makeSUT()
        sut.selector.start()
        var sentTrackData = sut.nextTrackSender.sentTrackData.makeAsyncIterator()

        sut.albumListLoadedListener.send([firstAlbum, secondAlbum])
        _ = await sentTrackData.next()

        sut.findNextTrackListener.send()

        #expect(await sentTrackData.next() == TrackData(track: firstAlbum.tracks[1], album: firstAlbum, autoPlay: true))
    }

    // MARK: - Tracks selected by the other features

    @Test
    func trackFollowingTheOneSelectedElsewhereIsTakenFromTheAlbumItHasBeenSentWith() async {
        let sut = makeSUT(selectedElsewhere: [
            TrackData(track: secondAlbum.tracks[0], album: secondAlbum, autoPlay: true)
        ])
        sut.selector.start()
        var sentTrackData = sut.nextTrackSender.sentTrackData.makeAsyncIterator()

        await sut.waitUntilSelectionOf(secondAlbum.tracks[0])
        sut.findNextTrackListener.send()

        #expect(await sentTrackData.next() == TrackData(track: secondAlbum.tracks[1], album: secondAlbum, autoPlay: true))
    }

    @Test
    func theTrackAfterTheLastOneSelectedElsewhereIsTheFirstTrackOfTheSameAlbum() async {
        let sut = makeSUT(selectedElsewhere: [
            TrackData(track: secondAlbum.tracks[1], album: secondAlbum, autoPlay: true)
        ])
        sut.selector.start()
        var sentTrackData = sut.nextTrackSender.sentTrackData.makeAsyncIterator()

        await sut.waitUntilSelectionOf(secondAlbum.tracks[1])
        sut.findNextTrackListener.send()

        #expect(await sentTrackData.next() == TrackData(track: secondAlbum.tracks[0], album: secondAlbum, autoPlay: true))
    }

    /// The values of one stream are handled in the order they are sent, so the latest of them wins.
    @Test
    func albumOfTheLatestSelectionIsTheOneTheNextTrackIsLookedForIn() async {
        let sut = makeSUT(selectedElsewhere: [
            TrackData(track: firstAlbum.tracks[0], album: firstAlbum, autoPlay: true),
            TrackData(track: secondAlbum.tracks[0], album: secondAlbum, autoPlay: true)
        ])
        sut.selector.start()
        var sentTrackData = sut.nextTrackSender.sentTrackData.makeAsyncIterator()

        await sut.waitUntilSelectionOf(secondAlbum.tracks[0])
        sut.findNextTrackListener.send()

        #expect(await sentTrackData.next() == TrackData(track: secondAlbum.tracks[1], album: secondAlbum, autoPlay: true))
    }

    @Test
    func trackSelectedWithoutAnAlbumHasNoNextTrack() async {
        let sut = makeSUT(selectedElsewhere: [
            TrackData(track: trackWithoutAlbum, album: nil, autoPlay: true)
        ])
        sut.selector.start()
        var sentTrackData = sut.nextTrackSender.sentTrackData.makeAsyncIterator()

        await sut.waitUntilSelectionOf(trackWithoutAlbum)
        sut.findNextTrackListener.send()
        await sut.logger.waitForMessage(containing: "is not from an album")

        // Nothing has been sent for the track without an album, so the album list selection
        // made below is the first value the selector sends.
        sut.albumListLoadedListener.send([firstAlbum])

        #expect(await sentTrackData.next() == TrackData(track: firstAlbum.tracks[0], album: firstAlbum, autoPlay: false))
    }
}
