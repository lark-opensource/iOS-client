//
//  DocumentUserPermissionValidatorTests.swift
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

final class DocumentUserPermissionValidatorTests: XCTestCase {

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

    func testShouldInvoke() {
        let validator = DocumentUserPermissionValidator(model: nil, isFromCache: false)

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
        let validator = DocumentUserPermissionValidator(model: nil, isFromCache: false)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .export,
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
                             code: Int? = DocumentUserPermission.rightCode,
                             file: StaticString = #file,
                             line: UInt = #line) {
        var actions: [String: Int] = [:]
        actions[action.rawValue] = code
        let permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        let validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
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
        let permission = DocumentUserPermission(actions: actions,
                                                authReasons: [:],
                                                isOwner: false)
        let validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
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
        let result = DocumentUserPermissionValidator.convertAction(operation: operation)
        XCTAssertEqual(action, result, file: file, line: line)

        assertAllow(operation: operation,
                    action: action,
                    file: file,
                    line: line)

        assertForbidden(operation: operation,
                        action: action,
                        code: DocumentUserPermission.blockByCACCode,
                        denyType: .blockByFileStrategy,
                        behaviorType: .error(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                             allowOverrideMessage: false),
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
            (.export, .export), // MARK_OFFSET_START
            (.view, .view),
            (.edit, .edit),
            (.copyContent, .copy),
            (.createCopy, .duplicate),
            (.comment, .comment),
            (.createSubNode, .createSubNode),
            (.deleteEntity, .operateEntity),
            (.inviteFullAccess, .inviteContainerFullAccess),
            (.inviteEdit, .inviteContainerCanEdit),
            (.inviteView, .inviteContainerCanView),
            (.inviteSinglePageFullAccess, .inviteSinglePageFullAccess),
            (.inviteSinglePageEdit, .inviteSinglePageCanEdit),
            (.inviteSinglePageView, .inviteSinglePageCanView),
            (.moveThisNode, .beMoved),
            (.moveSubNode, .moveFrom),
            (.moveToHere, .moveTo),
            (.applyEmbed, .applyEmbed),
            (.manageContainerCollaborator, .manageContainerCollaborator),
            (.manageContainerPermissionMeta, .manageContainerMeta),
            (.manageSinglePageCollaborator, .manageSinglePageCollaborator),
            (.manageSinglePagePermissionMeta, .manageSinglePageMeta),
            (.secretLabelVisible, .visitSecretLevel),
            (.modifySecretLabel, .modifySecretLevel),
            (.isContainerFullAccess, .manageContainerMeta),
            (.isSinglePageFullAccess, .manageSinglePageMeta),
            (.manageVersion, .manageVersion),
            (.deleteVersion, .operateEntity),
            (.importToOnlineDocument, .download),
            (.downloadAttachment, .download),
            (.download, .download),
            (.viewCollaboratorInfo, .showCollaboratorInfo)
        ]
        for (index, (operation, action)) in simpleActions.enumerated() {
            let assertLineOffset: UInt = UInt(simpleActions.count + 3 - index) // 让test失败显示到上面
            batchAssert(operation: operation, action: action, line: #line - assertLineOffset) // MARK_OFFSET_END
        }
    }

    func testIrrelevantOperation() {
        let irrelevantOperations: [PermissionRequest.Operation] = [
            .delete,
            .save,
            .shareToExternal,
            .upload,
            .uploadAttachment
        ]
        for (index, operation) in irrelevantOperations.enumerated() {
            let assertLineOffset: UInt = UInt(irrelevantOperations.count + 3 - index)
            assertAllow(operation: operation, action: .export, code: -1, line: #line - assertLineOffset) // 测无关操作时，随便给点位赋非法值，判断仍可通过
        }
    }

    func testConvertComposeAction() {
        let composeActions: [(PermissionRequest.Operation, ComposeAction)] = [
            (.manageCollaborator, .manageCollaborator), // MARK_OFFSET_START
            (.managePermissionMeta, .managePermissionMeta),
            (.openWithOtherApp, .openWithOtherApp),
            (.updateTimeZone, .updateTimeZone)
        ]
        for (index, (operation, action)) in composeActions.enumerated() {
            let assertLineOffset: UInt = UInt(composeActions.count + 3 - index)
            XCTAssertEqual(DocumentUserPermissionValidator.convertComposeAction(operation: operation), action, line: #line - assertLineOffset)
        }
    }

    func testManageCollaboratorComposeAction() {
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .manageCollaborator,
                                        bizDomain: .ccm,
                                        tenantID: nil)
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
        var validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        var response = validator.validate(request: request)
        response.assertAllow()
        var asyncExpect = expectation(description: "expect allow with only container permission")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

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
        validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        response = validator.validate(request: request)
        response.assertAllow()
        asyncExpect = expectation(description: "expect allow with only single page permission")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

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
        validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        response = validator.validate(request: request)
        response.assertAllow()
        asyncExpect = expectation(description: "expect allow with both permission")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

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
        validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        response = validator.validate(request: request)
        response.assertEqual(denyType: .blockByFileStrategy)
        asyncExpect = expectation(description: "expect allow with neither permission")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockByFileStrategy)
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testManagePermissionMetaComposeAction() {
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .managePermissionMeta,
                                        bizDomain: .ccm,
                                        tenantID: nil)
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
        var validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        var response = validator.validate(request: request)
        response.assertAllow()
        var asyncExpect = expectation(description: "expect allow with only container permission")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

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
        validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        response = validator.validate(request: request)
        response.assertAllow()
        asyncExpect = expectation(description: "expect allow with only single page permission")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

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
        validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        response = validator.validate(request: request)
        response.assertAllow()
        asyncExpect = expectation(description: "expect allow with both permission")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

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
        validator = DocumentUserPermissionValidator(model: permission, isFromCache: false)
        response = validator.validate(request: request)
        response.assertEqual(denyType: .blockByFileStrategy)
        asyncExpect = expectation(description: "expect allow with neither permission")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockByFileStrategy)
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
