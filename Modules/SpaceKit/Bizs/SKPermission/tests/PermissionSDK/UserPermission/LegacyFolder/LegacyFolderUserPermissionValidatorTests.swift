//
//  LegacyFolderUserPermissionValidatorTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/25.
//

import Foundation
import XCTest
@testable import SKPermission
import SKFoundation
import SpaceInterface
import SKResource

final class LegacyFolderUserPermissionValidatorTests: XCTestCase {

    private typealias Role = LegacyFolderUserPermission.PermissionRole

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testShouldInvoke() {
        let validator = LegacyFolderUserPermissionValidator(model: nil, isFromCache: false)

        var rules = PermissionExemptRules(shouldCheckFileStrategy: true,
                                          shouldCheckDLP: true,
                                          shouldCheckSecurityAudit: true,
                                          shouldCheckUserPermission: false)
        XCTAssertFalse(validator.shouldInvoke(rules: rules))

        rules = PermissionExemptRules(shouldCheckFileStrategy: false,
                                          shouldCheckDLP: false,
                                          shouldCheckSecurityAudit: false,
                                          shouldCheckUserPermission: true)
        XCTAssertTrue(validator.shouldInvoke(rules: rules))
    }

    func testPermissionNoReady() {
        let validator = LegacyFolderUserPermissionValidator(model: nil, isFromCache: false)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .moveToHere,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        let response = validator.validate(request: request)
        response.assertEqual(denyType: .blockByUserPermission(reason: .userPermissionNotReady))
        response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                                  allowOverrideMessage: true))

        var asyncFlag = false
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockByUserPermission(reason: .userPermissionNotReady))
            response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                                      allowOverrideMessage: true))
            asyncFlag = true
        }
        XCTAssertTrue(asyncFlag)
    }

    private func assertAllow(operation: PermissionRequest.Operation,
                             role: Role,
                             file: StaticString = #file,
                             line: UInt = #line) {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN",
                                           folderType: .share(spaceID: "MOCK_SPACE_ID", isRoot: false, ownerID: nil))
        let permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: false, role: role)
        let validator = LegacyFolderUserPermissionValidator(model: permission, isFromCache: false)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: operation,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        let response = validator.validate(request: request)
        response.assertAllow(file: file, line: line)
        var asyncFlag = false
        validator.asyncValidate(request: request) { response in
            response.assertAllow(file: file, line: line)
            asyncFlag = true
        }
        XCTAssertTrue(asyncFlag, file: file, line: line)
    }

    private func assertForbidden(operation: PermissionRequest.Operation,
                                 role: Role,
                                 denyType expectDenyType: PermissionResponse.DenyType,
                                 behaviorType expectBehaviorType: PermissionDefaultUIBehaviorType,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN",
                                           folderType: .share(spaceID: "MOCK_SPACE_ID", isRoot: false, ownerID: nil))
        let permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: false, role: role)
        let validator = LegacyFolderUserPermissionValidator(model: permission, isFromCache: false)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: operation,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        let response = validator.validate(request: request)
        response.assertEqual(denyType: expectDenyType, file: file, line: line)
        response.assertEqual(behaviorType: expectBehaviorType, file: file, line: line)
        var asyncFlag = false
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: expectDenyType, file: file, line: line)
            response.assertEqual(behaviorType: expectBehaviorType, file: file, line: line)
            asyncFlag = true
        }
        XCTAssertTrue(asyncFlag, file: file, line: line)
    }

    private func batchAssert(operation: PermissionRequest.Operation,
                             role requirement: Role,
                             errorMessage: String = BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                             file: StaticString = #file,
                             line: UInt = #line) {
        Role.allCases.forEach { role in
            if role >= requirement {
                assertAllow(operation: operation, role: role, file: file, line: line)
            } else {
                assertForbidden(operation: operation,
                                role: role,
                                denyType: .blockByUserPermission(reason: .unknown),
                                behaviorType: .error(text: errorMessage,
                                                     allowOverrideMessage: true),
                                file: file,
                                line: line)
            }
        }
    }

    func testValidateNormalOperation() {
        let simpleActions: [(PermissionRequest.Operation, Role)] = [
            (.view, .viewer), // MARK_OFFSET_START
            (.edit, .editor),
            (.inviteEdit, .editor),
            (.inviteView, .viewer),
            (.moveThisNode, .editor),
            (.moveToHere, .editor),
            (.moveSubNode, .editor),
            (.createSubNode, .editor)
        ]
        for (index, (operation, role)) in simpleActions.enumerated() {
            let assertLineOffset: UInt = UInt(simpleActions.count + 3 - index) // 让test失败显示到上面
            batchAssert(operation: operation, role: role, line: #line - assertLineOffset) // MARK_OFFSET_END
        }
    }

    func testInviteFullAccess() {
        // 不区分角色，都不允许
        assertForbidden(operation: .inviteFullAccess,
                        role: .viewer,
                        denyType: .blockByUserPermission(reason: .unknown),
                        behaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                             allowOverrideMessage: true))
        assertForbidden(operation: .inviteFullAccess,
                        role: .editor,
                        denyType: .blockByUserPermission(reason: .unknown),
                        behaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                             allowOverrideMessage: true))
        assertForbidden(operation: .inviteFullAccess,
                        role: .none,
                        denyType: .blockByUserPermission(reason: .unknown),
                        behaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                             allowOverrideMessage: true))
    }

    func testManageCollaborator() {
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .folder,
                                        operation: .manageCollaborator,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        var folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN",
                                           folderType: .personal)
        var roles: [Role] = [.none, .viewer, .editor]
        roles.forEach { role in
            let permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: true, role: role)
            let validator = LegacyFolderUserPermissionValidator(model: permission, isFromCache: false)
            let response = validator.validate(request: request)
            response.assertAllow()
            let asyncExpect = expectation(description: "async validate personal folder can manage collaborator with role: \(role)")
            validator.asyncValidate(request: request) { response in
                response.assertAllow()
                asyncExpect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }

        folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .share(spaceID: "", isRoot: false, ownerID: nil))
        roles = [.none, .viewer, .editor]
        roles.forEach { role in
            let permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: true, role: role)
            let validator = LegacyFolderUserPermissionValidator(model: permission, isFromCache: false)
            let response = validator.validate(request: request)
            response.assertEqual(denyType: .blockByUserPermission(reason: .unknown))
            let asyncExpect = expectation(description: "async validate nont root share folder can manage collaborator with role: \(role)")
            validator.asyncValidate(request: request) { response in
                response.assertEqual(denyType: .blockByUserPermission(reason: .unknown))
                asyncExpect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }

        folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .share(spaceID: "", isRoot: true, ownerID: nil))
        roles = [.viewer, .editor]
        roles.forEach { role in
            let permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: true, role: role)
            let validator = LegacyFolderUserPermissionValidator(model: permission, isFromCache: false)
            let response = validator.validate(request: request)
            response.assertAllow()
            let asyncExpect = expectation(description: "async validate nont root share folder can manage collaborator with role: \(role)")
            validator.asyncValidate(request: request) { response in
                response.assertAllow()
                asyncExpect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }

        let permission = LegacyFolderUserPermission(folderInfo: folderInfo, isOwner: true, role: .none)
        let validator = LegacyFolderUserPermissionValidator(model: permission, isFromCache: false)
        let response = validator.validate(request: request)
        response.assertEqual(denyType: .blockByUserPermission(reason: .unknown))
        let asyncExpect = expectation(description: "async validate nont root share folder can manage collaborator with none role")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockByUserPermission(reason: .unknown))
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testIrrelevantOperation() {
        let irrelevantOperations: [PermissionRequest.Operation] = [
            .applyEmbed,
            .comment,
            .copyContent,
            .createCopy,
            .delete,
            .deleteEntity,
            .deleteVersion,
            .download,
            .downloadAttachment,
            .export,
            .inviteSinglePageEdit,
            .inviteSinglePageFullAccess,
            .inviteSinglePageView,
            .isContainerFullAccess,
            .isSinglePageFullAccess,
            .manageContainerCollaborator,
            .manageContainerPermissionMeta,
            .manageSinglePageCollaborator,
            .manageSinglePagePermissionMeta,
            .manageVersion,
            .modifySecretLabel,
            .openWithOtherApp,
            .save,
            .secretLabelVisible,
            .shareToExternal,
            .upload,
            .uploadAttachment,
            .viewCollaboratorInfo
        ]
        irrelevantOperations.forEach { operation in
            // 测无关操作时，随便给点位赋非法值，判断仍可通过
            assertAllow(operation: operation, role: .none)
        }
    }
}
