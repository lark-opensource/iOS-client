//
//  LarkAudioKitTest.swift
//  LarkAudioKitDevEEUnitTest
//
//  Created by 李晨 on 2020/3/20.
//

import Foundation
import XCTest
@testable import LarkAudioKit

class LarkAudioKitTest: XCTestCase, RecordServiceDelegate {

    var playService: AudioPlayService!
    var recordService: RecordService!

    override func setUp() {
        playService = AudioPlayService()
        recordService = RecordService(sampleRate: 8000, channel: 1, bitsPerChannel: 16)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPlay() {
        if let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") {
            let key = "test"

            let audioData = AudioData.path(url)
            self.playService.loadAudioWith(data: audioData, playerType: .earPhone, audioKey: key)

            assert(self.playService.isPlaying)
            assert(self.playService.playingKey == key)

            self.playService.pauseAudioPlayer()
            assert(self.playService.isPaused)
            assert(self.playService.currentAudioKey == key)

            self.playService.continuePlay(audioKey: key, lastPlayerType: .speaker)
            assert(self.playService.isPlaying)

            self.playService.stopPlayingAudio()
            assert(!self.playService.isPlaying)
        } else {
            assertionFailure()
        }
    }

    func testRecord() {
        let e = self.expectation(description: "test")
        recordService.startRecord(encoder: self)
        assert(recordService.isRecording)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.recordService.stopRecord()
            assert(!self.recordService.isRecording)
            e.fulfill()
        }
        self.wait(for: [e], timeout: 3)
    }

    func testModel() {
        if let url = Bundle.main.url(forResource: "test", withExtension: "wav"),
            let data = try? Data(contentsOf: url) {
            assert(WavFile.isWavFormat(data))
            let wavFile = WavFile(data: data)
            assert(wavFile != nil)
            assert(wavFile!.pcmData.during > 0)
            assert(wavFile!.pcmData.byteRate > 0)
            assert(wavFile!.pcmData.blockAlign > 0)
            assert(wavFile!.pcmData.frameLength > 0)

            let decibel = Decibel.getDecibel(data: wavFile!.pcmData.data, channel: wavFile!.header.numChannels, bitsPerSample: wavFile!.header.bitsPerSample)
            assert(decibel.maxValue != 0)
            assert(decibel.avgValue != 0)
        } else {
            assertionFailure()
        }
    }

    func testOpus() {
        if let url = Bundle.main.url(forResource: "test", withExtension: "wav"),
            let data = try? Data(contentsOf: url) {
            assert(OpusUtil.isWavFormat(data))
            let opusData = OpusUtil.encode_wav_data(data)
            assert(opusData != nil)
            let wavData = OpusUtil.decode_opus_data(opusData!)
            assert(wavData != nil)
        } else {
            assertionFailure()
        }
    }

    func recordServiceStart() {
    }

    func recordServiceStop() {
    }

    func onMicrophoneData(_ data: Data) {
    }

    func onPowerData(power: Float32) {
    }
}
