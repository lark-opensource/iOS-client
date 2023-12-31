//
//  OpenPluginHealthTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/9/27.
//

import XCTest

import LarkOpenAPIModel
import LarkOpenPluginManager
import OPUnitTestFoundation
import OPFoundation
import CoreMotion

@testable import OPPlugin

extension CMPedometer {
    @objc class func hook_isStepCountingAvailable() -> Bool { 
        true
    }
    
    @objc class func restricted_authorizationStatus() -> CMAuthorizationStatus {
        .restricted
    }
}

@available(iOS 13.0, *)
final class OpenPluginHealthTests: GadgetAPIXCTestCase {
    
    let apiName = "getStepCount"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_getStepCount_failed() throws {
        CMPedometer.lkw_swizzleOriginClassMethod(#selector(CMPedometer.isStepCountingAvailable), withHookClassMethod: #selector(CMPedometer.hook_isStepCountingAvailable))
        CMPedometer.lkw_swizzleOriginClassMethod(#selector(CMPedometer.authorizationStatus), withHookClassMethod: #selector(CMPedometer.restricted_authorizationStatus))
        defer {
            CMPedometer.lkw_swizzleOriginClassMethod(#selector(CMPedometer.isStepCountingAvailable), withHookClassMethod: #selector(CMPedometer.hook_isStepCountingAvailable))
            CMPedometer.lkw_swizzleOriginClassMethod(#selector(CMPedometer.authorizationStatus), withHookClassMethod: #selector(CMPedometer.restricted_authorizationStatus))
        }
        failed_async_api_test(apiName: apiName) { error in
            XCTAssertEqual(error.code.rawValue, OpenAPICommonErrorCode.systemAuthDeny.rawValue)
        }
    }
    
    func test() throws {
        failed_async_api_test(apiName: apiName) { error in
            XCTAssertEqual(error.code.rawValue, GetStepCountErrorCode.notAvailable.rawValue)
        }
    }
}

