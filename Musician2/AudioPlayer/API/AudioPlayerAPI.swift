//
//  AudioPlayerAPI.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.07.2026.
//

import AVFoundation

protocol AudioPlayerAPI {

    var delegate: AudioPlayerDelegate? { get set }

    func initialize(with data: Data) throws

    func play()

    func pause()

    var currentTime: TimeInterval { get }

    var duration: TimeInterval { get }
}

protocol AudioPlayerDelegate: AnyObject {

    func didFinishPlaying()
}

final class AVAudioPlayerAPI: NSObject, AudioPlayerAPI {

    weak var delegate: AudioPlayerDelegate?

    private var audioPlayer: AVAudioPlayer?

    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }

    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }

    func initialize(with data: Data) throws {
        let player = try AVAudioPlayer(data: data)
        player.delegate = self
        audioPlayer = player
    }

    func play() {
        audioPlayer?.play()
    }

    func pause() {
        audioPlayer?.pause()
    }
}

// MARK: - AVAudioPlayerDelegate

extension AVAudioPlayerAPI: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.didFinishPlaying()
    }
}
