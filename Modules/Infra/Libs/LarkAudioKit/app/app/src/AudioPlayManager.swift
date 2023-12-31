//
//  AudioManager.swift
//  LarkAudioKitDev
//
//  Created by 李晨 on 2021/6/22.
//
import Foundation
import UIKit
import AVFoundation
import RxSwift
import LKCommonsLogging
import LarkAudioKit

class AudioPlayMediator {
    static let logger = Logger.log(AudioPlayMediator.self, category: "Module.Audio")

    fileprivate let playService: AudioPlayService = AudioPlayService()

    var isPlaying: Bool {
        return self.playService.isPlaying
    }

    var status: AudioPlayingStatus {
        return playService.status
    }

    var volume: Float {
        return AVAudioSession.sharedInstance().outputVolume
    }

    let disposeBag = DisposeBag()

    private let playQueue = DispatchQueue(label: "audio.mediator.play.queue")

    init() {
    }

    func stopPlayingAudio() {
        self.playQueue.async { [weak self] in
            self?.playService.stopPlayingAudio()
        }
    }

    func pausePlayingAudio() {
        self.playQueue.async { [weak self] in
            self?.playService.pauseAudioPlayer()
        }
    }

    func isPlaying(key: String) -> Bool {
        return playService.playingAudioWith(key: key)
    }

    func playAudioWith(data: Data, key: String, play: Bool) {
        /// 如果切换了输出方式, 则按照新切换的播放, 否则按照原来设置的播放
        playService.loadAudioWith(
            data: .data(data),
            playerType: .speaker,
            audioKey: key,
            continueWhenPause: true,
            play: play
        )
    }
}
