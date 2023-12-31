//
//  OpusUtilUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/18.
//

import XCTest
import Foundation
import LarkAudioKit // OpusUtil

/// OpusUtil新增单测
final class OpusUtilUnitTest: CanSkipTestCase {
    func testOpus() {
        let audioData = Resources.audioData(named: "1-opus")
        XCTAssertTrue(!OpusUtil.isWavFormat(audioData))
        guard let audioData = OpusUtil.decode_opus_data(audioData) else {
            XCTExpectFailure("opus to wav error")
            return
        }
        XCTAssertTrue(OpusUtil.isWavFormat(audioData))
    }

    func testWav() {
        // WAV是音频封装格式，用来保存PCM（原始数据）等数据
        let audioData = Resources.audioData(named: "1-wav")
        XCTAssertTrue(OpusUtil.isWavFormat(audioData))
        guard let audioData = OpusUtil.encode_wav_data(audioData) else {
            XCTExpectFailure("wav to opus error")
            return
        }
        XCTAssertTrue(!OpusUtil.isWavFormat(audioData))
    }
}
