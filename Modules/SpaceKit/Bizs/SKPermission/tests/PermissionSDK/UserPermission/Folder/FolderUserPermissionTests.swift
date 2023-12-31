//
//  FolderUserPermissionTests.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/23.
//

import Foundation
import XCTest
@testable import SKPermission
import SKFoundation
import SpaceInterface
import SwiftyJSON

final class FolderUserPermissionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testIsOwner() {
        var permission = FolderUserPermission(actions: [:], isOwner: true)
        XCTAssertTrue(permission.isOwner)

        permission = FolderUserPermission(actions: [:], isOwner: false)
        XCTAssertFalse(permission.isOwner)
    }

    func testCheckAction() {
        var actionValues: [String: Int] = [:]
        let allActions = FolderUserPermission.Action.allCases
        allActions.forEach { action in
            actionValues[action.rawValue] = FolderUserPermission.rightCode
        }
        var permission = FolderUserPermission(actions: actionValues, isOwner: true)
        allActions.forEach { action in
            XCTAssertTrue(permission.check(action: action))
        }

        permission = FolderUserPermission(actions: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertFalse(permission.check(action: action))
        }

        actionValues = [:]
        allActions.forEach { action in
            actionValues[action.rawValue] = FolderUserPermission.blockByCACCode
        }
        permission = FolderUserPermission(actions: actionValues, isOwner: true)
        allActions.forEach { action in
            XCTAssertFalse(permission.check(action: action))
        }
    }

    func testDenyReason() {
        let allActions = FolderUserPermission.Action.allCases

        var permission = FolderUserPermission(actions: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertEqual(permission.denyReason(for: action), .unknown)
        }

        var actionValues: [String: Int] = [:]
        allActions.forEach { action in
            actionValues[action.rawValue] = FolderUserPermission.rightCode
        }
        permission = FolderUserPermission(actions: actionValues, isOwner: true)
        allActions.forEach { action in
            XCTAssertNil(permission.denyReason(for: action))
        }

        actionValues = [:]
        allActions.forEach { action in
            actionValues[action.rawValue] = FolderUserPermission.blockByCACCode
        }
        permission = FolderUserPermission(actions: actionValues, isOwner: true)
        allActions.forEach { action in
            XCTAssertEqual(permission.denyReason(for: action), .blockByCAC)
        }

        actionValues = [:]
        allActions.forEach { action in
            // 注意绕开其他可能有明确含义的值
            actionValues[action.rawValue] = Int.random(in: 100...200)
        }
        permission = FolderUserPermission(actions: actionValues, isOwner: true)
        allActions.forEach { action in
            XCTAssertEqual(permission.denyReason(for: action),
                           .blockByServer(code: actionValues[action.rawValue]!))
        }
    }

    func testRootFolder() {
        let permission = FolderUserPermission.personalRootFolder
        FolderUserPermission.Action.allCases.forEach { action in
            XCTAssertTrue(permission.check(action: action))
            XCTAssertNil(permission.denyReason(for: action))
        }
    }
}
