//
//  PermissionSDKImplTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/25.
//

import Foundation
import XCTest
import SpaceInterface
@testable import SKPermission
@testable import SKFoundation
import LarkSecurityComplianceInterface

final class PermissionSDKImplTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        UserScopeNoChangeFG.clearAllMockFG()
    }

    func testSyncValidateAllPass() {
        class MockValidator: MockPermissionValidator {
            var expect: XCTestExpectation?
            override func validate(request: PermissionRequest) -> PermissionValidatorResponse {
                XCTAssertEqual(request.entity, .ccm(token: "MOCK_TOKEN", type: .docX))
                XCTAssertEqual(request.operation, .copyContent)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.extraInfo.entityTenantID, "MOCK_TENANT_ID")
                XCTAssertNil(request.exemptConfig)
                XCTAssertEqual(request.exemptRules, .default)
                expect?.fulfill()
                return super.validate(request: request)
            }
        }
        let firstExpect = expectation(description: "first validator expect")
        let firstValidator = MockValidator()
        firstValidator.expect = firstExpect

        let secondExpect = expectation(description: "second validator expect")
        let secondValidator = MockValidator()
        secondValidator.expect = secondExpect

        let sdk = PermissionSDKImpl(userID: "MOCK_USERID",
                                    tenantID: "MOCK_TENANT_ID",
                                    validators: [firstValidator, secondValidator])
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .copyContent,
                                        bizDomain: .ccm,
                                        tenantID: "MOCK_TENANT_ID")
        let response = sdk.validate(request: request)
        XCTAssertTrue(response.allow)
        waitForExpectations(timeout: 1)
    }

    func testAsyncValidateAllPass() {
        class MockValidator: MockPermissionValidator {
            var expect: XCTestExpectation?
            override func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
                XCTAssertEqual(request.entity, .ccm(token: "MOCK_TOKEN", type: .docX))
                XCTAssertEqual(request.operation, .copyContent)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.extraInfo.entityTenantID, "MOCK_TENANT_ID")
                XCTAssertNil(request.exemptConfig)
                XCTAssertEqual(request.exemptRules, .default)
                expect?.fulfill()
                super.asyncValidate(request: request, completion: completion)
            }
        }
        let firstExpect = expectation(description: "first validator expect")
        let firstValidator = MockValidator()
        firstValidator.expect = firstExpect

        let secondExpect = expectation(description: "second validator expect")
        let secondValidator = MockValidator()
        secondValidator.expect = secondExpect

        let sdk = PermissionSDKImpl(userID: "MOCK_USERID",
                                    tenantID: "MOCK_TENANT_ID",
                                    validators: [firstValidator, secondValidator])
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .copyContent,
                                        bizDomain: .ccm,
                                        tenantID: "MOCK_TENANT_ID")
        let expect = expectation(description: "async callback")
        sdk.asyncValidate(request: request) { response in
            XCTAssertTrue(response.allow)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSyncExemptRules() {
        class MockValidator: MockPermissionValidator {
            var expect: XCTestExpectation?
            override func validate(request: PermissionRequest) -> PermissionValidatorResponse {
                expect?.fulfill()
                return super.validate(request: request)
            }
        }
        let firstExpect = expectation(description: "first validator expect")
        firstExpect.isInverted = true
        let firstValidator = MockValidator()
        firstValidator.expect = firstExpect
        firstValidator.invoke = false
        firstValidator.syncResponse = .forbidden(denyType: .blockByFileStrategy) { _, _ in }

        let secondExpect = expectation(description: "second validator expect")
        let secondValidator = MockValidator()
        secondValidator.expect = secondExpect

        let sdk = PermissionSDKImpl(userID: "MOCK_USERID",
                                    tenantID: "MOCK_TENANT_ID",
                                    validators: [firstValidator, secondValidator])
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .copyContent,
                                        bizDomain: .ccm,
                                        tenantID: "MOCK_TENANT_ID")
        let response = sdk.validate(request: request)
        XCTAssertTrue(response.allow)
        waitForExpectations(timeout: 1)
    }

    func testAsyncExemptRules() {
        class MockValidator: MockPermissionValidator {
            var expect: XCTestExpectation?
            override func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
                expect?.fulfill()
                super.asyncValidate(request: request, completion: completion)
            }
        }
        let firstExpect = expectation(description: "first validator expect")
        firstExpect.isInverted = true
        let firstValidator = MockValidator()
        firstValidator.expect = firstExpect
        firstValidator.invoke = false
        firstValidator.asyncResponse = .forbidden(denyType: .blockByFileStrategy) { _, _ in }

        let secondExpect = expectation(description: "second validator expect")
        let secondValidator = MockValidator()
        secondValidator.expect = secondExpect

        let sdk = PermissionSDKImpl(userID: "MOCK_USERID",
                                    tenantID: "MOCK_TENANT_ID",
                                    validators: [firstValidator, secondValidator])
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .copyContent,
                                        bizDomain: .ccm,
                                        tenantID: "MOCK_TENANT_ID")
        let expect = expectation(description: "async callback")
        sdk.asyncValidate(request: request) { response in
            XCTAssertTrue(response.allow)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSyncValidateForbidden() {
        class MockValidator: MockPermissionValidator {
            var expect: XCTestExpectation?
            override func validate(request: PermissionRequest) -> PermissionValidatorResponse {
                expect?.fulfill()
                return super.validate(request: request)
            }
        }
        let firstExpect = expectation(description: "first validator expect")
        let firstValidator = MockValidator()
        firstValidator.expect = firstExpect
        firstValidator.syncResponse = .forbidden(denyType: .blockByDLPSensitive) { _, _ in }

        let secondExpect = expectation(description: "second validator expect")
        secondExpect.isInverted = true
        let secondValidator = MockValidator()
        secondValidator.expect = secondExpect

        let sdk = PermissionSDKImpl(userID: "MOCK_USERID",
                                    tenantID: "MOCK_TENANT_ID",
                                    validators: [firstValidator, secondValidator])
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .copyContent,
                                        bizDomain: .ccm,
                                        tenantID: "MOCK_TENANT_ID")
        let response = sdk.validate(request: request)
        switch response.result {
        case .allow:
            XCTFail("un-expected allow found")
        case let .forbidden(denyType, _):
            XCTAssertEqual(denyType, .blockByDLPSensitive)
        }
        waitForExpectations(timeout: 1)
    }

    func testAsyncValidateForbidden() {
        class MockValidator: MockPermissionValidator {
            var expect: XCTestExpectation?
            override func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
                expect?.fulfill()
                super.asyncValidate(request: request, completion: completion)
            }
        }
        let firstExpect = expectation(description: "first validator expect")
        let firstValidator = MockValidator()
        firstValidator.expect = firstExpect
        firstValidator.asyncResponse = .forbidden(denyType: .blockByDLPSensitive) { _, _ in }

        let secondExpect = expectation(description: "second validator expect")
        let secondValidator = MockValidator()
        secondValidator.expect = secondExpect
        secondValidator.asyncResponse = .forbidden(denyType: .blockByFileStrategy) { _, _ in }

        let thirdExpect = expectation(description: "third validator expect")
        let thirdValidator = MockValidator()
        thirdValidator.expect = thirdExpect
        thirdValidator.asyncResponse = .forbidden(denyType: .blockByUserPermission(reason: .blockByCAC)) { _, _ in }

        let sdk = PermissionSDKImpl(userID: "MOCK_USERID",
                                    tenantID: "MOCK_TENANT_ID",
                                    validators: [firstValidator, secondValidator, thirdValidator])
        let request = PermissionRequest(token: "MOCK_TOKEN",
                                        type: .docX,
                                        operation: .copyContent,
                                        bizDomain: .ccm,
                                        tenantID: "MOCK_TENANT_ID")
        let expect = expectation(description: "async callback")
        sdk.asyncValidate(request: request) { response in
            switch response.result {
            case .allow:
                XCTFail("un-expected allow found")
            case let .forbidden(denyType, _):
                XCTAssertEqual(denyType, .blockByFileStrategy)
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSortDenyType() {
        typealias DenyType = PermissionResponse.DenyType

        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockByFileStrategy))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockBySecurityAudit))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockByDLPSensitive))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockByDLPDetecting))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByFileStrategy, rhs: .blockByUserPermission(reason: .unknown)))

        XCTAssertTrue(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockByFileStrategy))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockBySecurityAudit))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockByDLPSensitive))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockByDLPDetecting))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockBySecurityAudit, rhs: .blockByUserPermission(reason: .unknown)))

        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockByFileStrategy))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockBySecurityAudit))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockByDLPSensitive))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockByDLPDetecting))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPSensitive, rhs: .blockByUserPermission(reason: .unknown)))

        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockByFileStrategy))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockBySecurityAudit))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockByDLPSensitive))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockByDLPDetecting))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByDLPDetecting, rhs: .blockByUserPermission(reason: .unknown)))

        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockByFileStrategy))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockBySecurityAudit))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockByDLPSensitive))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockByDLPDetecting))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .userPermissionNotReady), rhs: .blockByUserPermission(reason: .unknown)))

        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockByFileStrategy))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockBySecurityAudit))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockByDLPSensitive))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockByDLPDetecting))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByCAC), rhs: .blockByUserPermission(reason: .unknown)))

        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockByFileStrategy))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockBySecurityAudit))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockByDLPSensitive))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockByDLPDetecting))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .blockByServer(code: 200)), rhs: .blockByUserPermission(reason: .unknown)))

        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockByFileStrategy))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockBySecurityAudit))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockByDLPSensitive))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockByDLPDetecting))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockByUserPermission(reason: .userPermissionNotReady)))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockByUserPermission(reason: .blockByCAC)))
        XCTAssertTrue(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockByUserPermission(reason: .blockByServer(code: 300))))
        XCTAssertFalse(DenyType.sortByRank(lhs: .blockByUserPermission(reason: .unknown), rhs: .blockByUserPermission(reason: .unknown)))
    }

    func testGetExemptRequest() {
        let permissionSDK = PermissionSDKImpl(userID: "MOCK_USERID",
                                              tenantID: "MOCK_TENANT_ID",
                                              validators: [])
        let entity = PermissionRequest.Entity.ccm(token: "MOCK_TOKEN", type: .docX)
        PermissionExemptScene.allCases.forEach { scene in
            let request = permissionSDK.getExemptRequest(entity: entity, exemptScene: scene)
            switch scene {
            case .duplicateSystemTemplate:
                // 检查特殊的配置
                XCTAssertEqual(request.operation, .createCopy)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.exemptRules, PermissionExemptRules(shouldCheckFileStrategy: false,
                                                                          shouldCheckDLP: false,
                                                                          shouldCheckSecurityAudit: false,
                                                                          shouldCheckUserPermission: true))
            case .useTemplateButtonEnable:
                // 检查特殊的配置
                XCTAssertEqual(request.operation, .createCopy)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.exemptRules, PermissionExemptRules(shouldCheckFileStrategy: true,
                                                                          shouldCheckDLP: false,
                                                                          shouldCheckSecurityAudit: true,
                                                                          shouldCheckUserPermission: true))
            case .driveAttachmentMoreVisable:
                // 检查特殊的配置
                XCTAssertEqual(request.operation, .downloadAttachment)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.exemptRules, PermissionExemptRules(shouldCheckFileStrategy: false,
                                                                          shouldCheckDLP: false,
                                                                          shouldCheckSecurityAudit: false,
                                                                          shouldCheckUserPermission: true))
            case .downloadDocumentImageAttachmentWithDLP:
                XCTAssertEqual(request.operation, .downloadAttachment)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.exemptRules, PermissionExemptRules(shouldCheckFileStrategy: false,
                                                                          shouldCheckDLP: true,
                                                                          shouldCheckSecurityAudit: false,
                                                                          shouldCheckUserPermission: false))
            case .viewSpaceFolder:
                XCTAssertEqual(request.operation, .view)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.exemptRules, PermissionExemptRules(shouldCheckFileStrategy: false,
                                                                          shouldCheckDLP: false,
                                                                          shouldCheckSecurityAudit: false,
                                                                          shouldCheckUserPermission: true))
            case .dlpBannerVisable:
                XCTAssertEqual(request.operation, .shareToExternal)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertEqual(request.exemptRules, PermissionExemptRules(shouldCheckFileStrategy: true,
                                                                          shouldCheckDLP: true,
                                                                          shouldCheckSecurityAudit: false,
                                                                          shouldCheckUserPermission: true))
            }
        }
    }

    func testGetUserPermissionService() {
        let permissionSDK = PermissionSDKImpl(userID: "MOCK_USERID",
                                              tenantID: "MOCK_TENANT_ID",
                                              validators: [])
        var service: UserPermissionService? = permissionSDK.userPermissionService(for: .document(token: "MOCK_TOKEN", type: .docX)) as? DocumentUserPermissionService
        XCTAssertNotNil(service)

        service = permissionSDK.userPermissionService(for: .folder(token: "MOCK_TOKEN")) as? FolderUserPermissionService
        XCTAssertNotNil(service)

        service = permissionSDK.userPermissionService(for: .legacyFolder(info: SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .personal))) as? LegacyFolderUserPermissionService
        XCTAssertNotNil(service)
    }

    func testHandleCommonError() {
        let permissionSDK = PermissionSDKImpl(userID: "",
                                              tenantID: "",
                                              validators: [])
        var error: Error = DocsNetworkError(900099011)!
        XCTAssertNotNil(permissionSDK.canHandle(error: error, context: PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createCopy)))

        error = NSError(domain: "MOCK", code: 900099011)
        XCTAssertNotNil(permissionSDK.canHandle(error: error, context: PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createCopy)))

        error = NSError(domain: "MOCK", code: 90099001)
        XCTAssertNotNil(permissionSDK.canHandle(error: error, context: PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createCopy)))

        error = NSError(domain: "MOCK", code: 90099002)
        XCTAssertNotNil(permissionSDK.canHandle(error: error, context: PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createCopy)))

        error = NSError(domain: "MOCK", code: 90099003)
        XCTAssertNotNil(permissionSDK.canHandle(error: error, context: PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createCopy)))

        error = NSError(domain: "MOCK", code: 90099004)
        XCTAssertNotNil(permissionSDK.canHandle(error: error, context: PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createCopy)))

        error = NSError(domain: "MOCK", code: -1)
        XCTAssertNil(permissionSDK.canHandle(error: error, context: PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createCopy)))
    }

    func testDLPContext() {
        UserScopeNoChangeFG.setMockFG(key: "lark.security.ccm_dlp_migrate", value: true)

        let permissionSDK = PermissionSDKImpl(userID: "MOCK_USERID",
                                              tenantID: "MOCK_TENANT_ID",
                                              validators: [])
        var service = permissionSDK.userPermissionService(for: .document(token: "MOCK_TOKEN", type: .docX)) as? DocumentUserPermissionService
        XCTAssertNotNil(service)
        XCTAssertNotNil(service?.dlpContext)
        if let pointKeys = service?.dlpContext?.pointKeys,
           pointKeys.count == DLPSceneContext.dlpPointKeysForDocument.count {
            for (index, (pointKey, operation)) in pointKeys.enumerated() {
                let (expectPointKey, expectOperation) = DLPSceneContext.dlpPointKeysForDocument[index]
                XCTAssertEqual(pointKey, expectPointKey)
                XCTAssertEqual(operation, expectOperation)
            }
        } else {
            XCTFail()
        }

        service = permissionSDK.userPermissionService(for: .document(token: "MOCK_TOKEN", type: .file)) as? DocumentUserPermissionService
        XCTAssertNotNil(service)
        XCTAssertNotNil(service?.dlpContext)
        if let pointKeys = service?.dlpContext?.pointKeys,
           pointKeys.count == DLPSceneContext.dlpPointKeysForFile.count {
            for (index, (pointKey, operation)) in pointKeys.enumerated() {
                let (expectPointKey, expectOperation) = DLPSceneContext.dlpPointKeysForFile[index]
                XCTAssertEqual(pointKey, expectPointKey)
                XCTAssertEqual(operation, expectOperation)
            }
        } else {
            XCTFail()
        }

        let cache = DocumentUserPermissionCache(userID: "MOCK_USERID")
        service = permissionSDK.driveSDKCustomUserPermissionService(permissionAPI: DocumentUserPermissionAPI(meta: SpaceMeta(objToken: "MOCK_TOKEN", objType: .docX), parentMeta: nil, sessionID: "MOCK_SESSION_ID", cache: cache),
                                                                    validatorType: DocumentUserPermissionValidator.self,
                                                                    tokenForDLP: "MOCK_DLP_TOKEN",
                                                                    bizDomain: .ccm,
                                                                    sessionID: "MOCK_SESSION_ID") as? DocumentUserPermissionService
        XCTAssertNotNil(service)
        XCTAssertNotNil(service?.dlpContext)
        if let pointKeys = service?.dlpContext?.pointKeys,
           pointKeys.count == DLPSceneContext.dlpPointKeysForAttachmentFile.count {
            for (index, (pointKey, operation)) in pointKeys.enumerated() {
                let (expectPointKey, expectOperation) = DLPSceneContext.dlpPointKeysForAttachmentFile[index]
                XCTAssertEqual(pointKey, expectPointKey)
                XCTAssertEqual(operation, expectOperation)
            }
        } else {
            XCTFail()
        }
    }
}
