//
//  TestFirsPageLoad.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/30.
//

import UIKit
import Foundation
import XCTest
@testable import BootManager

class TestFirsPageLoad: BaseTest {
    let window = UIWindow()
    /// 优先启动calendar业务，做首屏数据加载
    func testDocsScope() {
        BootManager.shared.boot(rootWindow: window, firstTab: "calendar")
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        // Preload在子线程，Test判断顺序要依赖时序
        sleep(1)
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask",
                                "CalendarPreloadTask"])

        result.removeAll()

        BootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["ForceTouchTask",
                                "DebugTask",
                                "SetupDocsTask",
                                "SetupVCTask",
                                "SetupOpenPlatformTask",
                                "SetupBDPTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SettingBundleTask",
                                "SetupMailTask"])
    }
}

class NewTestFirsPageLoad: NewBaseTest {
    let window = UIWindow()
    /// 优先启动calendar业务，做首屏数据加载
    func testDocsScope() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window, firstTab: "calendar")
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        // Preload在子线程，Test判断顺序要依赖时序
//        sleep(1)
//        XCTAssertEqual(result, ["PrivacyCheckTask",
//                                "SetupSlardarTask",
//                                "SetupLoggerTask",
//                                "SetupURLProtocolTask",
//                                "SettingBundleTask",
//                                "FastLoginTask",
//                                "CalendarSetupTask",
//                                "SetupUATask",
//                                "SetupMainTabTask"])

        result.removeAll()

        NewBootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["SetupDocsTask",
                                "SetupOpenPlatformTask",
                                "SetupGuideTask",
                                "ForceTouchTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SetupMailTask"])
    }
}
