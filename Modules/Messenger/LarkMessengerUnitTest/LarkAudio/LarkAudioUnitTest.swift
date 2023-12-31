//
//  LarkAudioUnitTest.swift
//  LarkMessengerUnitTest
//
//  Created by 李晨 on 2020/3/5.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import Swinject
import LarkMessengerInterface
import LarkSDKInterface
import RxSwift
import LarkModel
@testable import LarkAudio

class LarkAudioUnitTest: XCTestCase {

    var state: AudioRecordState = .prepare

    override func setUp() {
        super.setUp()
        self.state = .prepare
        AudioRecordManager.sharedInstance.delegate = self
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAudioPlay() {
        let player = AudioPlayMediatorImpl(audioResourceService: MockAudioResourceService())
        player.playAudioWith(keys: [.init("test")])
        let expectation = self.expectation(description: "play")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if case .playing = player.status {
            } else {
                assertionFailure("state is not playing")
            }
            player.updateStatus(.pause(AudioProgress(key: "test", current: 0, duration: 10) ))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if case .pause = player.status {
                } else {
                    assertionFailure("state is not pause")
                }
                player.stopPlayingAudio()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if case .default = player.status {
                    } else {
                        assertionFailure("state is not default")
                    }
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 10)
    }

    func testAudioRecordCancel() {
        AudioRecordManager.sharedInstance.startRecord()
        let expectation = self.expectation(description: "record")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if case .start = self.state {
            } else {
                assertionFailure("state is not start")
            }
            AudioRecordManager.sharedInstance.cancelRrcord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if case .cancel = self.state {
                } else {
                    assertionFailure("state is not cancel")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10)
    }

    func testAudioRecordTooShort() {
        AudioRecordManager.sharedInstance.startRecord()
        let expectation = self.expectation(description: "record")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if case .start = self.state {
            } else {
                assertionFailure("state is not start")
            }
            AudioRecordManager.sharedInstance.stopRecord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if case .tooShort = self.state {
                } else {
                    assertionFailure("state is not tooshort")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10)
    }

    func testAudioRecordFinish() {
        AudioRecordManager.sharedInstance.startRecord()
        let expectation = self.expectation(description: "record")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if case .start = self.state {
            } else {
                assertionFailure("state is not start")
            }
            AudioRecordManager.sharedInstance.stopRecord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if case .success(_, _) = self.state {
                } else {
                    assertionFailure("state is not success")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10)
    }

    func testAudioRecognitionVM() {
        let vm = AudioRecognizeViewModel(audioRecognizeService: MockAudioRecognizeService(), from: .audioMenu)
        assert(vm.state == .normal)
        vm.startRecognition(language: .en_US)
        let expectation = self.expectation(description: "expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            assert(vm.state == .recording)
            vm.endRecord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                assert(vm.state == .normal)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
    }

    func testAudioRecordVM() {
        let vm = AudioRecognizeViewModel(audioRecognizeService: MockAudioRecognizeService(), from: .audioMenu)
        assert(vm.state == .normal)
        vm.startRecognition(language: .en_US)
        let expectation = self.expectation(description: "expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            assert(vm.state == .recording)
            vm.endRecord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                assert(vm.state == .normal)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
    }

    func testAudioWithTextVM() {
        let vm = AudioWithTextRecordViewModel(audioRecognizeService: MockAudioRecognizeService(), from: .audioMenu)
        assert(vm.state == .normal)
        vm.startRecognition(language: .en_US)
        let expectation = self.expectation(description: "expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            assert(vm.state == .recording)
            vm.endRecord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                assert(vm.state == .normal)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
    }
}

extension LarkAudioUnitTest: RecordAudioDelegate {
    func audioRecordUpdateMetra(_ metra: Float) {
    }

    func audioRecordStateChange(state: AudioRecordState) {
        self.state = state
    }

    func audioRecordStreamData(data: Data) {
    }
}

class MockAudioResourceService: AudioResourceService {
    func fetch(key: String, compliteHandler: @escaping (Error?, AudioResource?) -> Void) {
        let path = Bundle(for: MockAudioResourceService.self).path(forResource: "call_waiting", ofType: "mp3")!
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        let audio = AudioResource(data: data!, duration: 10)
        compliteHandler(nil, audio)
    }
    func store(key: String, oldKey: String, resource: AudioResource) {
    }
    func resourceDownloaded(key: String) -> Bool {
        return false
    }
}

class MockAudioRecognizeService: AudioRecognizeService {
    var result: Observable<AudioRecognizeResult> {
        return Observable<AudioRecognizeResult>.create { (_) -> Disposable in
            return Disposables.create()
        }
    }

    func checkLastRcognitionFinish() -> Bool {
        return true
    }

    func receiveAudioRecognizeResult(result: AudioRecognizeResult, recognizeFailed: Bool) {
    }

    func updateAudioState(uploadID: String, sequenceId: Int32, state: AudioRecognizeState, callback: ((Error?) -> Void)?) {
    }

    func speechRecognition(
        uploadID: String,
        sequenceId: Int32,
        audioData: Data,
        action: SendSpeechRecognitionRequest.Action,
        speechLocale: String,
        callback: ((AudioRecognizeResult?, Error?) -> Void)?) {
    }
}
