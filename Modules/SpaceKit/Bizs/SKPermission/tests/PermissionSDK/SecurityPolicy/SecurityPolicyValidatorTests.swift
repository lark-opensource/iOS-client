//
//  SecurityPolicyValidatorTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/24.
//

import Foundation
import XCTest
@testable import SKPermission
import SKFoundation
import SKResource
import LarkSecurityComplianceInterface
import SpaceInterface
import LarkContainer

private class MockPolicyDecision: SecurityPolicyActionDecision {

    func handleAction(_ action: SecurityActionProtocol) {
    }


    var noPermissionExpect: XCTestExpectation?
    func handleNoPermissionAction(_ action: SecurityActionProtocol) {
        noPermissionExpect?.fulfill()
    }
}

private extension ValidateResult {
    init(result: ValidateResultType, extra: ValidateExtraInfo) {
        self.init(userResolver: Container.shared.getCurrentUserResolver(),
                  result: result,
                  extra: extra)
    }
}

final class SecurityPolicyValidatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testShouldInvoke() {
        let validator = SecurityPolicyValidator(userID: 0,
                                                tenantID: 0,
                                                service: MockSecurityPolicyService(),
                                                legacyFileProtectConvertionEnable: true)
        var rules = PermissionExemptRules(shouldCheckFileStrategy: true,
                                          shouldCheckDLP: false,
                                          shouldCheckSecurityAudit: false,
                                          shouldCheckUserPermission: false)
        XCTAssertTrue(validator.shouldInvoke(rules: rules))

        rules = PermissionExemptRules(shouldCheckFileStrategy: false,
                                          shouldCheckDLP: true,
                                          shouldCheckSecurityAudit: true,
                                          shouldCheckUserPermission: true)
        XCTAssertTrue(validator.shouldInvoke(rules: rules))

        rules = PermissionExemptRules(shouldCheckFileStrategy: false,
                                          shouldCheckDLP: false,
                                          shouldCheckSecurityAudit: true,
                                          shouldCheckUserPermission: true)
        XCTAssertFalse(validator.shouldInvoke(rules: rules))
    }

    func testIrrelevantOperation() {
        class MockService: MockSecurityPolicyService {
            override func cacheValidate(policyModel: PolicyModel, authEntity: AuthEntity?, config: ValidateConfig?) -> ValidateResult {
                XCTFail("should not call service validate with irrelevant request")
                return result
            }
            override func asyncValidate(policyModel: PolicyModel, authEntity: AuthEntity?, config: ValidateConfig?, complete: @escaping (ValidateResult) -> Void) {
                XCTFail("should not call service validate with irrelevant request")
                complete(result)
            }
        }
        let validator = SecurityPolicyValidator(userID: 0,
                                                tenantID: 0,
                                                service: MockService(),
                                                legacyFileProtectConvertionEnable: true)

        let irrelevantOperations: [PermissionRequest.Operation] = [
            .applyEmbed,
            .comment,
            .createSubNode,
            .delete,
            .deleteEntity,
            .deleteVersion,
            .edit,
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
            .secretLabelVisible,
            .viewCollaboratorInfo
        ]
        irrelevantOperations.forEach { operation in
            let request = PermissionRequest(token: "MOCK_TOKEN",
                                            type: .folder,
                                            operation: operation,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            let response = validator.validate(request: request)
            response.assertAllow()

            var syncValidateFlag = false
            validator.asyncValidate(request: request) { response in
                response.assertAllow()
                syncValidateFlag = true
            }
            XCTAssertTrue(syncValidateFlag)
        }

        // 小程序的请求也要求快速通过
        let request = PermissionRequest(driveSDKDomain: .openPlatformAttachment, fileID: "MOCK_FILE_ID",
                                        operation: .view,
                                        bizDomain: .openPlatform)
        let response = validator.validate(request: request)
        response.assertAllow()

        var syncValidateFlag = false
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            syncValidateFlag = true
        }
        XCTAssertTrue(syncValidateFlag)
    }

    func testConvertRequest() {
        class MockService: MockSecurityPolicyService {
            override func cacheValidate(policyModel: PolicyModel, authEntity: AuthEntity?, config: ValidateConfig?) -> ValidateResult {
                if let config {
                    XCTAssertTrue(config.ignoreSecurityOperate)
                    XCTAssertFalse(config.ignoreCache)
                } else {
                    XCTFail("validate config should not be nil")
                }
                if let authEntity {
                    XCTAssertEqual(authEntity.entity?.entityType, .ccmDoc)
                    XCTAssertEqual(authEntity.entity?.id, "MOCK_TOKEN")
                    XCTAssertEqual(authEntity.permType, .docExport)
                } else {
                    XCTFail("validate auth entity should not be nil")
                }
                XCTAssertEqual(policyModel.pointKey, .ccmExport)
                if let entity = policyModel.entity as? CCMEntity {
                    XCTAssertEqual(entity.fileBizDomain, .ccm)
                    XCTAssertEqual(entity.entityType, .doc)
                    XCTAssertEqual(entity.entityDomain, .ccm)
                    XCTAssertEqual(entity.entityOperate, .ccmExport)
                    XCTAssertEqual(entity.operatorUid, 10010)
                    XCTAssertEqual(entity.operatorTenantId, 10086)
                } else {
                    XCTFail("invalid entity found: \(policyModel.entity)")
                }
                let result = ValidateResult(result: .allow, extra: ValidateExtraInfo(resultSource: .unknown, errorReason: nil))
                return result
            }

            override func asyncValidate(policyModel: PolicyModel, authEntity: AuthEntity?, config: ValidateConfig?, complete: @escaping (ValidateResult) -> Void) {
                let result = cacheValidate(policyModel: policyModel, authEntity: authEntity, config: config)
                complete(result)
            }
        }

        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .doc,
                                        operation: .export,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        let validator = SecurityPolicyValidator(userID: 10010,
                                                tenantID: 10086,
                                                service: MockService(),
                                                legacyFileProtectConvertionEnable: true)
        let response = validator.validate(request: request)
        response.assertAllow()

        var syncExecFlag = false
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            syncExecFlag = true
        }
        XCTAssertTrue(syncExecFlag)
    }

    func testConvertFileStrategyResponse() {
        let mockDecision = MockPolicyDecision()
        Container.shared.register(SecurityPolicyActionDecision.self) { _ in
            mockDecision
        }
        let service = MockSecurityPolicyService()
        service.result = ValidateResult(userResolver: Container.shared.getCurrentUserResolver(),
                                        result: .allow,
                                        extra: ValidateExtraInfo(resultSource: .fileStrategy, errorReason: nil))

        let validator = SecurityPolicyValidator(userID: 0, tenantID: 0, service: service,
                                                legacyFileProtectConvertionEnable: true)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .doc,
                                        operation: .export,
                                        bizDomain: .ccm,
                                        tenantID: nil)

        let allowResultType: [ValidateResultType] = [.allow]
        allowResultType.forEach { resultType in
            service.result = ValidateResult(result: resultType, extra: ValidateExtraInfo(resultSource: .fileStrategy, errorReason: nil))
            let response = validator.validate(request: request)
            response.assertAllow()

            let expect = expectation(description: "async validate CAC with \(resultType)")
            validator.asyncValidate(request: request) { response in
                response.assertAllow()
                expect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }

        let forbiddenResultType: [ValidateResultType] = [.unknown, .deny, .null, .error]
        forbiddenResultType.forEach { resultType in
            service.result = ValidateResult(result: resultType, extra: ValidateExtraInfo(resultSource: .fileStrategy, errorReason: nil, rawActions: "MOCK"))
            let response = validator.validate(request: request)
            response.assertEqual(denyType: .blockByFileStrategy)
            if case let .forbidden(_, _, behavior) = response,
               case let .custom(action) = behavior {
                if resultType == .deny {
                    let showDialogExpect = expectation(description: "expect show CAC dialog for \(resultType)")
                    mockDecision.noPermissionExpect = showDialogExpect
                    action(UIViewController(), nil)
                    waitForExpectations(timeout: 1)
                }
            } else {
                XCTFail("un-expected response found: \(response)")
            }

            let asyncExpect = expectation(description: "async validate CAC with \(resultType)")
            validator.asyncValidate(request: request) { [self] response in
                response.assertEqual(denyType: .blockByFileStrategy)
                if case let .forbidden(_, _, behavior) = response,
                   case let .custom(action) = behavior {
                    if resultType == .deny {
                        let showDialogExpect = XCTestExpectation(description: "expect show CAC dialog for \(resultType)")
                        mockDecision.noPermissionExpect = showDialogExpect
                        action(UIViewController(), nil)
                        wait(for: [showDialogExpect], timeout: 1)
                    }
                } else {
                    XCTFail("un-expected response found: \(response)")
                }
                asyncExpect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }

    func testConvertDLPResponse() {
        let service = MockSecurityPolicyService()
        let validator = SecurityPolicyValidator(userID: 0, tenantID: 0, service: service,
                                                legacyFileProtectConvertionEnable: true)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .doc,
                                        operation: .export,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        service.result = ValidateResult(result: .allow, extra: ValidateExtraInfo(resultSource: .dlpDetecting, errorReason: nil))
        var response = validator.validate(request: request)
        response.assertAllow()

        var expect = expectation(description: "async validate DLP detecting with allow")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        service.result = ValidateResult(result: .allow, extra: ValidateExtraInfo(resultSource: .dlpSensitive, errorReason: nil))
        response = validator.validate(request: request)
        response.assertAllow()

        expect = expectation(description: "async validate DLP sensitive with dlpDetecting deny")
        validator.asyncValidate(request: request) { response in
            response.assertAllow()
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        service.result = ValidateResult(result: .deny, extra: ValidateExtraInfo(resultSource: .dlpDetecting, errorReason: nil))
        response = validator.validate(request: request)
        response.assertEqual(denyType: .blockByDLPDetecting)

        expect = expectation(description: "async validate DLP sensitive with dlpDetecting deny")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockByDLPDetecting)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        service.result = ValidateResult(result: .deny, extra: ValidateExtraInfo(resultSource: .dlpSensitive, errorReason: nil))
        response = validator.validate(request: request)
        response.assertEqual(denyType: .blockByDLPSensitive)

        expect = expectation(description: "async validate DLP sensitive with dlpSensitive deny")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockByDLPSensitive)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)

        service.result = ValidateResult(result: .deny, extra: ValidateExtraInfo(resultSource: .ttBlock, errorReason: nil))
        response = validator.validate(request: request)
        response.assertEqual(denyType: .blockByDLPSensitive)

        expect = expectation(description: "async validate DLP sensitive with ttBlock deny")
        validator.asyncValidate(request: request) { response in
            response.assertEqual(denyType: .blockByDLPSensitive)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testConvertSecurityAuditResponse() {
        let service = MockSecurityPolicyService()
        let validator = SecurityPolicyValidator(userID: 0, tenantID: 0, service: service,
                                                legacyFileProtectConvertionEnable: true)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .doc,
                                        operation: .export,
                                        bizDomain: .ccm,
                                        tenantID: nil)

        let allowResultType: [ValidateResultType] = [.unknown, .allow, .null]
        allowResultType.forEach { resultType in
            service.result = ValidateResult(result: resultType, extra: ValidateExtraInfo(resultSource: .securityAudit, errorReason: nil))
            let response = validator.validate(request: request)
            response.assertAllow()

            let expect = expectation(description: "async validate security audit with \(resultType)")
            validator.asyncValidate(request: request) { response in
                response.assertAllow()
                expect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }

        let forbiddenResultType: [ValidateResultType] = [.deny, .error]
        forbiddenResultType.forEach { resultType in
            service.result = ValidateResult(result: resultType, extra: ValidateExtraInfo(resultSource: .securityAudit, errorReason: nil))
            let response = validator.validate(request: request)
            response.assertEqual(denyType: .blockBySecurityAudit)
            response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                                      allowOverrideMessage: false))

            let expect = expectation(description: "async validate security audit with \(resultType)")
            validator.asyncValidate(request: request) { response in
                response.assertEqual(denyType: .blockBySecurityAudit)
                response.assertEqual(behaviorType: .error(text: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                                          allowOverrideMessage: false))
                expect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }

    func testConvertUnknownResponse() {
        let mockDecision = MockPolicyDecision()
        Container.shared.register(SecurityPolicyActionDecision.self) { _ in
            mockDecision
        }
        let service = MockSecurityPolicyService()
        let validator = SecurityPolicyValidator(userID: 0, tenantID: 0, service: service,
                                                legacyFileProtectConvertionEnable: true)
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .doc,
                                        operation: .export,
                                        bizDomain: .ccm,
                                        tenantID: nil)

        let allowResultType: [ValidateResultType] = [.unknown, .allow, .null]
        allowResultType.forEach { resultType in
            service.result = ValidateResult(result: resultType, extra: ValidateExtraInfo(resultSource: .securityAudit, errorReason: nil))
            let response = validator.validate(request: request)
            response.assertAllow()

            let expect = expectation(description: "async validate unknown with \(resultType)")
            validator.asyncValidate(request: request) { response in
                response.assertAllow()
                expect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }

        let forbiddenResultType: [ValidateResultType] = [.deny, .error]
        forbiddenResultType.forEach { resultType in
            service.result = ValidateResult(result: resultType, extra: ValidateExtraInfo(resultSource: .unknown, errorReason: nil, rawActions: "MOCK"))
            let response = validator.validate(request: request)
            response.assertEqual(denyType: .blockByFileStrategy)
            if case let .forbidden(_, _, behavior) = response,
               case let .custom(action) = behavior {
                if resultType == .deny {
                    let showDialogExpect = expectation(description: "expect show CAC dialog for \(resultType)")
                    mockDecision.noPermissionExpect = showDialogExpect
                    action(UIViewController(), nil)
                    waitForExpectations(timeout: 1)
                }
            } else {
                XCTFail("un-expected response found: \(response)")
            }

            let asyncExpect = expectation(description: "async validate unknown with \(resultType)")
            validator.asyncValidate(request: request) { [self] response in
                response.assertEqual(denyType: .blockByFileStrategy)
                if case let .forbidden(_, _, behavior) = response,
                   case let .custom(action) = behavior {
                    if resultType == .deny {
                        let showDialogExpect = XCTestExpectation(description: "expect show CAC dialog for \(resultType)")
                        mockDecision.noPermissionExpect = showDialogExpect
                        action(UIViewController(), nil)
                        wait(for: [showDialogExpect], timeout: 1)
                    }
                } else {
                    XCTFail("un-expected response found: \(response)")
                }
                asyncExpect.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    }
}
