import SwiftUI

struct BooksListView: View {
    @State private var viewModel = BooksViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading books…")
                case .failed(let message):
                    ContentUnavailableView(
                        "Failed to load books",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                case .loaded(let books):
                    if books.isEmpty {
                        ContentUnavailableView(
                            "No books",
                            systemImage: "book.closed",
                            description: Text("Pull to refresh or try again later.")
                        )
                    } else {
                        list(books)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private func list(_ books: [Book]) -> some View {
        List(books) { book in
            BookRowView(book: book)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
