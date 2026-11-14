import Foundation

protocol BooksRepository {
    func fetchBooks() async throws -> [Book]
}

final class BooksRepositoryImpl: BooksRepository {

    private let sourceURL: URL
    private let cacheURL: URL
    private let urlSession: URLSession

    init(sourceURL: URL = URL(string: "http://maksimn.github.io/elizarov/books.json")!,
         fileManager: FileManager = .default,
         urlSession: URLSession = .shared) {
        self.sourceURL = sourceURL
        self.urlSession = urlSession

        let cachesDir = try? fileManager.url(for: .cachesDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: true)
        self.cacheURL = (cachesDir ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("books.json")
    }

    func fetchBooks() async throws -> [Book] {
        do {
            let (data, response) = try await urlSession.data(from: sourceURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            try saveCache(data)
            return try decodeBooks(from: data)
        } catch {
            // Fallback to cache if available
            if let data = try? Data(contentsOf: cacheURL) {
                return try decodeBooks(from: data)
            }
            throw error
        }
    }

    private func decodeBooks(from data: Data) throws -> [Book] {
        let decoder = JSONDecoder()
        return try decoder.decode([Book].self, from: data)
    }

    private func saveCache(_ data: Data) throws {
        try data.write(to: cacheURL, options: [.atomic])
    }
}
