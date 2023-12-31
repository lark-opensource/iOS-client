//
//  UserPermissionPushTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/5/15.
//

import Foundation
import XCTest
import SpaceInterface
import RxSwift
@testable import SKPermission
import SKCommon
import SKFoundation

private class MockStablePushManager: StablePushManagerProtocol {
    weak var delegate: StablePushManagerDelegate?
    func push(data: [String: Any], tag: String) {
        delegate?.stablePushManager(self, didReceivedData: data, forServiceType: tag, andTag: tag)
    }
    func register(with handler: StablePushManagerDelegate) {
        self.delegate = handler
    }
    func unRegister() {
        self.delegate = nil
    }
}

private class MockCommonPushManager: PermissionCommonPushManager {

    weak var delegate: CommonPushDataDelegate?
    func push(data: [String: Any]) {
        delegate?.didReceiveData(response: data)
    }
    func register(with handler: CommonPushDataDelegate) {
        self.delegate = handler
    }
    func unRegister() {
        self.delegate = nil
    }
}

final class UserPermissionPushTests: XCTestCase {

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

    func testRegister() {
        let mockStableManager = MockStablePushManager()
        let mockCommonManager = MockCommonPushManager()
        let service = MockUserPermissionService()
        var pushWrapper: UserPermissionServicePushWrapper? = UserPermissionServicePushWrapper(backing: service,
                                                                                              objToken: "MOCK_TOKEN",
                                                                                              objType: .docX,
                                                                                              stablePushManager: mockStableManager,
                                                                                              commonPushManager: mockCommonManager)
        XCTAssertNotNil(mockStableManager.delegate)
        XCTAssertNotNil(mockCommonManager.delegate)
        pushWrapper = nil
        XCTAssertNil(mockStableManager.delegate)
        XCTAssertNil(mockCommonManager.delegate)
    }

    func testPush() {
        class MockService: MockUserPermissionService {
            var updatePermissionExpect: XCTestExpectation?
            override func updateUserPermission() -> Single<UserPermissionResponse> {
                updatePermissionExpect?.fulfill()
                return .just(.success)
            }
        }
        let mockStableManager = MockStablePushManager()
        let mockCommonManager = MockCommonPushManager()
        let service = MockService()
        let pushWrapper = UserPermissionServicePushWrapper(backing: service,
                                                           objToken: "MOCK_TOKEN",
                                                           objType: .docX,
                                                           stablePushManager: mockStableManager,
                                                           commonPushManager: mockCommonManager)

        XCTAssertEqual(pushWrapper.pushFileToken, "MOCK_TOKEN")
        XCTAssertEqual(pushWrapper.pushFileType, DocsType.docX.rawValue)
        var updateExpect = expectation(description: "expect call update user permission when stable push")
        service.updatePermissionExpect = updateExpect
        mockStableManager.push(data: [:], tag: "")
        waitForExpectations(timeout: 1)

        updateExpect = expectation(description: "expect call update user permission when common push")
        service.updatePermissionExpect = updateExpect
        mockCommonManager.push(data: [:])
        waitForExpectations(timeout: 1)
    }

    func testWrapperPassthrough() {
        let mockStableManager = MockStablePushManager()
        let mockCommonManager = MockCommonPushManager()
        let service = MockUserPermissionService()
        let pushWrapper = UserPermissionServicePushWrapper(backing: service,
                                                           objToken: "MOCK_TOKEN",
                                                           objType: .docX,
                                                           stablePushManager: mockStableManager,
                                                           commonPushManager: mockCommonManager)

        service.ready = true
        XCTAssertTrue(pushWrapper.ready)

        let permissionUpdatedExpect = expectation(description: "onPermissionUpdated passthrough")
        service.onPermissionUpdated = .just(.noPermission(statusCode: .passwordRequired, applyUserInfo: nil))
        pushWrapper.onPermissionUpdated.subscribe(onNext: { response in
            XCTAssertEqual(response, .noPermission(statusCode: .passwordRequired, applyUserInfo: nil))
            permissionUpdatedExpect.fulfill()
        })
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)

        service.permissionResponse = .noPermission(statusCode: .reportError, applyUserInfo: nil)
        XCTAssertEqual(pushWrapper.permissionResponse, .noPermission(statusCode: .reportError, applyUserInfo: nil))

        service.updateResponse = .noPermission(statusCode: .unknown(code: 300), applyUserInfo: nil)
        let updateExpect = expectation(description: "updateUserPermission() passthrough")
        pushWrapper.updateUserPermission().subscribe(onSuccess: { response in
            XCTAssertEqual(response, .noPermission(statusCode: .unknown(code: 300), applyUserInfo: nil))
            updateExpect.fulfill()
        })
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)

        service.syncResponse = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockByFileStrategy, preferUIStyle: .hidden) { _, _ in }
        let syncResponse = pushWrapper.validate(operation: .upload, bizDomain: .ccm)
        syncResponse.assertEqual(denyType: .blockByFileStrategy, preferUIStyle: .hidden)

        service.syncExemptResponse = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockByDLPDetecting, preferUIStyle: .disabled) { _, _ in }
        let syncExemptResponse = pushWrapper.validate(exemptScene: .duplicateSystemTemplate)
        syncExemptResponse.assertEqual(denyType: .blockByDLPDetecting, preferUIStyle: .disabled)

        service.asyncResponse = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockByUserPermission(reason: .blockByServer(code: 200)),
                                           preferUIStyle: .default) { _, _ in }
        let asyncExpect = expectation(description: "asyncValidate passthrough")
        pushWrapper.asyncValidate(operation: .upload, bizDomain: .ccm) { response in
            response.assertEqual(denyType: .blockByUserPermission(reason: .blockByServer(code: 200)),
                                 preferUIStyle: .default)
            asyncExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

        service.asyncExemptResponse = .forbidden(traceID: "MOCK_TRACE_ID",
                                                 denyType: .blockBySecurityAudit,
                                                 preferUIStyle: .default) { _, _ in }
        let asyncExemptExpect = expectation(description: "asyncValidate exempt passthrough")
        pushWrapper.asyncValidate(exemptScene: .duplicateSystemTemplate) { response in
            response.assertEqual(denyType: .blockBySecurityAudit,
                                 preferUIStyle: .default)
            asyncExemptExpect.fulfill()
        }
        waitForExpectations(timeout: 1)

        pushWrapper.update(tenantID: "MOCK_TENANT_ID")
        XCTAssertEqual(service.tenantID, "MOCK_TENANT_ID")
    }
}
