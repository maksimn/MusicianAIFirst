//
//  ContentView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 30.06.2026.
//

import SwiftUI
import UDF

struct AppView: View {

    /// The index of the Books tab in the view pager: the audio player is hidden while it is
    /// selected, since the books have nothing to play.
    private static let booksTabIndex = 0

    @State var store: Store<AppState>

    @State private var selectedTabIndex = 1

    var body: some View {
        VStack(spacing: 2) {
            ViewPager(selectedIndex: 1, onPageSelected: { selectedTabIndex = $0 }) {
                ViewPagerPage("КНИГИ") {
                    BooksView()
                }

                ViewPagerPage("АЛЬБОМЫ") {
                    AlbumListFeature(store: store)
                }

                ViewPagerPage("ИЗБРАННОЕ") {
                    FavoritesView(store: ObservableStore(store.scope(\.favorites)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if selectedTabIndex == Self.booksTabIndex {
                // The player is hidden on the Books tab: the empty view keeps the if/else
                // branches type-compatible and lets the player ease out instead of vanishing.
                Color.clear
                    .transition(.opacity.animation(.easeOut(duration: 0.25)))
            } else {
                AudioPlayerFeature(store: store.scope(\.audioPlayer))
                    .transition(.opacity.animation(.easeIn(duration: 0.25)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTabIndex)
    }
}
