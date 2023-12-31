//
//  TestDelay.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/15.
//

import UIKit
import Foundation
import XCTest
@testable import BootManager

class TestDelay: BaseTest {
    let window = UIWindow()

    /// 优先启动Docs业务，其余业务延后
    func testDocsScope() {
        BootManager.shared.boot(rootWindow: window, scope: [.docs])
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask",
                                "SetupDocsTask",
                                "SetupBDPTask"])

        result.removeAll()

        BootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["ForceTouchTask",
                                "DebugTask",
                                "SetupVCTask",
                                "SetupOpenPlatformTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SettingBundleTask",
                                "SetupMailTask"])
    }

    /// 优先启动Mail业务，其余业务延后
    func testMailScope() {
        BootManager.shared.boot(rootWindow: window, scope: [.mail])
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask",
                                "SetupMailTask"])
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
        XCTAssertEqual(result, ["SettingBundleTask"])
    }

    /// 优先启动应用中心业务，其余业务延后
    func testAppCenterScope() {
        BootManager.shared.boot(rootWindow: window, scope: [.openplatform])
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask",
                                "SetupOpenPlatformTask",
                                "SetupBDPTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["ForceTouchTask",
                                "DebugTask",
                                "SetupDocsTask",
                                "SetupVCTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SettingBundleTask",
                                "SetupMailTask"])
    }

    // Scope为组合：.appcenter + .docs
    func testDelayOptions() {
        BootManager.shared.boot(rootWindow: window, scope: [.docs, .openplatform])
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask",
                                "SetupDocsTask",
                                "SetupOpenPlatformTask",
                                "SetupBDPTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["ForceTouchTask",
                                "DebugTask",
                                "SetupVCTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SettingBundleTask",
                                "SetupMailTask"])
    }

    /// 延迟任务，立即执行，测试第二次不运行
    func testRumImmediately() {
        BootManager.shared.boot(rootWindow: window, scope: [.openplatform])
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        result.removeAll()
        BootManager.shared.rumImmediately(contextID: contextID, identify: "SetupDocsTask")
        XCTAssertEqual(result, ["SetupDocsTask"])
        result.removeAll()
        BootManager.shared.rumImmediately(contextID: contextID, identify: "SetupVCTask")
        XCTAssertEqual(result, ["SetupVCTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["ForceTouchTask",
                                "DebugTask"])
        result.removeAll()

        BootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SettingBundleTask",
                                "SetupMailTask"])
    }

    /// 启动完成，测试清理任务
    func testClearAll() {
        BootManager.shared.boot(rootWindow: window)
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        BootManager.shared.finished(workspace: workspace)
        XCTAssertEqual(workspace.taskRepo.allTasks.count, 0)
    }

    /// 切租户，测试只清空lifeScope == .container的Task
    func testClearScope() {
        BootManager.shared.boot(rootWindow: window)
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        workspace.context.scope = [.vc]
        workspace.taskRepo.clearUserScopeTask()
        let delays: [LaunchTask] = workspace.taskRepo.delayQueue
        XCTAssertEqual(delays.count, 1)
        XCTAssertEqual(delays.first?.identify, "SetupOpenPlatformTask")
    }
}

class NewTestDelay: NewBaseTest {
    let window = UIWindow()

    /// 优先启动Docs业务，其余业务延后
    func testDocsScope() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window, scope: [.docs])
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask",
                                "SetupDocsTask",
                                "SetupUATask",
                                "SetupMainTabTask"])

        result.removeAll()

        NewBootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["SetupOpenPlatformTask",
                                "SetupGuideTask",
                                "ForceTouchTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SetupMailTask"])
    }

    /// 优先启动Mail业务，其余业务延后
    func testMailScope() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window, scope: [.mail])
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask",
                                "SetupUATask",
                                "SetupMailTask",
                                "SetupMainTabTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["SetupDocsTask",
                                "SetupOpenPlatformTask",
                                "SetupGuideTask",
                                "ForceTouchTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, [])
    }

    /// 优先启动应用中心业务，其余业务延后
    func testAppCenterScope() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window, scope: [.openplatform])
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask",
                                "SetupUATask",
                                "SetupOpenPlatformTask",
                                "SetupMainTabTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["SetupDocsTask",
                                "SetupGuideTask",
                                "ForceTouchTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SetupMailTask"])
    }

    // Scope为组合：.appcenter + .docs
    func testDelayOptions() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window, scope: [.docs, .openplatform])
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask",
                                "SetupDocsTask",
                                "SetupUATask",
                                "SetupOpenPlatformTask",
                                "SetupMainTabTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .afterFirstRender, contextID: contextID)
        XCTAssertEqual(result, ["SetupGuideTask",
                                "ForceTouchTask"])
        result.removeAll()

        NewBootManager.shared.trigger(with: .idle, contextID: contextID)
        XCTAssertEqual(result, ["SetupMailTask"])
    }

    /// 启动完成，测试清理任务
    func testClearAll() {
        NewBootManager.shared.boot(rootWindow: window)
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        NewBootManager.shared.finished(launcher: workspace)
        XCTAssertEqual(workspace.taskRepo.allTasks.count, 0)
    }

    /// 切租户，测试只清空lifeScope == .container的Task
    func testClearScope() {
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window)
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        workspace.context.scope = [.vc]
        workspace.taskRepo.clearUserScopeTask()
        let delays: [BootTask] = workspace.taskRepo.delayTasks
        XCTAssertEqual(delays.count, 1)
        XCTAssertEqual(delays.first?.identify, "SetupOpenPlatformTask")
    }
}
