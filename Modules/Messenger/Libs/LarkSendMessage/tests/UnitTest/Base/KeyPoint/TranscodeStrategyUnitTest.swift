//
//  TranscodeStrategyUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import UIKit
import XCTest
import Foundation
import LarkSDKInterface // UserGeneralSettings
import LarkContainer // InjectedLazy
import LarkFileKit // Path
import LarkStorage // IsoPath
@testable import LarkSendMessage

/// TranscodeStrategy新增单测
final class TranscodeStrategyUnitTest: CanSkipTestCase {
    @InjectedLazy private var generalSettings: UserGeneralSettings

    /// 测试压缩分辨率，覆盖目前所有的策略
    func testAdjustVideoSize() {
        // 如果settings没下发完成，不执行用例
        if self.generalSettings.videoSynthesisSetting.value.newCompressSetting.scenes.isEmpty || self.generalSettings.videoSynthesisSetting.value.newCompressSetting.config.isEmpty {
            return
        }

        let transcodeStrategy = VideoTranscodeStrategyImpl(userResolver: Container.shared.getCurrentUserResolver(), videoSetting: self.generalSettings.videoSynthesisSetting)
        var strategy = VideoTranscodeStrategy()
        XCTAssertEqual(transcodeStrategy.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
        strategy.isOriginal = true
        XCTAssertEqual(transcodeStrategy.adjustVideoSize(CGSize(width: 2000, height: 2000), strategy: strategy), CGSize(width: 1280, height: 1280))
        strategy.isOriginal = false; strategy.isForceReencode = true
        XCTAssertEqual(transcodeStrategy.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
        strategy.isForceReencode = false; strategy.isWeakNetwork = true
        XCTAssertEqual(transcodeStrategy.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
        strategy.isWeakNetwork = false; strategy.isPassthrough = true
        XCTAssertEqual(transcodeStrategy.adjustVideoSize(CGSize(width: 1280, height: 1280), strategy: strategy), CGSize(width: 960, height: 960))
    }

    /// 测试获取文件格式
    func testFileFormat() {
        // 自己搞一个沙盒路径，不然Path().exists会为false
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"; try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4" //; try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "10-540x960-mp4").write(to: tempFilePath)
        XCTAssertEqual(self.fileFormat(from: tempFilePath.absoluteString), "mpeg4")
        try? tempFilePath.removeItem()
        try? Resources.mediaData(named: "20-1080x1920-mov").write(to: tempFilePath)
        XCTAssertEqual(self.fileFormat(from: tempFilePath.absoluteString), "mov")
        // 非视频格式统一为unknown
        XCTAssertEqual(self.fileFormat(from: Resources.audioUrl(named: "1-opus").absoluteString), "unknown")
        XCTAssertEqual(self.fileFormat(from: Resources.imageUrl(named: "1170x2532-PNG").absoluteString), "unknown")
        XCTAssertEqual(self.fileFormat(from: Resources.imageUrl(named: "1200x1400-JPEG").absoluteString), "unknown")
        XCTAssertEqual(self.fileFormat(from: Resources.imageUrl(named: "300x400-GIF").absoluteString), "unknown")
    }

    /// 从Data层面获取视频格式，不从文件后缀名判断
    private func fileFormat(from: String) -> String {
        let inputStream = Path(from).inputStream()
        inputStream?.open()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 2048)

        defer {
            buffer.deallocate()
            inputStream?.close()
        }

        // 异常情况按照unknown处理
        guard let read = inputStream?.read(buffer, maxLength: 2048), read > 0 else {
            return "unknown"
        }
        var data = Data()
        data.append(buffer, count: read)
        // 判断格式
        switch data.lf.fileFormat() {
            // 只处理视频格式
        case .video(let format): return format.rawValue
            // 其他格式一律按照unknown处理
        default: return "unknown"
        }
    }
}
