//
//  TestCheckout.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/15.
//

import UIKit
import Foundation
import XCTest
@testable import BootManager

class TestCheckout: BaseTest {
    let window = UIWindow()

    func testCheckoutPrivacyAlert() {
        shouldPrivacyCheckTask = true
        BootManager.shared.boot(rootWindow: window)
        guard let contextID = BootManager.shared.connectedContexts.keys.first ,
            let workspace = BootManager.shared.workplaces[contextID] else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(result, ["PrivacyCheckTask".checkout,
                                "SetupLoggerTask",
                                "PrivacyBizTask"])
        result.removeAll()
        let task = workspace.taskRepo.allTasks["PrivacyBizTask"]
        // 异步任务停止
        (task as? AsyncLaunchTask)?.end()

        // SetupURLProtocolTask在子线程
        sleep(1)
        XCTAssertEqual(result, ["SetupUATask", "SetupURLProtocolTask"])

        let expect = expectation(description: "Async")
        DispatchQueue.global().asyncAfter(deadline: .now()) {
            let task = workspace.taskRepo.allTasks["SetupURLProtocolTask"]
            // 异步任务停止
            (task as? AsyncLaunchTask)?.end()
            sleep(1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 10)
        XCTAssertEqual(result, ["SetupUATask",
                                "SetupURLProtocolTask",
                                "SetupSlardarTask",
                                "SetupTeaTask",
                                "FastLoginTask",
                                "SetupMainTabTask"])

        (task as? AsyncLaunchTask)?.end()
    }

    func testFastloginFailure() {
        shouldFastLoginTask = true
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
                                "LaunchGuideTask"])
        result.removeAll()

        let task = workspace.taskRepo.allTasks["LaunchGuideTask"]
        // 异步任务停止
        (task as? AsyncLaunchTask)?.branchCheckout()
        XCTAssertEqual(result, ["LoginTask"])

        let task2 = workspace.taskRepo.allTasks["LoginTask"]
        // 异步任务停止
        (task2 as? AsyncLaunchTask)?.end()
        XCTAssertEqual(result, ["LoginTask",
                                "LoginSuccessTask",
                                "SetupMainTabTask"])
    }
}

class NewTestCheckout: NewBaseTest {
    let window = UIWindow()

    func testCheckoutPrivacyAlert() {
        shouldPrivacyCheckTask = true
        NewBootManager.shared.boot(rootWindow: window)
        guard let contextID = NewBootManager.shared.connectedContexts.keys.first ,
            let workspace = NewBootManager.shared.launchers[contextID] else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(result, ["PrivacyCheckTask".checkout,
                                "SetupUATask",
                                "PrivacyBizTask"])
        result.removeAll()
        let task = workspace.taskRepo.allTasks["PrivacyBizTask"]
        // 异步任务停止
        (task as? AsyncBootTask)?.end()

        // SetupURLProtocolTask在子线程
        sleep(1)
        XCTAssertEqual(result, ["SetupSlardarTask", "SetupLoggerTask", "SetupURLProtocolTask"])

        let expect = expectation(description: "Async")
        DispatchQueue.global().asyncAfter(deadline: .now()) {
            let task = workspace.taskRepo.allTasks["SetupURLProtocolTask"]
            // 异步任务停止
            (task as? AsyncBootTask)?.end()
            sleep(1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 10)
        XCTAssertEqual(result, ["SetupSlardarTask",
                                "SetupLoggerTask",
                                "SetupURLProtocolTask",
                                "SettingBundleTask",
                                "FastLoginTask",
                                "SetupMainTabTask"])

        (task as? AsyncBootTask)?.end()
    }

    func testFastloginFailure() {
        shouldFastLoginTask = true
        shouldWaiteResponse = false
        shouldPrivacyCheckTask = false
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
                                "LaunchGuideTask"])
        result.removeAll()

        let task = workspace.taskRepo.allTasks["LaunchGuideTask"]
        // 异步任务停止
        (task as? AsyncBootTask)?.flowCheckout(.loginFlow)
        XCTAssertEqual(result, ["SetupUATask", "LoginTask"])

        let task2 = workspace.taskRepo.allTasks["LoginTask"]
        // 异步任务停止
        (task2 as? AsyncBootTask)?.end()
        XCTAssertEqual(result, ["SetupUATask",
                                "LoginTask",
                                "SetupGuideTask",
                                "SetupMainTabTask"])
    }
}
