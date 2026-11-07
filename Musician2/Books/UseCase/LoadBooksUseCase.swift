//
//  LoadBooksUseCase.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import Foundation

/// The use case of loading the books list: it is the single business operation of the Books
/// feature, standing between the ViewModel and the repository.
protocol LoadBooksUseCase {

    func execute() async throws -> [Book]
}

/// Loads the books through the repository, leaving the orchestration of the sources — the remote
/// feed and the local cache — to the repository itself.
struct LoadBooksUseCaseImpl: LoadBooksUseCase {

    let repository: BooksRepository

    func execute() async throws -> [Book] {
        try await repository.loadBooks()
    }
}
