//
//  TestVCMetting.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/9/2.
//

import UIKit
import Foundation
import XCTest
@testable import BootManager

class TestVCMetting: BaseTest {
    let window = UIWindow()
    func testVCStage() {
        BootManager.shared.boot(rootWindow: window)
        guard let context = BootManager.shared.connectedContexts.values.first else {
            XCTAssert(false)
            return
        }
        result.removeAll()
        XCTAssertEqual(result, [])
        BootManager.shared.customBoot(branchStage: .vcGuestMeetingStage, stage: .vcGuestMeetingStage, context: context)
        XCTAssertEqual(result, ["SetupDocsTask",
                                "SetupVCTask"])
    }

    func testLaunchGuide() {
        BootManager.shared.boot(rootWindow: window)
        guard let context = BootManager.shared.connectedContexts.values.first else {
            XCTAssert(false)
            return
        }
        result.removeAll()
        XCTAssertEqual(result, [])
        BootManager.shared.launchGuide()
        XCTAssertEqual(result, ["LaunchGuideTask"])
    }
}

class NewTestVCMetting: NewBaseTest {
    let window = UIWindow()
    func testVCStage() {
        NewBootManager.shared.boot(rootWindow: window)
        guard let context = NewBootManager.shared.connectedContexts.values.first else {
            XCTAssert(false)
            return
        }
        result.removeAll()
        XCTAssertEqual(result, [])
        NewBootManager.shared.customBoot(flow: .vcGuestMeetingFlow, context: context)
        XCTAssertEqual(result, [])
    }

    func testLaunchGuide() {
        NewBootManager.shared.boot(rootWindow: window)
        guard let context = NewBootManager.shared.connectedContexts.values.first else {
            XCTAssert(false)
            return
        }
        result.removeAll()
        XCTAssertEqual(result, [])
        NewBootManager.shared.launchGuide()
        XCTAssertEqual(result, ["LaunchGuideTask"])
    }
}
