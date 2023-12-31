//
//  SecurityAuditValidatorTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/23.
//

import Foundation
import XCTest
@testable import SKPermission
import SKFoundation
import LarkSecurityAudit
import SpaceInterface
import ServerPB
import SKResource

private class MockSecurityAuditProvider: SecurityAuditProvider {

    var expectPermissionType: PermissionType?
    var expectEntityID: String?
    var expectEntityType: ServerPB_Authorization_EntityType?
    var authResult = AuthResult.unknown

    func validate(permissionType: PermissionType, entity: Entity) -> AuthResult {
        XCTAssertEqual(permissionType, expectPermissionType)
        XCTAssertEqual(entity.entityType, expectEntityType)
        XCTAssertEqual(entity.id, expectEntityID)
        return authResult
    }
}

final class SecurityAuditValidatorTests: XCTestCase {

    private typealias Converter = SecurityAuditConverter

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testShouldInvoke() {
        var rules = PermissionExemptRules(shouldCheckFileStrategy: true,
                                          shouldCheckDLP: true,
                                          shouldCheckSecurityAudit: false,
                                          shouldCheckUserPermission: true)
        let validator = SecurityAuditValidator()
        XCTAssertFalse(validator.shouldInvoke(rules: rules))

        rules = PermissionExemptRules(shouldCheckFileStrategy: false,
                                      shouldCheckDLP: false,
                                      shouldCheckSecurityAudit: true,
                                      shouldCheckUserPermission: false)
        XCTAssertTrue(validator.shouldInvoke(rules: rules))
    }

    func testValidateFastPass() {
        // 测试不需要判断的 operation
        let irrelevantOperations: [PermissionRequest.Operation] = [
            .applyEmbed,
            .comment,
            .copyContent,
            .createCopy,
            .createSubNode,
            .delete,
            .deleteEntity,
            .deleteVersion,
            .download,
            .downloadAttachment,
            .edit,
            .export,
            .inviteEdit,
            .inviteFullAccess,
            .inviteSinglePageEdit,
            .inviteSinglePageFullAccess,
            .inviteSinglePageView,
            .inviteView,
            .isContainerFullAccess,
            .isSinglePageFullAccess,
            .manageCollaborator,
            .manageContainerCollaborator,
            .manageContainerPermissionMeta,
            .managePermissionMeta,
            .manageSinglePageCollaborator,
            .manageSinglePagePermissionMeta,
            .manageVersion,
            .modifySecretLabel,
            .moveSubNode,
            .moveThisNode,
            .moveToHere,
            .openWithOtherApp,
            .save,
            .secretLabelVisible,
            .upload,
            .uploadAttachment,
            .view,
            .viewCollaboratorInfo
        ]
        irrelevantOperations.forEach { operation in
            let request = PermissionRequest(entity: .ccm(token: "MOCK_TOKEN",
                                                         type: .doc),
                                            operation: .createCopy,
                                            bizDomain: .ccm)
            let validator = SecurityAuditValidator(auditProvider: MockSecurityAuditProvider())
            let response = validator.validate(request: request)
            XCTAssertTrue(response.allow)

            let expect = expectation(description: "async validate security audit fast pass")
            validator.asyncValidate(request: request) { response in
                XCTAssertTrue(response.allow)
                expect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }

    func testValidatePass() {
        let mockProvider = MockSecurityAuditProvider()
        let request = PermissionRequest(entity: .ccm(token: "MOCK_TOKEN",
                                                     type: .doc),
                                        operation: .shareToExternal,
                                        bizDomain: .ccm)
        mockProvider.expectPermissionType = .fileShare
        mockProvider.expectEntityID = "MOCK_TOKEN"
        mockProvider.expectEntityType = .ccmDoc
        mockProvider.authResult = .unknown

        let validator = SecurityAuditValidator(auditProvider: mockProvider)
        var response = validator.validate(request: request)
        XCTAssertTrue(response.allow)

        var expect = expectation(description: "async validate security audit unknown")
        validator.asyncValidate(request: request) { response in
            XCTAssertTrue(response.allow)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        mockProvider.authResult = .allow
        response = validator.validate(request: request)
        XCTAssertTrue(response.allow)

        expect = expectation(description: "async validate security audit allow")
        validator.asyncValidate(request: request) { response in
            XCTAssertTrue(response.allow)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        mockProvider.authResult = .null
        response = validator.validate(request: request)
        XCTAssertTrue(response.allow)

        expect = expectation(description: "async validate security audit null")
        validator.asyncValidate(request: request) { response in
            XCTAssertTrue(response.allow)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        mockProvider.authResult = .deny
        response = validator.validate(request: request)
        response.assertEqual(denyType: .blockBySecurityAudit)
        response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                                  allowOverrideMessage: false))

        expect = expectation(description: "async validate security audit null")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockBySecurityAudit)
            response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                                      allowOverrideMessage: false))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        mockProvider.authResult = .error
        response = validator.validate(request: request)
        response.assertEqual(denyType: .blockBySecurityAudit)
        response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                                  allowOverrideMessage: false))

        expect = expectation(description: "async validate security audit null")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockBySecurityAudit)
            response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                                      allowOverrideMessage: false))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
