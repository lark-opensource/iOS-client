//
//  BootTest.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/12.
//

import UIKit
import Foundation
import XCTest
@testable import BootManager

class BootTest: BaseTest {
    let window = UIWindow()
    func testBoot() {
        /// master路径启动
        BootManager.shared.boot(rootWindow: window)
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask"])

        result.removeAll()
        XCTAssertEqual(result, [])
        // 外界触发FirstRender
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        BootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["ForceTouchTask",
                                "DebugTask",
                                "SetupDocsTask",
                                "SetupVCTask",
                                "SetupOpenPlatformTask",
                                "SetupBDPTask"])

        result.removeAll()
        XCTAssertEqual(result, [])
        // 外界触发Idle
        BootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SettingBundleTask", "SetupMailTask"])

        XCTAssertEqual(workspace.taskRepo.allTasks.count, 0)
        XCTAssertEqual(BootManager.shared.globalTaskRepo.deamonTasks.count, 1)

        BootManager.shared.removeDeamonTask(SetupSlardarTask.identify)
        XCTAssertEqual(BootManager.shared.globalTaskRepo.deamonTasks.count, 0)
    }
}

class NewBootTest: NewBaseTest {
    let window = UIWindow()
    func testBoot() {
        /// master路径启动
        NewBootManager.shared.boot(rootWindow: window)
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask"])

        result.removeAll()
        XCTAssertEqual(result, [])
        // 外界触发FirstRender
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        NewBootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["SetupGuideTask",
                                "ForceTouchTask",
                                "SettingBundleTask",
                                "FastLoginTask",
                                "SetupUATask",
                                "SetupMainTabTask"])

        result.removeAll()
        XCTAssertEqual(result, [])
        // 外界触发Idle
        NewBootManager.shared.trigger(with: .idle, contextID: contextID)

        XCTAssertEqual(workspace.taskRepo.allTasks.count, 0)
        XCTAssertEqual(NewBootManager.shared.globalTaskRepo.deamonTasks.count, 1)

        NewBootManager.shared.removeDeamonTask(NewSetupSlardarTask.identify)
        XCTAssertEqual(NewBootManager.shared.globalTaskRepo.deamonTasks.count, 0)
    }
}
