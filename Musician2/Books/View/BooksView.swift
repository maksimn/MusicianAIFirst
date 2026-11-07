//
//  BooksView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.11.2026.
//

import SwiftUI

/// The entry view of the Books feature: it builds the feature dependencies and renders the books
/// list driven by the view model.
struct BooksView: View {

    @StateObject private var viewModel: BooksViewModel

    init(viewModel: BooksViewModel = BooksViewModel(
        loadBooksUseCase: LoadBooksUseCaseImpl(
            repository: RemoteBooksRepository(
                dataLoader: URLSessionNetworkDataLoader(),
                fileCache: BooksFileCache()
            )
        )
    )) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading books…")
            case .failed(let error):
                ContentUnavailableView(
                    "Failed to load books",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            case .loaded(let books) where books.isEmpty:
                ContentUnavailableView(
                    "No books",
                    systemImage: "books.vertical",
                    description: Text("Try again later.")
                )
            case .loaded(let books):
                booksList(books)
            }
        }
        .task {
            await viewModel.loadBooks()
        }
    }

    private func booksList(_ books: [Book]) -> some View {
        List(books) { book in
            BookRowView(book: book)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
