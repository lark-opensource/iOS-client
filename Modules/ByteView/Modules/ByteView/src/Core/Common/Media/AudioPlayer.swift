//
//  AudioPlayer.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/11/15.
//

import Foundation
import ByteViewMeeting

protocol AudioPlayer: NSObject {
    associatedtype SoundType

    func play(_ sound: SoundType, completion: ((Bool) -> Void)?)
}

class MeetingAudioPlayer: NSObject {
    let audioOutput: AudioOutputManager
    var isEnabled: Bool

    required init(meeting: InMeetMeeting) {
        self.audioOutput = meeting.audioDevice.output
        self.isEnabled = !audioOutput.isMuted && !audioOutput.isDisabled
        super.init()
        audioOutput.addListener(self)
    }

    init(audioOutput: AudioOutputManager) {
        self.audioOutput = audioOutput
        self.isEnabled = !audioOutput.isMuted && !audioOutput.isDisabled
        super.init()
        audioOutput.addListener(self)
    }
}

extension MeetingAudioPlayer: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        isEnabled = !output.isMuted && !output.isDisabled
    }
}
