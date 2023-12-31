//
//  DocumentUserPermissionTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/20.
//

import Foundation
import XCTest
@testable import SKPermission
import SKFoundation
import SpaceInterface
import SwiftyJSON

extension DocumentUserPermission {
    init(actions: [String: Int], authReasons: [String: Int], isOwner: Bool) {
        self.init(actions: actions, authReasons: authReasons, isOwner: isOwner, statusCode: .normal)
    }
}

final class DocumentUserPermissionTests: XCTestCase {

    private typealias Action = DocumentUserPermission.Action
    private typealias ComposeAction = DocumentUserPermission.ComposeAction
    private typealias AuthReason = DocumentUserPermission.AuthReason

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testIsOwner() {
        var permission = DocumentUserPermission(actions: [:], authReasons: [:], isOwner: true)
        XCTAssertTrue(permission.isOwner)

        permission = DocumentUserPermission(actions: [:], authReasons: [:], isOwner: false)
        XCTAssertFalse(permission.isOwner)
    }

    func testCheckAction() {
        var actionValues: [String: Int] = [:]
        let allActions = DocumentUserPermission.Action.allCases
        allActions.forEach { action in
            actionValues[action.rawValue] = DocumentUserPermission.rightCode
        }
        var permission = DocumentUserPermission(actions: actionValues, authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertTrue(permission.check(action: action))
        }

        permission = DocumentUserPermission(actions: [:], authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertFalse(permission.check(action: action))
        }

        actionValues = [:]
        allActions.forEach { action in
            actionValues[action.rawValue] = DocumentUserPermission.blockByCACCode
        }
        permission = DocumentUserPermission(actions: actionValues, authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertFalse(permission.check(action: action))
        }
    }

    func testPreviewBlockByAdmin() {
        var actions: [String: Int] = [
            Action.perceive.rawValue: 1,
            Action.view.rawValue: 2
        ]
        var permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        XCTAssertTrue(permission.previewBlockByAdmin)

        actions = [
            Action.perceive.rawValue: 1,
            Action.view.rawValue: 1
        ]
        permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        XCTAssertFalse(permission.previewBlockByAdmin)

        actions = [
            Action.perceive.rawValue: 2,
            Action.view.rawValue: 1
        ]
        permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        XCTAssertFalse(permission.previewBlockByAdmin)

        actions = [
            Action.perceive.rawValue: 2,
            Action.view.rawValue: 2
        ]
        permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        XCTAssertFalse(permission.previewBlockByAdmin)
    }

    func testDenyReason() {
        let allActions = DocumentUserPermission.Action.allCases

        var permission = DocumentUserPermission(actions: [:], authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertEqual(permission.denyReason(for: action), .normal(denyReason: .unknown))
        }

        var actionValues: [String: Int] = [:]
        allActions.forEach { action in
            actionValues[action.rawValue] = DocumentUserPermission.rightCode
        }
        permission = DocumentUserPermission(actions: actionValues, authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertNil(permission.denyReason(for: action))
        }

        actionValues = [:]
        allActions.forEach { action in
            actionValues[action.rawValue] = DocumentUserPermission.blockByCACCode
        }
        permission = DocumentUserPermission(actions: actionValues, authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertEqual(permission.denyReason(for: action), .normal(denyReason: .blockByCAC))
        }

        actionValues = [:]
        allActions.forEach { action in
            // 注意绕开其他可能有明确含义的值
            actionValues[action.rawValue] = Int.random(in: 100...200)
        }
        permission = DocumentUserPermission(actions: actionValues, authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertEqual(permission.denyReason(for: action),
                           .normal(denyReason: .blockByServer(code: actionValues[action.rawValue]!)))
        }

        // blockByAdmin 检查
        actionValues = [
            Action.perceive.rawValue: 1,
            Action.preview.rawValue: 2,
            Action.view.rawValue: 2
        ]
        permission = DocumentUserPermission(actions: actionValues, authReasons: [:], isOwner: true)
        XCTAssertEqual(permission.denyReason(for: .preview), .previewBlockBySecurityAudit)
    }

    func testAuthReason() {
        let allActions = DocumentUserPermission.Action.allCases
        let permission = DocumentUserPermission(actions: [:], authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertNil(permission.authReason(for: action))
        }

        func assert(reasonValue: Int, reason: DocumentUserPermission.AuthReason,
                    file: StaticString = #file, line: UInt = #line) {
            var authReasons: [String: Int] = [:]
            allActions.forEach { action in
                authReasons[action.rawValue] = reasonValue
            }
            let permission = DocumentUserPermission(actions: [:], authReasons: authReasons, isOwner: true)
            allActions.forEach { action in
                let reason = permission.authReason(for: action)
                XCTAssertEqual(reason, reason, file: file, line: line)
                XCTAssertEqual(reason?.rawValue, reasonValue, file: file, line: line)
            }
        }

        assert(reasonValue: 0, reason: .collaborator)
        assert(reasonValue: 100000, reason: .leaderCanCopyPreference)
        assert(reasonValue: 100003, reason: .leaderCanManagePreference)
        assert(reasonValue: 150000, reason: .shareByLink)
        assert(reasonValue: -1, reason: .unknown(code: -1))
    }

    func testManageCollaboratorComposeAction() {
        // 只有容器权限
        var actions: [String: Int] = [
            Action.manageContainerCollaborator.rawValue: 1,
            Action.manageSinglePageCollaborator.rawValue: 2
        ]
        var reasons: [String: Int] = [
            Action.manageContainerCollaborator.rawValue: 0
        ]
        var permission = DocumentUserPermission(actions: actions,
                                                authReasons: reasons,
                                                isOwner: false)
        XCTAssertTrue(permission.check(action: .manageCollaborator))
        XCTAssertEqual(permission.authReason(for: .manageCollaborator), .collaborator)
        XCTAssertNil(permission.denyReason(for: .manageCollaborator))
        // 只有单页面权限
        actions = [
            Action.manageContainerCollaborator.rawValue: 2,
            Action.manageSinglePageCollaborator.rawValue: 1
        ]
        reasons = [
            Action.manageSinglePageCollaborator.rawValue: 0
        ]
        permission = DocumentUserPermission(actions: actions,
                                            authReasons: reasons,
                                            isOwner: false)
        XCTAssertTrue(permission.check(action: .manageCollaborator))
        XCTAssertEqual(permission.authReason(for: .manageCollaborator), .collaborator)
        XCTAssertNil(permission.denyReason(for: .manageCollaborator))

        // 两个都有
        actions = [
            Action.manageContainerCollaborator.rawValue: 1,
            Action.manageSinglePageCollaborator.rawValue: 1
        ]
        reasons = [
            Action.manageContainerCollaborator.rawValue: AuthReason.shareByLink.rawValue,
            Action.manageSinglePageCollaborator.rawValue: AuthReason.collaborator.rawValue
        ]
        permission = DocumentUserPermission(actions: actions,
                                            authReasons: reasons,
                                            isOwner: false)
        XCTAssertTrue(permission.check(action: .manageCollaborator))
        // 优先用 container 的
        XCTAssertEqual(permission.authReason(for: .manageCollaborator), .shareByLink)
        XCTAssertNil(permission.denyReason(for: .manageCollaborator))

        // 两个都没
        actions = [
            Action.manageContainerCollaborator.rawValue: 2002,
            Action.manageSinglePageCollaborator.rawValue: 100
        ]
        reasons = [
            :
        ]
        permission = DocumentUserPermission(actions: actions,
                                            authReasons: reasons,
                                            isOwner: false)
        XCTAssertFalse(permission.check(action: .manageCollaborator))
        XCTAssertNil(permission.authReason(for: .manageCollaborator))
        // 优先用 container 的
        XCTAssertEqual(permission.denyReason(for: .manageCollaborator), .normal(denyReason: .blockByCAC))
    }

    func testManagePermissionMetaComposeAction() {
        // 只有容器权限
        var actions: [String: Int] = [
            Action.manageContainerMeta.rawValue: 1,
            Action.manageSinglePageMeta.rawValue: 2
        ]
        var reasons: [String: Int] = [
            Action.manageContainerMeta.rawValue: 0
        ]
        var permission = DocumentUserPermission(actions: actions,
                                                authReasons: reasons,
                                                isOwner: false)
        XCTAssertTrue(permission.check(action: .managePermissionMeta))
        XCTAssertEqual(permission.authReason(for: .managePermissionMeta), .collaborator)
        XCTAssertNil(permission.denyReason(for: .managePermissionMeta))
        // 只有单页面权限
        actions = [
            Action.manageContainerMeta.rawValue: 2,
            Action.manageSinglePageMeta.rawValue: 1
        ]
        reasons = [
            Action.manageSinglePageMeta.rawValue: 0
        ]
        permission = DocumentUserPermission(actions: actions,
                                            authReasons: reasons,
                                            isOwner: false)
        XCTAssertTrue(permission.check(action: .managePermissionMeta))
        XCTAssertEqual(permission.authReason(for: .managePermissionMeta), .collaborator)
        XCTAssertNil(permission.denyReason(for: .managePermissionMeta))

        // 两个都有
        actions = [
            Action.manageContainerMeta.rawValue: 1,
            Action.manageSinglePageMeta.rawValue: 1
        ]
        reasons = [
            Action.manageContainerMeta.rawValue: AuthReason.shareByLink.rawValue,
            Action.manageSinglePageMeta.rawValue: AuthReason.collaborator.rawValue
        ]
        permission = DocumentUserPermission(actions: actions,
                                            authReasons: reasons,
                                            isOwner: false)
        XCTAssertTrue(permission.check(action: .managePermissionMeta))
        // 优先用 container 的
        XCTAssertEqual(permission.authReason(for: .managePermissionMeta), .shareByLink)
        XCTAssertNil(permission.denyReason(for: .managePermissionMeta))

        // 两个都没
        actions = [
            Action.manageContainerMeta.rawValue: 2002,
            Action.manageSinglePageMeta.rawValue: 100
        ]
        reasons = [
            :
        ]
        permission = DocumentUserPermission(actions: actions,
                                            authReasons: reasons,
                                            isOwner: false)
        XCTAssertFalse(permission.check(action: .managePermissionMeta))
        XCTAssertNil(permission.authReason(for: .managePermissionMeta))
        // 优先用 container 的
        XCTAssertEqual(permission.denyReason(for: .managePermissionMeta), .normal(denyReason: .blockByCAC))
    }

    // MARK: - ComposeAction
    func testAnd() {
        var result = Action.preview & Action.export
        XCTAssertEqual(result, .and(lhs: .single(action: .preview), rhs: .single(action: .export)))
        result = result & Action.download
        XCTAssertEqual(result,
                       .and(lhs: .and(lhs: .single(action: .preview),
                                      rhs: .single(action: .export)),
                            rhs: .single(action: .download))
        )

        result = Action.copy & result
        XCTAssertEqual(result,
                       .and(lhs: .single(action: .copy),
                            rhs: .and(lhs: .and(lhs: .single(action: .preview),
                                                rhs: .single(action: .export)),
                                      rhs: .single(action: .download)))
        )

        result = (Action.preview & Action.export) & (Action.download & Action.copy)
        XCTAssertEqual(result,
                       .and(lhs: .and(lhs: .single(action: .preview),
                                      rhs: .single(action: .export)),
                            rhs: .and(lhs: .single(action: .download),
                                      rhs: .single(action: .copy)))
        )
    }

    func testOr() {
        var result = Action.preview | Action.export
        XCTAssertEqual(result, .or(lhs: .single(action: .preview), rhs: .single(action: .export)))
        result = result | Action.download
        XCTAssertEqual(result,
                       .or(lhs: .or(lhs: .single(action: .preview),
                                    rhs: .single(action: .export)),
                           rhs: .single(action: .download))
        )

        result = Action.copy | result
        XCTAssertEqual(result,
                       .or(lhs: .single(action: .copy),
                           rhs: .or(lhs: .or(lhs: .single(action: .preview),
                                             rhs: .single(action: .export)),
                                    rhs: .single(action: .download)))
        )

        result = (Action.preview | Action.export) | (Action.download | Action.copy)
        XCTAssertEqual(result,
                       .or(lhs: .or(lhs: .single(action: .preview),
                                    rhs: .single(action: .export)),
                           rhs: .or(lhs: .single(action: .download),
                                    rhs: .single(action: .copy)))
        )
    }

    func testCheckComposeAction() {
        var actions: [String: Int] = [
            Action.manageContainerMeta.rawValue: 1,
            Action.manageSinglePageMeta.rawValue: 2
        ]
        var permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        XCTAssertTrue(permission.check(action: .single(action: .manageContainerMeta)))
        XCTAssertFalse(permission.check(action: .single(action: .manageSinglePageMeta)))
        XCTAssertTrue(permission.check(action: Action.manageContainerMeta | Action.manageSinglePageMeta))
        XCTAssertFalse(permission.check(action: Action.manageContainerMeta & Action.manageSinglePageMeta))
    }

    func testDenyReasonForComposeAction() {
        var actions: [String: Int] = [
            Action.manageContainerMeta.rawValue: 1,
            Action.manageSinglePageMeta.rawValue: 2,
            Action.preview.rawValue: 3
        ]
        var permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        XCTAssertNil(permission.denyReason(for: Action.manageContainerMeta | Action.manageSinglePageMeta))
        XCTAssertEqual(permission.denyReason(for: Action.manageContainerMeta & Action.manageSinglePageMeta),
                       .normal(denyReason: .blockByServer(code: 2)))
        XCTAssertEqual(permission.denyReason(for: .single(action: .manageSinglePageMeta)),
                       .normal(denyReason: .blockByServer(code: 2)))
        XCTAssertEqual(permission.denyReason(for: Action.preview | Action.manageSinglePageMeta),
                       .normal(denyReason: .blockByServer(code: 3)))
    }

    func testAuthReasonForComposeAction() {
        let allActions = DocumentUserPermission.Action.allCases
        var permission = DocumentUserPermission(actions: [:], authReasons: [:], isOwner: true)
        allActions.forEach { action in
            XCTAssertNil(permission.authReason(for: .single(action: action)))
        }

        permission = DocumentUserPermission(actions: [:],
                                            authReasons: [
                                                Action.manageSinglePageMeta.rawValue: 100003,
                                                Action.copy.rawValue: 100000
                                            ],
                                            isOwner: false)
        XCTAssertEqual(permission.authReason(for: Action.copy | Action.manageSinglePageMeta),
                       .leaderCanCopyPreference)
        XCTAssertEqual(permission.authReason(for: Action.copy & Action.manageSinglePageMeta),
                       .leaderCanCopyPreference)
        XCTAssertEqual(permission.authReason(for: .single(action: .copy)),
                       .leaderCanCopyPreference)
    }
}
