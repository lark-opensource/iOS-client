//
//  LarkMediaResource.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/24.
//

import Foundation
import LKCommonsLogging

@objcMembers
public final class LarkMediaResource {

    static let logger = Logger.log(LarkMediaResource.self, category: "LarkMedia.LarkMediaResource")

    public let scene: MediaMutexScene

    public var microphone: LarkMicrophoneService { _microphone }
    public var audioSession: LarkAudioSessionService { _audioSession }

    let _microphone: LarkMicrophoneManager
    let _audioSession: LarkAudioSessionManager

    private let enableRuntime: Bool

    init(scene: MediaMutexScene, enableRuntime: Bool) {
        self.scene = scene
        self.enableRuntime = enableRuntime
        self._microphone = LarkMicrophoneManager(scene: scene, enableRuntime: enableRuntime)
        self._audioSession = LarkAudioSessionManager(scene: scene)
        Self.logger.info("init LarkMediaResource scene: \(scene)")
    }

    deinit {
        Self.logger.info("deinit LarkMediaResource scene: \(scene)")
    }
}
