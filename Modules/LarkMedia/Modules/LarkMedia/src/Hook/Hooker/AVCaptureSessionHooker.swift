//
//  AVCaptureSessionHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/12/21.
//

import Foundation

class AVCaptureSessionHooker: Hooker {

    lazy var setterArray: [(Selector, Selector)] = {
        var array = [
            (
                #selector(AVCaptureSession.startRunning),
                #selector(AVCaptureSession.lk_startRunning)
            ),
        ]
        return array
    }()

    func willHook() {
    }

    func hook() {
        setterArray.forEach {
            swizzleInstanceMethod(AVCaptureSession.self, from: $0.0, to: $0.1)
        }
    }

    func didHook() {
        LarkAudioSession.logger.info("AVCaptureSession swizzle start")
    }
}

private extension AVCaptureSession {
    @objc dynamic func lk_startRunning() {
        LarkAudioSession.hook(block: {
            lk_startRunning()
        }, completion: { _ in

        })
    }
}
