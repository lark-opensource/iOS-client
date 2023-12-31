//
//  LegacyFolderUserPermissionTests.swift
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

final class LegacyFolderUserPermissionTests: XCTestCase {

    typealias Role = LegacyFolderUserPermission.PermissionRole

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testSatisfy() {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .share(spaceID: "", isRoot: false, ownerID: nil))
        var permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: false, role: .none)
        XCTAssertTrue(permission.satisfy(role: .none))
        XCTAssertFalse(permission.satisfy(role: .viewer))
        XCTAssertFalse(permission.satisfy(role: .editor))

        permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: false, role: .viewer)
        XCTAssertTrue(permission.satisfy(role: .none))
        XCTAssertTrue(permission.satisfy(role: .viewer))
        XCTAssertFalse(permission.satisfy(role: .editor))

        permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: false, role: .editor)
        XCTAssertTrue(permission.satisfy(role: .none))
        XCTAssertTrue(permission.satisfy(role: .viewer))
        XCTAssertTrue(permission.satisfy(role: .editor))
    }

    func testComparePermissionRole() {
        XCTAssertGreaterThan(Role.viewer, Role.none)
        XCTAssertGreaterThan(Role.editor, Role.viewer)
        XCTAssertGreaterThan(Role.editor, Role.none)

        XCTAssertLessThan(Role.none, Role.viewer)
        XCTAssertLessThan(Role.none, Role.editor)
        XCTAssertLessThan(Role.viewer, Role.editor)

        XCTAssertEqual(Role.viewer, Role.viewer)
        XCTAssertEqual(Role.editor, Role.editor)
        XCTAssertEqual(Role.none, Role.none)
    }
}
