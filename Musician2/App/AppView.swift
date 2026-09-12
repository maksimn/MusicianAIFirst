//
//  ContentView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 30.06.2026.
//

import SwiftUI
import UDF

struct AppView: View {

    @State var store: Store<AppState>

    var body: some View {
        VStack(spacing: 2) {
            ViewPager(selectedIndex: 1) {
                ViewPagerPage("КНИГИ") {
                    // The books feature is not there yet: the tab only keeps the place it will take.
                    Color(.systemBackground)
                }

                ViewPagerPage("АЛЬБОМЫ") {
                    AlbumListFeature(store: store)
                }

                ViewPagerPage("ИЗБРАННОЕ") {
                    FavoritesView(store: ObservableStore(store.scope(\.favorites)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AudioPlayerFeature(store: store.scope(\.audioPlayer))
        }
    }
}
