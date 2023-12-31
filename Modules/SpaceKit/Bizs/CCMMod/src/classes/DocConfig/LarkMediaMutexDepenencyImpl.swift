//
//  LarkMediaMutexDepenencyImpl.swift
//  CCMMod
//
//  Created by ByteDance on 2022/11/24.
//

import Foundation
import LarkMedia
import SpaceInterface
import LKCommonsLogging

extension SKMediaScene {
    var larkMediaScene: MediaMutexScene {
        switch self {
        case .ccmPlay:
            return MediaMutexScene.ccmPlay
        case .ccmRecord:
            return MediaMutexScene.ccmRecord
        }
    }
}

class LarkMediaMutexDepenencyImpl: SKMediaMutexDependency {
    private static let logger = Logger.log(MediaCompressDependencyImpl.self, category: "MediaMutex.LarkMediaMutexDepenencyImpl")

    private weak var observer: SpaceInterface.SKMediaResourceInterruptionObserver?
    func tryLock(scene: SKMediaScene,
                 mixWithOthers: Bool,
                 mute: Bool,
                 observer: SKMediaResourceInterruptionObserver,
                 interruptResult: @escaping (SKMediaInterruptResult) -> Void) {
        let options = mixWithOthers ? MediaMutexOptions.mixWithOthers : []
        Self.logger.info("try lock with scene: \(scene), mixWithOthers: \(mixWithOthers)")
        self.observer = observer
        LarkMediaManager.shared.tryLock(scene: scene.larkMediaScene, options: options, observer: self, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let mediaResource):
                    Self.logger.info("try lock success")
                    if #available(iOS 17, *), !mute {
                        mediaResource.microphone.requestMute(false) { _ in }
                    }
                    interruptResult(.success)
                case .failure(let error):
                    Self.logger.error("try lock failed", error: error)
                    switch error {
                    case let MediaMutexError.occupiedByOther(_, msg):
                        interruptResult(.occupiedByOther(msg: msg))
                    case MediaMutexError.sceneNotFound:
                        interruptResult(.sceneNotFound)
                    case MediaMutexError.unknown:
                        interruptResult(.unknown)
                    }
                }
            }
        })
    }
    func unlock(scene: SpaceInterface.SKMediaScene, observer: SKMediaResourceInterruptionObserver) {
        Self.logger.info("unkock scene: \(scene)")
        LarkMediaManager.shared.unlock(scene: scene.larkMediaScene)
    }

    func enterDriveAudioSessionScenario(scene: SpaceInterface.SKMediaScene, id: String) {
        if let audioSession = LarkMediaManager.shared.getMediaResource(for: scene.larkMediaScene)?.audioSession {
            let scenario = AudioSessionScenario(id, category: .playback)
            audioSession.enter(scenario)
        }
    }
    func leaveDriveAudioSessionScenario(scene: SpaceInterface.SKMediaScene, id: String) {
        if let audioSession = LarkMediaManager.shared.getMediaResource(for: scene.larkMediaScene)?.audioSession {
            let scenario = AudioSessionScenario(id, category: .playback)
            audioSession.leave(scenario)
        }
    }
}

extension LarkMediaMutexDepenencyImpl: MediaResourceInterruptionObserver {
    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        Self.logger.info("media resource interupted by scene: \(scene), type: \(type), msg: \(msg ?? "")")
        observer?.mediaResourceInterrupted(with: msg)
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        Self.logger.info("meida resource interruption end from: \(scene), type: \(type)")
        observer?.meidaResourceInterruptionEnd()
    }
}
