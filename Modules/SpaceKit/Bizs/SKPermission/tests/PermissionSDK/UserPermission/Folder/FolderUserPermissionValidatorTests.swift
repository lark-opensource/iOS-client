//
//  FolderUserPermissionValidatorTests.swift
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

final class FolderUserPermissionValidatorTests: XCTestCase {

    private typealias Action = FolderUserPermission.Action

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testShouldInvoke() {
        let validator = FolderUserPermissionValidator(model: nil, isFromCache: false)

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
        let validator = FolderUserPermissionValidator(model: nil, isFromCache: false)
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
                             action: Action,
                             code: Int? = FolderUserPermission.rightCode,
                             file: StaticString = #file,
                             line: UInt = #line) {
        var actions: [String: Int] = [:]
        actions[action.rawValue] = code
        let permission = FolderUserPermission(actions: actions,
                                              isOwner: false)
        let validator = FolderUserPermissionValidator(model: permission, isFromCache: false)
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
                                 action: Action,
                                 code: Int?,
                                 denyType expectDenyType: PermissionResponse.DenyType,
                                 behaviorType expectBehaviorType: PermissionDefaultUIBehaviorType,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        var actions: [String: Int] = [:]
        actions[action.rawValue] = code
        let permission = FolderUserPermission(actions: actions,
                                              isOwner: false)
        let validator = FolderUserPermissionValidator(model: permission, isFromCache: false)
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
                             action: Action,
                             errorMessage: String = BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                             file: StaticString = #file,
                             line: UInt = #line) {
        XCTAssertEqual(FolderUserPermissionValidator.convert(operation: operation),
                       action,
                       file: file,
                       line: line)

        assertAllow(operation: operation,
                    action: action,
                    file: file,
                    line: line)

        assertForbidden(operation: operation,
                        action: action,
                        code: FolderUserPermission.blockByCACCode,
                        denyType: .blockByUserPermission(reason: .blockByCAC),
                        behaviorType: .error(text: errorMessage,
                                             allowOverrideMessage: true),
                        file: file,
                        line: line)

        assertForbidden(operation: operation,
                        action: action,
                        code: nil,
                        denyType: .blockByUserPermission(reason: .unknown),
                        behaviorType: .error(text: errorMessage,
                                             allowOverrideMessage: true),
                        file: file,
                        line: line)

        assertForbidden(operation: operation,
                        action: action,
                        code: 200,
                        denyType: .blockByUserPermission(reason: .blockByServer(code: 200)),
                        behaviorType: .error(text: errorMessage,
                                             allowOverrideMessage: true),
                        file: file,
                        line: line)
    }

    func testValidateAction() {
        let simpleActions: [(PermissionRequest.Operation, Action)] = [
            (.view, .view), // MARK_OFFSET_START
            (.edit, .edit),
            (.manageCollaborator, .manageCollaborator),
            (.managePermissionMeta, .manageMeta),
            (.inviteFullAccess, .inviteFullAccess),
            (.inviteEdit, .inviteCanEdit),
            (.inviteView, .inviteCanView),
            (.moveThisNode, .beMoved),
            (.moveToHere, .moveTo),
            (.moveSubNode, .moveFrom),
            (.createSubNode, .createSubNode)
        ]
        for (index, (operation, action)) in simpleActions.enumerated() {
            let assertLineOffset: UInt = UInt(simpleActions.count + 3 - index) // 让test失败显示到上面
            batchAssert(operation: operation, action: action, line: #line - assertLineOffset) // MARK_OFFSET_END
        }
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
            assertAllow(operation: operation, action: .moveTo, code: nil)
        }
    }
}
