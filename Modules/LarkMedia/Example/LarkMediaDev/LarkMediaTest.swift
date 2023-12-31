//
//  AudioSessionScenarioTest.swift
//  AudioSessionScenarioDev
//
//  Created by fakegourmet on 2022/1/11.
//

import Foundation
import LarkMedia
import AVFoundation

class AudioSessionScenarioTest {

    init() {
        LarkAudioSession.setup {
            LarkAudioSession.shared.hookAudioSession()
            LarkAudioSession.activateNotification()
        }
        testEntry()
        testMediaMutex()
    }

    func testEntry() {
        LarkMediaManager.shared.tryLock(scene: .vcMeeting) { result in
            if case .success(let resource) = result {
                let scenario = AudioSessionScenario("scenario")
                resource.audioSession.enter(scenario)
                resource.audioSession.leave(scenario)
            }
        }
    }

    func testMediaMutex() {
        LarkMediaManager.shared.tryLock(scene: .microPlay(id: "testA"), options: [], observer: TestA()) { _ in }
        let _ = LarkMediaManager.shared.tryLock(scene: .microRecord(id: "testB"), options: [], observer: self)
        LarkMediaManager.shared.tryLock(scene: .microPlay(id: "testA"), options: [], observer: TestA()) { _ in }
    }
}

extension AudioSessionScenarioTest: MediaResourceInterruptionObserver {
    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        print("mediaResourceWasInterrupted \(scene) \(type) \(String(describing: msg))")
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        print("mediaResourceInterruptionEnd \(scene) \(type)")
    }
}

class TestA: MediaResourceInterruptionObserver {
    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        print("mediaResourceWasInterrupted \(scene) \(type) \(String(describing: msg))")
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        print("mediaResourceInterruptionEnd \(scene) \(type)")
    }
}

class TestB: MediaResourceInterruptionObserver {
    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        print("mediaResourceWasInterrupted \(scene) \(type) \(String(describing: msg))")
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        print("mediaResourceInterruptionEnd \(scene) \(type)")
    }
}

