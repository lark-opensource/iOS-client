//
//  AVAudioRecorderHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/12/21.
//

import Foundation

class AVAudioRecorderHooker: Hooker {

    lazy var setterArray: [(Selector, Selector)] = {
        var array = [
            (
                NSSelectorFromString("record"),
                NSSelectorFromString("lk_record")
            ), (
                #selector(AVAudioRecorder.record(atTime:)),
                #selector(AVAudioRecorder.lk_record(atTime:))
            ), (
                #selector(AVAudioRecorder.record(forDuration:)),
                #selector(AVAudioRecorder.lk_record(forDuration:))
            ), (
                #selector(AVAudioRecorder.record(atTime:forDuration:)),
                #selector(AVAudioRecorder.lk_record(atTime:forDuration:))
            )
        ]
        return array
    }()

    func willHook() {
    }

    func hook() {
        setterArray.forEach {
            swizzleInstanceMethod(AVAudioRecorder.self, from: $0.0, to: $0.1)
        }
    }

    func didHook() {
        LarkAudioSession.logger.info("AVAudioRecorder swizzle start")
    }
}

private extension AVAudioRecorder {
    @objc dynamic func lk_record() -> Bool {
        return LarkAudioSession.hook {
            lk_record()
        }
    }

    @objc dynamic func lk_record(atTime time: TimeInterval) -> Bool {
        return LarkAudioSession.hook(time) {
            lk_record(atTime: time)
        }
    }

    @objc dynamic func lk_record(forDuration duration: TimeInterval) -> Bool {
        return LarkAudioSession.hook(duration) {
            lk_record(forDuration: duration)
        }
    }

    @objc dynamic func lk_record(atTime time: TimeInterval, forDuration duration: TimeInterval) -> Bool {
        return LarkAudioSession.hook(time, duration) {
            lk_record(atTime: time, forDuration: duration)
        }
    }
}
