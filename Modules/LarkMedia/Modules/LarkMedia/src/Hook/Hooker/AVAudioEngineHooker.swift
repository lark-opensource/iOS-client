//
//  AVAudioEngineHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/12/21.
//

import Foundation

class AVAudioEngineHooker: Hooker {

    lazy var setterArray: [(Selector, Selector)] = {
        var array = [
            (
                #selector(AVAudioEngine.start),
                #selector(AVAudioEngine.lk_start)
            ),
        ]
        return array
    }()

    func willHook() {
    }

    func hook() {
        setterArray.forEach {
            swizzleInstanceMethod(AVAudioEngine.self, from: $0.0, to: $0.1)
        }
    }

    func didHook() {
        LarkAudioSession.logger.info("AVAudioEngine swizzle start")
    }
}

private extension AVAudioEngine {
    @objc dynamic func lk_start() throws {
        try LarkAudioSession.hook(block: {
            try lk_start()
        }, completion: { _ in

        })
    }
}
