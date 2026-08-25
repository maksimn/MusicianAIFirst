//
//  AudioPlayerView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 12.07.2026.
//

import SwiftUI

struct AudioPlayerView: View {

    let store: ObservableStore<AudioPlayerState>

    private var state: AudioPlayerState {
        store.state
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    store.dispatch(AudioPlayerAction.playPauseTapped)
                } label: {
                    if state.condition == .playing {
                        Image("icon-stop")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .padding(.leading, 18)
                            .padding(.top, 2)
                    } else {
                        Image("icon-play")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .padding(.leading, 18)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(width: 56, height: 76)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text(state.track?.name ?? "")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.leading, 10)

                    Spacer()

                    if state.condition == .loading {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }

                    Text(state.timeDisplay)
                        .font(Font.custom("Helvetica Bold", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.trailing, 20)
                }
                .padding(.top, 4)

                ProgressView(value: state.progressValue)
                    .tint(.white)
                    .background(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 2)
                    .padding(.leading, 10)
                    .padding(.trailing, 56)
                    .padding(.top, 8)
            }
            .padding(.top, -6)
            .padding(.leading, 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
    }
}
