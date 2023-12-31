//
//  OPPluginLocationSearchPOITests.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/12/15.
//

import XCTest
import OPUnitTestFoundation
@testable import OPPlugin

@available(iOS 13.0, *)
final class OPPluginLocationSearchPOITests: XCTestCase {

    private var testUtils = OpenPluginGadgetTestUtils()
    
    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        
    }
    
    func test_searchPOI_success() throws {
        let params:[AnyHashable : Any] = ["latitude":40.015011,"longitude":116.352195,"radius":100]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "searchPOI", params: params) { response in
            switch response {
            case .success(_):
                exp.fulfill()
            case .failure(error: let error):
                XCTFail(error.description)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }
}
