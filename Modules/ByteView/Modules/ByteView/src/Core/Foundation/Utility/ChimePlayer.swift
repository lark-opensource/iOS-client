//
//  ChimePlayer.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/5/23.
//

import Foundation

final class ChimePlayerFactory<Player> where Player: MeetingAudioPlayer, Player: AudioPlayer {
    func create(meeting: InMeetMeeting) -> ChimePlayer<Player> {
        ChimePlayer(player: Player(meeting: meeting))
    }
}

class ChimePlayer<Player> where Player: AudioPlayer {

    private let queue = DispatchQueue(label: "ByteView.ChimePlayer")
    private let player: Player

    private var lastPlayTime: TimeInterval = 0
    private weak var lastPlayItem: DispatchWorkItem? {
        didSet {
            oldValue?.cancel()
        }
    }

    init(player: Player) {
        self.player = player
    }

    func play(_ sound: Player.SoundType) {
        queue.async { [weak player] in
            player?.play(sound, completion: nil)
        }
    }

    func schedule(_ sound: Player.SoundType) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let item = DispatchWorkItem {
                self.lastPlayTime = Date.timeIntervalSinceReferenceDate
                self.play(sound)
                self.lastPlayItem = nil
            }
            let duration = Int((Date.timeIntervalSinceReferenceDate - self.lastPlayTime) * 1000)
            let intervalTime: Int = 2000
            if duration > intervalTime {
                item.perform()
            } else {
                self.lastPlayItem = item
                // nolint-next-line: magic number
                self.queue.asyncAfter(deadline: .now() + .milliseconds(intervalTime - duration), execute: item)
            }
        }
    }
}
