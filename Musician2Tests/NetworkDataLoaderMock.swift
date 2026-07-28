@testable import Musician2
import Foundation

final class NetworkDataLoaderMock: NetworkDataLoader {

    private(set) var downloadMock: (URL) async throws -> Data

    init(_ downloadMock: @escaping (URL) async throws -> Data) {
        self.downloadMock = downloadMock
    }

    func download(_ url: URL) async throws -> Data {
        try await downloadMock(url)
    }
}
