//
//  PermissionSDKUtilsTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/25.
//

import Foundation
@testable import SKPermission
import SKFoundation
import SpaceInterface
import XCTest

final class PermissionSDKUtilsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testConvertResponse() {
        let validatorResponse = PermissionValidatorResponse.allow {}
        let response = validatorResponse.finalResponse(traceID: "")
        switch response.result {
        case .allow:
            break
        case .forbidden:
            XCTFail("failed to convert ValidatorResponse: allow to PermissionResponse")
        }

        let denyTypes: [PermissionResponse.DenyType] = [
            .blockByDLPSensitive,
            .blockByDLPDetecting,
            .blockByFileStrategy,
            .blockBySecurityAudit,
            .blockByUserPermission(reason: .blockByServer(code: 200)),
            .blockByUserPermission(reason: .userPermissionNotReady),
            .blockByUserPermission(reason: .blockByCAC),
            .blockByUserPermission(reason: .unknown)
        ]

        denyTypes.forEach { expectDenyType in
            let completionExpect = expectation(description: "expect for custom action completion")
            let validatorResponse = PermissionValidatorResponse.forbidden(denyType: expectDenyType, preferUIStyle: expectDenyType.preferUIStyle) { _, _ in
                completionExpect.fulfill()
            }
            let response = validatorResponse.finalResponse(traceID: "")
            guard case let .forbidden(denyType, preferUIStyle) = response.result else {
                completionExpect.fulfill()
                XCTFail("failed to convert forbidden type: \(expectDenyType)")
                return
            }
            XCTAssertEqual(denyType, expectDenyType)
            XCTAssertEqual(preferUIStyle, expectDenyType.preferUIStyle)
            response.didTriggerOperation(controller: UIViewController(), nil)
            waitForExpectations(timeout: 1)
        }
    }
}
