//
//  LocalAudioPlayer.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/11/15.
//

import Foundation
import AVFoundation
import LarkMedia

enum LocalAlertSound: Int {
    case enterMeeting = 1
    case leaveMeeting
}

extension LocalAlertSound {
    private var resource: String {
        switch self {
        case .enterMeeting:
            return "enter_chime"
        case .leaveMeeting:
            return "exit_chime"
        }
    }

    private var type: String {
        return "mp3"
    }

    var url: URL? {
        return Bundle.localResources.url(forResource: resource, withExtension: type)
    }

    var filePath: String? {
        return Bundle.localResources.path(forResource: resource, ofType: type)
    }
}

class LocalAudioPlayer: MeetingAudioPlayer, AudioPlayer {

    private var players: [Int: AVAudioPlayer] = [:]

    private static let logger = Logger.audio
    private static let semaphore = DispatchSemaphore(value: 0)

    deinit {
        Self.logger.info("deinit \(self)")
        for player in players.values {
            player.delegate = nil
            player.stop()
        }
        Self.semaphore.signal()
        // 延迟释放，try fix https://t.wtturl.cn/BmMxmj2/
        DelayReleaseManager.append(Array(players.values), delaySeconds: 5)
    }

    func play(_ sound: LocalAlertSound, completion: ((Bool) -> Void)?) {
        guard isEnabled else {
            Self.logger.info("Current audio output mode is muted or disabled, skip playing local audio \(sound)")
            completion?(true)
            return
        }

        let player: AVAudioPlayer
        if let cached = players[sound.rawValue] {
            player = cached
            player.currentTime = 0
        } else {
            guard let url = sound.url else {
                Self.logger.error("cannot find url of local audio \(sound)")
                completion?(false)
                return
            }
            do {
                let p = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
                p.delegate = self
                p.prepareToPlay()
                players[sound.rawValue] = p
                player = p
            } catch {
                Self.logger.error("fail to initialize local audio player for audio \(sound), error: \(error)")
                completion?(false)
                return
            }
        }
        LarkAudioSession.shared.waitAudioSession("LocalAudioPlayer.play") {
            if LarkAudioSession.shared.mode == .voiceChat {
                // voiceChat mode 模式下声音会变轻，故增益
                player.volume = 0.3
                Self.logger.info("play volume 0.3")
            } else {
                player.volume = 1.0
                Self.logger.info("play volume 1.0")
            }
            let result = player.play()
            if result == true {
                Self.logger.info("succeed to play local audio: \(sound)")
            } else {
                Self.logger.info("fail to play local audio: \(sound)")
            }
            if Self.semaphore.wait(timeout: .now() + .seconds(2)) == .timedOut {
                Self.logger.error("LocalAudioPlayer play timedOut!, sound: \(sound)")
            }
        }
    }
}

extension LocalAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Self.semaphore.signal()
        Self.logger.info("local audio player: \(player) did finish playing successfully: \(flag)")
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Self.logger.info("audioPlayerDecodeErrorDidOccur, error: \(error)")
    }

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        Self.logger.info("audioPlayerBeginInterruption")
    }

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        Self.logger.info("audioPlayerEndInterruption")
    }
}
