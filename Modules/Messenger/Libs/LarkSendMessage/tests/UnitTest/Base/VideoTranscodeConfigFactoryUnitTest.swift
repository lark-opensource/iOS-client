//
//  VideoTranscodeConfigFactoryUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import AVFoundation
import LarkSDKInterface // UserGeneralSettings
import LarkContainer // InjectedLazy
import LarkStorage // IsoPath
@testable import LarkSendMessage

/// VideoTranscodeConfigFactory新增单测
final class VideoTranscodeConfigFactoryUnitTest: CanSkipTestCase {
    @InjectedLazy private var generalSettings: UserGeneralSettings

    /// 测试压缩分辨率，覆盖目前所有的策略
    func testVideoTranscodeConfig() {
        // 如果settings没下发完成，不执行用例
        if self.generalSettings.videoSynthesisSetting.value.newCompressSetting.scenes.isEmpty || self.generalSettings.videoSynthesisSetting.value.newCompressSetting.config.isEmpty {
            return
        }

        var strategy = VideoTranscodeStrategy()
        let transcodeFactory = VideoTranscodeConfigFactory(videoSetting: self.generalSettings.videoSynthesisSetting)
        // 自己搞一个临时路径，测试低码率视频
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"; try? tempFilePath.removeItem(); try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
        var result = transcodeFactory.config(strategy: strategy, avasset: AVURLAsset(url: tempFilePath.url))
        XCTAssertEqual(result.compileScene, "low_bitrate")
        XCTAssertEqual(result.compileQuality, "low_bitrate")
        // 测试原画配置
        strategy.isOriginal = true
        result = transcodeFactory.config(strategy: strategy, avasset: nil)
        XCTAssertEqual(result.compileScene, "origin")
        XCTAssertEqual(result.compileQuality, "high")
        // 测试弱网配置
        strategy.isOriginal = false; strategy.isWeakNetwork = true
        result = transcodeFactory.config(strategy: strategy, avasset: nil)
        XCTAssertEqual(result.compileScene, "weak_net")
        XCTAssertEqual(result.compileQuality, "low")
        // 测试默认配置，内部只识别isOriginal、isWeakNetwork、低码率，其他的isForceReencode、isPassthrough不生效
        strategy.isWeakNetwork = false; strategy.isForceReencode = true; strategy.isPassthrough = true
        result = transcodeFactory.config(strategy: strategy, avasset: nil)
        XCTAssertEqual(result.compileScene, "common")
        XCTAssertEqual(result.compileQuality, "middle")
        strategy.isForceReencode = false
        result = transcodeFactory.config(strategy: strategy, avasset: nil)
        XCTAssertEqual(result.compileScene, "common")
        XCTAssertEqual(result.compileQuality, "middle")
        strategy.isPassthrough = false
        result = transcodeFactory.config(strategy: strategy, avasset: nil)
        XCTAssertEqual(result.compileScene, "common")
        XCTAssertEqual(result.compileQuality, "middle")
    }
}
