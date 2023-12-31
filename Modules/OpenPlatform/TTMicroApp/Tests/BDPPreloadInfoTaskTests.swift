//
//  BDPPreloadInfoTaskTests.swift
//  TTMicroApp-Unit-Tests
//
//  Created by laisanpin on 2022/9/23.
//

import Foundation
import XCTest
import OPSDK

@testable import TTMicroApp

class MockPreloadHandleListenerAndInjector: BDPPreloadHandleListener, BDPPreloadHandleInjector, Equatable {
    let identify: String

    var hasMetaCallback = false

    var hasPkgCallback = false

    init(identify: String) {
        self.identify = identify
    }

    static func == (lhs: MockPreloadHandleListenerAndInjector, rhs: MockPreloadHandleListenerAndInjector) -> Bool {
        lhs.identify == rhs.identify
    }

    func onMetaResult(metaResult: OPBizMetaProtocol?, handleInfo: BDPPreloadHandleInfo, error: OPError?, success: Bool) {
        hasMetaCallback = true
    }

    func onPackageResult(success: Bool,  handleInfo: BDPPreloadHandleInfo, error: OPError?) {
        hasPkgCallback = true
    }
}

class BDPPreloadTaskTests: XCTestCase {
    var task: BDPPreloadInfoTask!

    override func setUp() {
        let handleInfo = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_123", identifier: nil, versionType: .current, appType: .gadget), scene: BDPPreloadScene.PreloadPull, scheduleType: .toBeScheduled)

        task = BDPPreloadInfoTask(handleInfo: handleInfo)
    }

    func test_queueIdentifier() {
        // Arrange
        let handleInfo = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_123", identifier: nil, versionType: .current, appType: .gadget), scene: BDPPreloadScene.PreloadPull, scheduleType: .toBeScheduled)

        // Act
        let queueIdentifier = "com.openplatform.preload.type_\(handleInfo.uniqueID.appType.rawValue).scheduleType.\(handleInfo.scheduleType)"

        // Assert
        XCTAssertEqual(queueIdentifier, task.queueIdentifier)
    }


    func test_replaceHanleInfo() {
        // Arrange
        let handleInfoB = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_123", identifier: nil, versionType: .current, appType: .webApp), scene: BDPPreloadScene.PreloadPull, scheduleType: .toBeScheduled)

        // Act
        task.replaceHanleInfo(handleInfoB)

        // Assert
        XCTAssert(task.handleInfo.identifier() == handleInfoB.identifier(), "BDPPreloadHandleInfo replaceHanleInfo failed")
    }

    func test_updateTaskStatus() {
        // Arrange

        // Act
        task.updateTaskStatus(status: .running)

        // Assert
        XCTAssertEqual(task.taskStatus, BDPScheduleTaskStatus.running)
    }

    func test_appendListeners() {
        // Arrange
        let mockListener = MockPreloadHandleListenerAndInjector(identify: "hello world")

        // Act
        task.appendListeners([mockListener])

        // Assert
        XCTAssertTrue(task.listeners.contains(where: { lisenter in
            if let mock = lisenter as? MockPreloadHandleListenerAndInjector {
                return mock == mockListener
            }
            return false
        }))
    }

    func test_appendInjectors() {
        // Arrange
        let mockInjector = MockPreloadHandleListenerAndInjector(identify: "hello world")

        // Act
        task.appendInjectors([mockInjector])

        // Assert
        XCTAssertTrue(task.injectors.contains(where: { lisenter in
            if let mock = lisenter as? MockPreloadHandleListenerAndInjector {
                return mock == mockInjector
            }
            return false
        }))
    }

    func test_onAllMetaResult() {
        // Arrange
        let mockListener = MockPreloadHandleListenerAndInjector(identify: "hello world")
        task.appendListeners([mockListener])

        // Act
        task.onAllMetaResult(metaResult: nil, handleInfo: task.handleInfo, error: nil, success: true)

        // Assert
        XCTAssertTrue(mockListener.hasMetaCallback)
    }

    func test_onAllPackageResult() {
        // Arrange
        let mockListener = MockPreloadHandleListenerAndInjector(identify: "hello world")
        task.appendListeners([mockListener])

        // Act
        task.onAllPackageResult(success: true, handleInfo: task.handleInfo, error: nil)

        // Assert
        XCTAssertTrue(mockListener.hasPkgCallback)
    }
}
