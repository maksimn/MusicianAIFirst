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
                    FavoritesView()
                }

                ViewPagerPage("АЛЬБОМЫ") {
                    AlbumListFeature(store: store)
                }

                ViewPagerPage("ИЗБРАННОЕ") {
                    FavoritesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            AudioPlayerFeature(store: store.scope(\.audioPlayer))
        }
    }
}
