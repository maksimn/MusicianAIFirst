//
//  AlbumDetailsFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import SwiftUI

struct AlbumDetailsFeature: View {

    let album: Album

    var body: some View {
        AlbumDetailsView(
            viewModel: AlbumDetailsViewModelImpl(
                album: album,
                nextTrackListener: NextTrackStream.shared,
                currentTrackProvider: CurrentTrackProviderImpl.shared,
                selectTrackSender: SelectTrackStream.shared
            )
        )
    }
}
