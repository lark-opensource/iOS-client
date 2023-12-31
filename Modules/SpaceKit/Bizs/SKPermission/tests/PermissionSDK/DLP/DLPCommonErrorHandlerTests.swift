//
//  DLPCommonErrorHandlerTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/27.
//

import Foundation
import XCTest
@testable import SKPermission
import SpaceInterface
import SKFoundation
import SKResource

final class DLPCommonErrorHandlerTests: XCTestCase {

    private typealias Handler = DLPCommonErrorHandler
    private typealias BehaviorType = PermissionDefaultUIBehaviorType

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testSameTenantSensitive() {
        let result = Handler.getCommonErrorBehaviorType(token: "", userID: "", errorCode: .sameTenantSensitive)
        result.assertEqualTo(expect: .error(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed,
                                            allowOverrideMessage: false))
    }

    func testOtherTenantSensitive() {
        let result = Handler.getCommonErrorBehaviorType(token: "", userID: "", errorCode: .externalTenantSensitive)
        result.assertEqualTo(expect: .error(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed,
                                            allowOverrideMessage: false))
    }

    func testSameTenantDetecting() {
        // 没缓存，默认 15 分钟
        var result = Handler.getCommonErrorBehaviorType(token: "", userID: "", errorCode: .sameTenantDetecting)
        result.assertEqualTo(expect: .error(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(15),
                                            allowOverrideMessage: false))
    }

    func testOtherTenantDetecting() {
        // 没缓存，默认 15 分钟
        var result = Handler.getCommonErrorBehaviorType(token: "", userID: "", errorCode: .externalTenantDetecting)
        result.assertEqualTo(expect: .error(text: BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(15),
                                            allowOverrideMessage: false))
    }
}
