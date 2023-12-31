//
//  RingPlayer.swift
//  ByteView
//
//  Created by kiri on 2020/8/4.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import LarkMedia

protocol RingPlayerListener {
    func ringPlayerDidFinished()
}

final class RingPlayer: NSObject {

    enum Scene: Equatable {
        case ringing(String?)
        /// 自定义铃声试听
        case customizeRingtone(URL?)
    }

    func recentRingtonURL(ringtone: String?) -> URL {
        switch ringtone {
        case Resources.springRingNotificationSoundName:
            return Bundle.ringingSpringURL!
        default:
            return Bundle.ringingURL!
        }
    }

    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    static let shared = RingPlayer()

    private let logger = Logger.audio

    private var currentScene: Scene?
    private static let queue = DispatchQueue(label: "lark.byteview.RingPlayer")

    private var playingSounds: [SystemSoundID: SoundConfig] = [:]
    private lazy var systemSoundCompletion: AudioServicesSystemSoundCompletionProc = { (id: SystemSoundID, point: UnsafeMutableRawPointer?) in
        RingPlayer.queue.async {
            if let point = point {
                let manager = Unmanaged<RingPlayer>.fromOpaque(point).takeUnretainedValue()
                if let config = manager.playingSounds[id] {
                    if config.repeats {
                        // nolint-next-line: magic number
                        RingPlayer.queue.asyncAfter(deadline: .now() + .milliseconds(800), execute: { [weak manager] in
                            manager?.playSound(config: config)
                        })
                    } else {
                        manager.unloadSound(id)
                    }
                }
            }
        }
    }

    private var audioPlayer: AVAudioPlayer?
    private lazy var logDescription = metadataDescription(of: self)
    private let listener = Listeners<RingPlayerListener>()

    private override init() {
        super.init()
        logger.info("init \(logDescription)")
    }

    func play(_ scene: RingPlayer.Scene, completion: ((Bool) -> Void)? = nil) {
        LarkAudioSession.shared.waitAudioSession("RingPlayer.play", in: RingPlayer.queue) { [weak self] in
            guard let `self` = self else {
                completion?(false)
                return
            }
            if scene != self.currentScene {
                self.doStop()
                self.currentScene = scene
            }

            if self.audioPlayer != nil { // is playing current scene
                completion?(false)
                return
            }

            self.doPlay(completion)
        }
    }

    func stop() {
        LarkAudioSession.shared.waitAudioSession("RingPlayer.stop", in: RingPlayer.queue) { [weak self] in
            guard let `self` = self else { return }
            self.doStop()
            self.currentScene = nil
            self.listener.forEach { $0.ringPlayerDidFinished() }
            self.logger.info("stop \(self.logDescription)")
        }
    }

    private func doPlay(_ completion: ((Bool) -> Void)? = nil) {
        guard let scene = self.currentScene else {
            completion?(false)
            return
        }

        switch scene {
        case .ringing(let ringtone):
            logger.info("play ringing sound")
            self.playAudio(url: recentRingtonURL(ringtone: ringtone), repeats: true, completion: completion)
            self.playSound(kSystemSoundID_Vibrate, repeats: true, isAlert: true)
        case .customizeRingtone(let ringtoneURL):
            logger.info("play customize ringtone \(ringtoneURL)")
            self.playAudio(url: ringtoneURL, repeats: false, completion: completion)
        }
    }

    private func doStop() {
        logger.info("stop all sounds, sounds: \(playingSounds), audioPlayer: \(String(describing: audioPlayer))")
        let soundIds = self.playingSounds.keys
        for id in soundIds {
            self.unloadSound(id)
        }

        if let audioPlayer = self.audioPlayer {
            audioPlayer.stop()
            self.audioPlayer = nil
            logger.info("audio player stop: \(audioPlayer)")
        }
    }

    private func playAudio(url: URL?, repeats: Bool, completion: ((Bool) -> Void)? = nil) {
        guard self.audioPlayer == nil, let soundUrl = url else {
            logger.error("current audio player is not nil, url = \(String(describing: url))")
            completion?(false)
            return
        }

        logger.info("audioPlayer will play url: \(soundUrl), repeats = \(repeats)")
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            audioPlayer.delegate = self
            if repeats {
                audioPlayer.numberOfLoops = -1
            }
            if !audioPlayer.prepareToPlay() || !audioPlayer.play() {
                logger.error("audioPlayer play or prepareToPlay no success")
                audioPlayer.stop()
                completion?(false)
                return
            }
            logger.error("audioPlayer playing url: \(soundUrl.lastPathComponent), player = \(audioPlayer)")
            self.audioPlayer = audioPlayer
            completion?(true)
        } catch {
            logger.error("init audio player error: \(error)")
            completion?(false)
        }
    }

    private func playSound(_ soundID: SystemSoundID, repeats: Bool, isAlert: Bool) {
        if !self.playingSounds.keys.contains(soundID) {
            let managerPoint = Unmanaged<RingPlayer>.passUnretained(self).toOpaque()
            AudioServicesAddSystemSoundCompletion(soundID, nil, nil, self.systemSoundCompletion, managerPoint)
        }

        let config = SoundConfig(soundID: soundID, repeats: repeats, isAlert: isAlert)
        self.playingSounds[soundID] = config
        playSound(config: config)
        logger.info("sound manager play system sound")
    }

    private func playSound(config: SoundConfig) {
        let soundID = config.soundID
        if soundID != 0 {
            if config.isAlert {
                AudioServicesPlayAlertSound(soundID)
            } else {
                AudioServicesPlaySystemSound(soundID)
            }
        }
    }

    private func unloadSound(_ soundID: SystemSoundID) {
        logger.info("will unload sound id \(soundID)")
        AudioServicesRemoveSystemSoundCompletion(soundID)
        let status: OSStatus = AudioServicesDisposeSystemSoundID(soundID)
        logger.info("did unload sound id \(soundID), stauts: \(status)")
        if status != kAudioServicesNoError {
            logger.error("system sound play dispose not success")
        }
        self.playingSounds.removeValue(forKey: soundID)
    }

    private struct SoundConfig {
        let soundID: SystemSoundID
        let repeats: Bool
        let isAlert: Bool
    }
}

extension RingPlayer {
    func addListener(_ listener: RingPlayerListener) {
        self.listener.addListener(listener)
    }

    func removeListener(_ listener: RingPlayerListener) {
        self.listener.removeListener(listener)
    }
}


extension RingPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        logger.info("audioPlayerDidFinishPlaying: \(player), successfully = \(flag)")
        self.listener.forEach { $0.ringPlayerDidFinished() }
        if !flag {
            player.delegate = nil
            logger.error("audioPlayerDidFinishPlaying failed, retry after 1s. player = \(player)")
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) { [weak player] in
                LarkAudioSession.shared.waitAudioSession("retry RingPlayer.stop") {
                    if let player = player {
                        self.logger.error("retry stoping player \(player)")
                        player.stop()
                    }
                }
            }
        }
    }
}
