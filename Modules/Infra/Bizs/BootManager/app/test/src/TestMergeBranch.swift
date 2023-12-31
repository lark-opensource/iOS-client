//
//  TestMergeBranch.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/15.
//

import UIKit
import Foundation
import XCTest
@testable import BootManager

class NewTestMergeBranch: NewBaseTest {
    let window = UIWindow()
    /// 触发切租户，切成功后，继续master流程
    func testSwitchAccountSuccess() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window)
        guard let context = NewBootManager.shared.connectedContexts.values.first else {
            XCTAssert(false)
            return
        }
        result.removeAll()
        XCTAssertEqual(result, [])
        NewBootManager.shared.context.currentUserID = "test"
        NewBootManager.shared.switchAccount()
        XCTAssertEqual(result, ["SetupGuideTask",
                                "SetupUATask",
                                "SetupMainTabTask"])

        result.removeAll()
        XCTAssertEqual(result, [])
        // 外界触发FirstRender
        NewBootManager.shared.trigger(with: .afterFirstRender, contextID: context.contextID)
        XCTAssertEqual(result, ["SetupDocsTask",
                                "SetupOpenPlatformTask",
                                "ForceTouchTask"])

        result.removeAll()
        XCTAssertEqual(result, [])
        // 外界触发Idle
        NewBootManager.shared.trigger(with: .idle, contextID: context.contextID)
        XCTAssertEqual(result, ["SetupMailTask"])
    }

    /// 手动登录的场景，登录完成后，继续master流程
    func testLogin() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window)
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first else {
            XCTAssert(false)
            return
        }
        result.removeAll()
        XCTAssertEqual(result, [])
        NewBootManager.shared.context.currentUserID = "test"
        NewBootManager.shared.login()
        NewBootManager.shared.context.isFastLogin = false
        XCTAssertEqual(result, ["LoginTask"])
        let task = NewBootManager.shared.launchers[contextID]?.taskRepo.allTasks["LoginTask"]
        // 异步任务停止
        (task as? AsyncBootTask)?.end()
        XCTAssertEqual(result, ["LoginTask",
                                "SetupGuideTask",
                                "SetupDocsTask",
                                "SetupUATask",
                                "SetupOpenPlatformTask",
                                "SetupMailTask",
                                "SetupMainTabTask"]
        )
    }

}
