//
//  TestLogin.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/16.
//

import UIKit
import Foundation
import XCTest
@testable import BootManager

class TestLogin: BaseTest {
    let window = UIWindow()
    /// 直接登录
    func testFastloginSuccess() {
        shouldFastLoginTask = false
        BootManager.shared.boot(rootWindow: window)
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask"])
    }

    /// fastlogin失败->LaunchGuide
    func testFastLoginFailure_showLaunchguide() {
        shouldFastLoginTask = true
        BootManager.shared.boot(rootWindow: window)
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask"])
    }
    /// fastlogin失败->end
    func testFastLoginFailure_createTeam_end() {
        shouldFastLoginTask = true
        BootManager.shared.boot(rootWindow: window)
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        let task = workspace.taskRepo.allTasks["LaunchGuideTask"]

        (task as? AsyncLaunchTask)?.end()
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask",
                                "SetupMainTabTask"])
    }

    /// fastlogin失败->createTeam
    func testFastLoginFailure_createTeam() {
        shouldFastLoginTask = true
        shouldGodoCreateTeam = true
        BootManager.shared.boot(rootWindow: window)
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask".checkout,
                                "CreatTeamTask"])
        result.removeAll()
        let task = workspace.taskRepo.allTasks["CreatTeamTask"]
        (task as? AsyncLaunchTask)?.end()
        XCTAssertEqual(result, ["LoginSuccessTask",
                                "SetupMainTabTask"])
    }
    /// fastlogin失败->login
    func testFastLoginFailure_login() {
        shouldFastLoginTask = true
        shouldGodoLogin = true
        BootManager.shared.boot(rootWindow: window)
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask".checkout,
                                "LoginTask"])
        let task = workspace.taskRepo.allTasks["LoginTask"]
        (task as? AsyncLaunchTask)?.end()
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupTeaTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask".checkout,
                                "LoginTask",
                                "LoginSuccessTask",
                                "SetupMainTabTask"])
    }
}

class NewTestLogin: NewBaseTest {
    let window = UIWindow()
    /// 直接登录
    func testFastloginSuccess() {
        shouldFastLoginTask = false
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window)
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask",
                                "SetupUATask",
                                "SetupMainTabTask"])
    }

    /// fastlogin失败->LaunchGuide
    func testFastLoginFailure_showLaunchguide() {
        shouldFastLoginTask = true
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window)
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask"])
    }
    /// fastlogin失败->end
    func testFastLoginFailure_createTeam_end() {
        shouldFastLoginTask = true
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window)
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }
        let task = workspace.taskRepo.allTasks["LaunchGuideTask"]

        (task as? AsyncBootTask)?.end()
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask",
                                "SetupUATask",
                                "SetupMainTabTask"])
    }

    /// fastlogin失败->login
    func testFastLoginFailure_login() {
        shouldFastLoginTask = true
        shouldGodoLogin = true
        shouldWaiteResponse = false
        NewBootManager.shared.boot(rootWindow: window)
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
                                "FastLoginTask".checkout,
                                "LaunchGuideTask".checkout,
                                "SetupUATask",
                                "LoginTask"])
        let task = workspace.taskRepo.allTasks["LoginTask"]
        (task as? AsyncBootTask)?.end()
        XCTAssertEqual(result, ["PrivacyCheckTask",
                                "SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask".checkout,
                                "LaunchGuideTask".checkout,
                                "SetupUATask",
                                "LoginTask",
                                "SetupGuideTask",
                                "SetupMainTabTask"])
    }
}
