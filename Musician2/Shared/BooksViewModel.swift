import Foundation
import Observation

@Observable
final class BooksViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Book])
        case failed(String)
    }

    private(set) var state: State = .idle

    private let repository: BooksRepository

    init(repository: BooksRepository = BooksRepositoryImpl()) {
        self.repository = repository
    }

    @MainActor
    func load() async {
        state = .loading
        do {
            let books = try await repository.fetchBooks()
            state = .loaded(books)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
