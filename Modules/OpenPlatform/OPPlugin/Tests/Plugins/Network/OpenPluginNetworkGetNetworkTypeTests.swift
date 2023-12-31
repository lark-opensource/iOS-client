//
//  OpenPluginNetworkGetNetworkTypeTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/10.
//

import XCTest
import RustPB
import LarkRustClient
import LarkContainer
import LarkOpenAPIModel
import TTMicroApp
import OPUnitTestFoundation
@available(iOS 13.0, *)
final class OpenPluginNetworkGetNetworkTypeTests: OpenPluginNetworkTests {

    override var configFileName: String { "requestFile" }

    func test_api_can_be_called() throws {
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "getNetworkType", params: [:]) { response in
            switch response {
            case .success(data: _):
                exp.fulfill()
            case .failure(error: let error):
                XCTFail(error.description)
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }
}
