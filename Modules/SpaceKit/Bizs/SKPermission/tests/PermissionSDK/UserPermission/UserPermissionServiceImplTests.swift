//
//  UserPermissionServiceImplTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/25.
//

import Foundation
import XCTest
import SpaceInterface
import RxSwift
@testable import SKPermission
import SKFoundation

final class UserPermissionServiceImplTests: XCTestCase {

    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        disposeBag = DisposeBag()
    }

    func testUpdateUserPermission() {
        let mockAPI = MockUserPermissionAPI()
        mockAPI.result = .failure(MockError.expectedFailure)
        let service = UserPermissionServiceImpl(permissionAPI: mockAPI,
                                                validatorType: MockUserPermissionValidator<MockAllowResponseProvider>.self,
                                                permissionSDK: MockPermissionSDK(),
                                                sessionID: "MOCK_SESSION_ID")
        XCTAssertFalse(service.ready)
        XCTAssertFalse(service.hasPermission)

        var testBag = DisposeBag()
        let updateWithErrorExpect = expectation(description: "expect update permission passthrough error")
        service.updateUserPermission()
            .subscribe { _ in
                XCTFail("un-expected success found")
                updateWithErrorExpect.fulfill()
            } onError: { error in
                if let mockError = error as? MockError {
                    XCTAssertEqual(mockError, .expectedFailure)
                } else {
                    XCTFail("un-expected other error found: \(error)")
                }
                updateWithErrorExpect.fulfill()
            }
            .disposed(by: testBag)
        waitForExpectations(timeout: 1)
        XCTAssertFalse(service.ready)
        XCTAssertFalse(service.hasPermission)

        testBag = DisposeBag()
        let updateWithNoPermissionExpect = expectation(description: "expect update permission with no permission")
        let authorizedUserInfo = AuthorizedUserInfo(userID: "MOCK_USER_ID",
                                                    userName: "MOCK_USER_NAME",
                                                    i18nNames: ["A": "B"],
                                                    aliasInfo: UserAliasInfo(displayName: "MOCK_DP_NAME",
                                                                             i18nDisplayNames: ["C": "D"]))
        mockAPI.result = .success(.noPermission(permission: nil, statusCode: .passwordRequired, applyUserInfo: authorizedUserInfo))
        service.updateUserPermission()
            .subscribe { response in
                switch response {
                case .success:
                    XCTFail("un-expected success found")
                case let .noPermission(statusCode, applyUserInfo):
                    XCTAssertEqual(statusCode, .passwordRequired)
                    XCTAssertEqual(applyUserInfo, authorizedUserInfo)
                }
                updateWithNoPermissionExpect.fulfill()
            } onError: { error in
                XCTFail("un-expected other error found: \(error)")
                updateWithNoPermissionExpect.fulfill()
            }
            .disposed(by: testBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(service.ready)
        XCTAssertFalse(service.hasPermission)

        testBag = DisposeBag()
        let updateSuccessExpect = expectation(description: "expect update permission success")
        mockAPI.result = .success(.success(permission: "SUCCESS_MODEL"))
        service.updateUserPermission()
            .subscribe { response in
                switch response {
                case .success:
                    break
                case .noPermission:
                    XCTFail("un-expected no permission found")
                }
                updateSuccessExpect.fulfill()
            } onError: { error in
                XCTFail("un-expected other error found: \(error)")
                updateSuccessExpect.fulfill()
            }
            .disposed(by: testBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(service.ready)
        XCTAssertTrue(service.hasPermission)
    }

    func testMonitorPermissionChanged() {
        var monitorBag = DisposeBag()

        let mockAPI = MockUserPermissionAPI()
        let service = UserPermissionServiceImpl(permissionAPI: mockAPI,
                                                validatorType: MockUserPermissionValidator<MockAllowResponseProvider>.self,
                                                permissionSDK: MockPermissionSDK(),
                                                sessionID: "MOCK_SESSION_ID")
        // 刚初始化时，监听不到 updated 事件
        let notReadyExpect = expectation(description: "expect no event when service not ready")
        notReadyExpect.isInverted = true
        service.onPermissionUpdated.subscribe(onNext: {_ in
            notReadyExpect.fulfill()
        })
        .disposed(by: monitorBag)
        waitForExpectations(timeout: 2)
        XCTAssertFalse(service.ready)
        XCTAssertFalse(service.hasPermission)
        XCTAssertNil(service.permissionResponse)
        // 获取用户权限失败，无监听事件
        monitorBag = DisposeBag()
        mockAPI.result = .failure(MockError.expectedFailure)
        let updateFailedExpect = expectation(description: "expect no event when service update failed")
        updateFailedExpect.isInverted = true
        service.onPermissionUpdated.subscribe(onNext: {_ in
            updateFailedExpect.fulfill()
        })
        .disposed(by: monitorBag)
        service.updateUserPermission().subscribe().disposed(by: monitorBag)
        waitForExpectations(timeout: 2)
        XCTAssertFalse(service.ready)
        XCTAssertFalse(service.hasPermission)
        XCTAssertNil(service.permissionResponse)
        // 获取用户权限，但需要密码、申请、无权限，能收到一次更新事件
        monitorBag = DisposeBag()
        mockAPI.result = .success(.noPermission(permission: nil, statusCode: .passwordRequired, applyUserInfo: nil))
        let noPermissionExpect = expectation(description: "expect no event when service update with no permission")
        service.onPermissionUpdated.subscribe(onNext: { _ in
            noPermissionExpect.fulfill()
        })
        .disposed(by: monitorBag)
        service.updateUserPermission().subscribe().disposed(by: monitorBag)
        waitForExpectations(timeout: 2)
        XCTAssertTrue(service.ready)
        XCTAssertFalse(service.hasPermission)
        XCTAssertEqual(service.permissionResponse,
                       .noPermission(statusCode: .passwordRequired, applyUserInfo: nil))
        // 获取用户权限成功，收到一次更新事件
        monitorBag = DisposeBag()
        mockAPI.result = .success(.success(permission: "SUCCESS_MODEL"))
        let updateSuccessExpect = expectation(description: "expect one event when service update success")
        service.onPermissionUpdated.skip(1).subscribe(onNext: { _ in
            updateSuccessExpect.fulfill()
        })
        .disposed(by: monitorBag)
        service.updateUserPermission().subscribe().disposed(by: monitorBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(service.ready)
        XCTAssertTrue(service.hasPermission)
        XCTAssertEqual(service.permissionResponse, .success)
        // 获取用户权限成功后，再建立监听，收到一次重放事件
        monitorBag = DisposeBag()
        let replayUpdatedExpect = expectation(description: "expect one event when service replay updated event")
        service.onPermissionUpdated.subscribe(onNext: { _ in
            replayUpdatedExpect.fulfill()
        })
        .disposed(by: monitorBag)
        waitForExpectations(timeout: 1)
        XCTAssertTrue(service.ready)
        XCTAssertTrue(service.hasPermission)
    }

    func testValidateBlockByUserPermission() {
        class MockSDK: MockPermissionSDK {
            override func validate(request: PermissionRequest) -> PermissionResponse {
                XCTAssertEqual(request.entity, .ccm(token: "MOCK_TOKEN", type: .docX))
                XCTAssertEqual(request.extraInfo.entityTenantID, "MOCK_TENANT_ID")
                XCTAssertEqual(request.operation, .copyContent)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertNil(request.exemptConfig)
                return .allow(traceID: "MOCK_TRACE_ID") { _, _ in }
            }

            override func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void) {
                completion(validate(request: request))
            }
        }

        enum ForbiddenResponseProvider: MockResponseProviderType {
            static func getResponse(model: String?, request: PermissionRequest, isAsync: Bool) -> PermissionValidatorResponse {
                XCTAssertNil(model)
                XCTAssertEqual(request.entity, .ccm(token: "MOCK_TOKEN", type: .docX))
                XCTAssertEqual(request.extraInfo.entityTenantID, "MOCK_TENANT_ID")
                XCTAssertEqual(request.operation, .copyContent)
                XCTAssertEqual(request.bizDomain, .ccm)
                XCTAssertNil(request.exemptConfig)
                if isAsync {
                    return .forbidden(denyType: .blockByUserPermission(reason: .blockByServer(code: 400)),
                                      customAction: { _, _ in })
                } else {
                    return .forbidden(denyType: .blockByUserPermission(reason: .blockByServer(code: 300)),
                                      customAction: { _, _ in })
                }
            }
        }

        let mockAPI = MockUserPermissionAPI()
        mockAPI.entity = .ccm(token: "MOCK_TOKEN", type: .docX)
        let service = UserPermissionServiceImpl(permissionAPI: mockAPI,
                                                validatorType: MockUserPermissionValidator<ForbiddenResponseProvider>.self,
                                                permissionSDK: MockSDK(),
                                                sessionID: "MOCK_SESSION_ID")
        service.update(tenantID: "MOCK_TENANT_ID")
        let response = service.validate(operation: .copyContent, bizDomain: .ccm)
        response.assertEqual(denyType: .blockByUserPermission(reason: .blockByServer(code: 300)))

        let expect = expectation(description: "async validate block by user permission")
        service.asyncValidate(operation: .copyContent, bizDomain: .ccm) { response in
            response.assertEqual(denyType: .blockByUserPermission(reason: .blockByServer(code: 400)))
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testExemptValidateBlockBySDK() {
        class MockSDK: MockPermissionSDK {
            override func validate(request: PermissionRequest) -> PermissionResponse {
                XCTAssertEqual(request.entity, .ccm(token: "MOCK_TOKEN", type: .sheet))
                XCTAssertEqual(request.extraInfo, .default)
                let exemptContext = PermissionExemptContext[.duplicateSystemTemplate]
                XCTAssertEqual(request.operation, exemptContext.operation)
                XCTAssertEqual(request.bizDomain, exemptContext.bizDomain)
                XCTAssertEqual(request.exemptRules, exemptContext.rules)
                let denyType = PermissionResponse.DenyType.blockByFileStrategy
                return .forbidden(traceID: "MOCK_TRACE_ID", denyType: denyType, preferUIStyle: denyType.preferUIStyle) { _, _ in }
            }

            override func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void) {
                XCTAssertEqual(request.entity, .ccm(token: "MOCK_TOKEN", type: .sheet))
                XCTAssertEqual(request.extraInfo, .default)
                let exemptContext = PermissionExemptContext[.duplicateSystemTemplate]
                XCTAssertEqual(request.operation, exemptContext.operation)
                XCTAssertEqual(request.bizDomain, exemptContext.bizDomain)
                XCTAssertEqual(request.exemptRules, exemptContext.rules)
                let denyType = PermissionResponse.DenyType.blockBySecurityAudit
                completion(.forbidden(traceID: "MOCK_TRACE_ID", denyType: denyType, preferUIStyle: denyType.preferUIStyle) { _, _ in })
            }
        }

        enum ForbiddenResponseProvider: MockResponseProviderType {
            static func getResponse(model: String?, request: PermissionRequest, isAsync: Bool) -> PermissionValidatorResponse {
                XCTFail("user permission validator should not be call when block by SDK")
                return .forbidden(denyType: .blockByUserPermission(reason: .blockByServer(code: 300)),
                                  customAction: { _, _ in })
            }
        }

        let mockAPI = MockUserPermissionAPI()
        mockAPI.entity = .ccm(token: "MOCK_TOKEN", type: .sheet)
        let service = UserPermissionServiceImpl(permissionAPI: mockAPI,
                                                validatorType: MockUserPermissionValidator<ForbiddenResponseProvider>.self,
                                                permissionSDK: MockSDK(),
                                                sessionID: "MOCK_SESSION_ID")
        let response = service.validate(exemptScene: .duplicateSystemTemplate)
        response.assertEqual(denyType: .blockByFileStrategy)

        let expect = expectation(description: "async validate block by SDK")
        service.asyncValidate(exemptScene: .duplicateSystemTemplate) { response in
            response.assertEqual(denyType: .blockBySecurityAudit)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testExemptUserPermission() {
        class MockSDK: MockPermissionSDK {
            override func getExemptRequest(entity: PermissionRequest.Entity,
                                           exemptScene: PermissionExemptScene,
                                           extraInfo: PermissionExtraInfo) -> PermissionRequest {
                XCTAssertEqual(entity, .ccm(token: "MOCK_BASE_TOKEN", type: .bitable))
                XCTAssertEqual(exemptScene, .duplicateSystemTemplate)
                XCTAssertEqual(extraInfo.entityTenantID, "MOCK_TENANT_ID")
                let rules = PermissionExemptRules(shouldCheckUserPermission: false)
                return PermissionRequest(entity: entity,
                                         operation: .copyContent,
                                         bizDomain: .ccm,
                                         extraInfo: extraInfo,
                                         exemptConfig: rules)
            }
        }

        enum ForbiddenResponseProvider: MockResponseProviderType {
            static func getResponse(model: String?, request: PermissionRequest, isAsync: Bool) -> PermissionValidatorResponse {
                XCTFail("user permission validator should not be call when exempted")
                return .forbidden(denyType: .blockByUserPermission(reason: .blockByServer(code: 300)),
                                  customAction: { _, _ in })
            }
        }

        let mockAPI = MockUserPermissionAPI()
        mockAPI.entity = .ccm(token: "MOCK_BASE_TOKEN", type: .bitable)
        let service = UserPermissionServiceImpl(permissionAPI: mockAPI,
                                                validatorType: MockUserPermissionValidator<ForbiddenResponseProvider>.self,
                                                permissionSDK: MockSDK(),
                                                sessionID: "MOCK_SESSION_ID")
        service.update(tenantID: "MOCK_TENANT_ID")
        let response = service.validate(exemptScene: .duplicateSystemTemplate)
        switch response.result {
        case .allow:
            break
        case .forbidden:
            XCTFail("un-expected forbidden found: \(response)")
        }

        let expect = expectation(description: "async validate block by SDK")
        service.asyncValidate(exemptScene: .duplicateSystemTemplate) { response in
            switch response.result {
            case .allow:
                break
            case .forbidden:
                XCTFail("un-expected forbidden found: \(response)")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
