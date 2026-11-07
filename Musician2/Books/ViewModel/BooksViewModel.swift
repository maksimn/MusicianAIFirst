//
//  BooksViewModel.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import Foundation

/// The view model of the books list.
///
/// It follows the Clean MVVM approach the project used before the UDF refactoring: the view
/// observes the published state and asks the view model to load the books, and the view model
/// delegates the business work to the use case.
@MainActor
final class BooksViewModel: ObservableObject {

    /// The state of the books list as the view renders it.
    enum State {

        case loading

        case loaded([Book])

        case failed(Error)
    }

    @Published private(set) var state: State = .loading

    private let loadBooksUseCase: LoadBooksUseCase

    init(loadBooksUseCase: LoadBooksUseCase) {
        self.loadBooksUseCase = loadBooksUseCase
    }

    /// Loads the books list, updating the state with the progress, the result or the failure.
    func loadBooks() async {
        state = .loading

        do {
            state = try await .loaded(loadBooksUseCase.execute())
        } catch {
            state = .failed(error)
        }
    }
}
