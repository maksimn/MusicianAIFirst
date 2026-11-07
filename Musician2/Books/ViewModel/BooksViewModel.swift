//
//  BooksViewModel.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import Foundation
import Observation

/// The view model protocol of the books list.
protocol BooksViewModel: AnyObject {
    var state: BooksViewModelState { get }
    func loadBooks() async
}

/// The state of the books list as the view renders it.
enum BooksViewModelState {
    case loading
    case loaded([Book])
    case failed(Error)
}

/// The default implementation of the books view model.
@Observable
final class BooksViewModelImpl: BooksViewModel {

    private(set) var state: BooksViewModelState = .loading

    private let repository: BooksRepository

    init(repository: BooksRepository) {
        self.repository = repository
    }

    /// Loads the books list, updating the state with the progress, the result or the failure.
    func loadBooks() async {
        state = .loading

        do {
            state = try await .loaded(repository.loadBooks())
        } catch {
            state = .failed(error)
        }
    }
}
