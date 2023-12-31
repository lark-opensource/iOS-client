//
//  VideoParseTaskUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/6.
//

import XCTest
import Foundation
import Photos
import RxSwift // DisposeBag
import LarkContainer // InjectedLazy
import LarkSDKInterface // UserGeneralSettings
@testable import LarkSendMessage

/// VideoParseTask新增单测
class VideoParseTaskUnitTest: CanSkipTestCase {
    @InjectedLazy private var generalSettings: UserGeneralSettings
    @InjectedLazy private var transcodeService: VideoTranscodeService
    private lazy var videoSendSetting = self.generalSettings.videoSynthesisSetting.value.sendSetting

    /// 测试resourceID获取
    func testResourceID() {
        // swiftlint:disable force_try
        let urlTask = try! VideoParseTask(userResolver: Container.shared.getCurrentUserResolver(), data: .fileURL(URL(fileURLWithPath: "")), isOriginal: false, type: .normal,
                                     transcodeService: self.transcodeService, videoSendSetting: self.videoSendSetting,
                                     taskID: SendVideoLogger.IDGenerator.uniqueID)
        XCTAssertFalse(urlTask.resourceID().isEmpty)
        let assetTask = try! VideoParseTask(userResolver: Container.shared.getCurrentUserResolver(), data: .asset(PHAsset()), isOriginal: false, type: .normal,
                                       transcodeService: self.transcodeService, videoSendSetting: self.videoSendSetting,
                                       taskID: SendVideoLogger.IDGenerator.uniqueID)
        XCTAssertFalse(assetTask.resourceID().isEmpty)
        XCTAssertFalse((assetTask.resourceID() ?? "").contains("origin_"))
        let assetOriginTask = try! VideoParseTask(userResolver: Container.shared.getCurrentUserResolver(), data: .asset(PHAsset()), isOriginal: true, type: .normal,
                                             transcodeService: self.transcodeService,
                                             videoSendSetting: self.videoSendSetting,
                                             taskID: SendVideoLogger.IDGenerator.uniqueID)
        XCTAssertFalse(assetOriginTask.resourceID().isEmpty)
        XCTAssertTrue((assetOriginTask.resourceID() ?? "").contains("origin_"))
        // swiftlint:enable force_try
    }
}
