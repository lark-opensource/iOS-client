//
//  ObserverManager.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/9/16.
//

import Foundation

class ObserverManager<T> {

    private var observerMap: [SceneMediaConfig: WeakRef<AnyObject>] = [:]

    func addObserver(_ observer: T?, for config: SceneMediaConfig) {
        if let observer = observer as? AnyObject {
            observerMap[config] = WeakRef(observer)
        }
    }

    func removeObserver(for config: SceneMediaConfig) {
        observerMap.removeValue(forKey: config)
    }
}

extension ObserverManager {
    func notifyInterruptionBegin(to config: SceneMediaConfig, by: SceneMediaConfig, type: MediaMutexType, msg: String?) {
        if let observer = observerMap[config]?.value as? MediaResourceInterruptionObserver {
            observer.mediaResourceWasInterrupted(by: by.scene, type: type, msg: msg)
        }
    }

    func notifyInterruptionEnd(to config: SceneMediaConfig, from: SceneMediaConfig, type: MediaMutexType) {
        if let observer = observerMap[config]?.value as? MediaResourceInterruptionObserver {
            observer.mediaResourceInterruptionEnd(from: from.scene, type: type)
        }
    }
}

extension ObserverManager {
    func notifyMicrophoneMuteStateChange(isMuted: Bool, isTriggeredInApp: Bool?) {
        observerMap.values.forEach {
            if let observer = $0.value as? LarkMicrophoneObserver {
                observer.applicationMicrophoneMuteStateDidChange(isMuted: isMuted, isTriggeredInApp: isTriggeredInApp)
            }
        }
    }
}
