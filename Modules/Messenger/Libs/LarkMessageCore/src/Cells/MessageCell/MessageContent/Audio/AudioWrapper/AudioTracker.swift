//
//  AudioTracker.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/17.
//

import Foundation
import Homeric
import LKCommonsTracker

final class AudioTracker {
    static func trackAudioPlayDrag() {
        Tracker.post(TeaEvent(Homeric.AUDIO_PLAY_DRAG))
    }
}
