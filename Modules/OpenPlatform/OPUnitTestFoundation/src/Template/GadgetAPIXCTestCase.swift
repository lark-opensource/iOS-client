//
//  GadgetAPIXCTestCase.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/20.
//

import XCTest
import LarkOpenAPIModel

// 简单API调通测试
@available(iOS 13.0, *)
open class GadgetAPIXCTestCase: APIXCTestCase { }

@available(iOS 13.0, *)
open class WebAppAPIXCTestCase: APIXCTestCase {
    private var _innerTestUtils = OpenPluginWebAppTestUtils()
    public override var testUtils: OpenPluginTestUtils {
        get {
            return _innerTestUtils
        }
        set {
            if let newValue = newValue as? OpenPluginWebAppTestUtils {
                _innerTestUtils = newValue
            } else {
                fatalError()
            }
        }
    }
}

@available(iOS 13.0, *)
open class APIXCTestCase: XCTestCase {
    
    open var testUtils: OpenPluginTestUtils = OpenPluginGadgetTestUtils()
    
    @inlinable
    @inline(__always)
    open func success_async_api_test(apiName: String, params: [AnyHashable: Any] = [:], success: ((OpenAPIBaseResult?) -> Void)? = nil) {
        let exp = XCTestExpectation(description: "\(#function)_\(apiName)")
        testUtils.asyncCall(apiName: apiName, params: params) { response in
            switch response.toTestReponse() {
            case .success(let data):
                success?(data)
            case .failure(let error):
                XCTFail("\(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }
    
    @inlinable
    @inline(__always)
    open func failed_async_api_test(apiName: String, params: [AnyHashable: Any] = [:], failed: ((OpenAPIError) -> Void)? = nil) {
        let exp = XCTestExpectation(description: "\(#function)_\(apiName)")
        testUtils.asyncCall(apiName: apiName, params: params) { response in
            switch response.toTestReponse() {
            case .success(_):
                XCTFail("failed_api_test with \(apiName) should not be success!")
            case .failure(let error):
                failed?(error)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }
    
    @inlinable
    @inline(__always)
    open func can_call_async_api_test(apiName: String, params: [AnyHashable: Any] = [:]) {
        let exp = XCTestExpectation(description: "\(#function)_\(apiName)")
        testUtils.asyncCall(apiName: apiName, params: params) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }
    
    public func mockSchema() -> BDPSchema {
        let url = "sslocal://microapp?version=v2&app_id=cli_a24ebc88c8f9d013&ide_disable_domain_check=0&identifier=cli_a24ebc88c8f9d013&isdev=1&scene=1012&token=ODQ3ODE0OTgtYzk4OC00MjVmLTg1N2ItZjVjNTkyMDQ4NDhk&version_type=preview&start_page=page%2Fcomponent%2Findex%3Fb%3D123%252F456%2540&bdpsum=b50c0a5"
        let result = BDPSchema(url: URL(string: url), appType: .gadget)
        result?.appID = testUtils.appID
        result?.startPagePath = "page/component/index"
        return result!
    }
}
