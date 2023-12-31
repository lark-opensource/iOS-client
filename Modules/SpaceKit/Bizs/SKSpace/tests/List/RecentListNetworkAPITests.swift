//
//  RecentListNetworkAPITests.swift
//  SKSpace-Unit-Tests
//
//  Created by zenghao on 2023/1/31.
//

import XCTest
@testable import SKSpace
import SwiftyJSON
import SKFoundation
import RxSwift
import OHHTTPStubs
import SKCommon
import SpaceInterface
import SKInfra

final class RecentListNetworkAPITests: XCTestCase {

    private var bag = DisposeBag()
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        bag = DisposeBag()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }
    
    /// {"entities":[{"obj_type":16,"obj_token":"wikbcphDiYf3VCcwsFUtHVslClc"}]}

    func testDeleteRecentAPIV2() throws {
        let mockToken = "MOCK_TOKEN"
        let mockType = DocsType.docX
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.deleteRecentFileByObjTokenV2)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: ["code": 0, "data": [:], "msg": "Success"],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let bodyString = String(data: body, encoding: .utf8) else {
                XCTFail("request body not found")
                return response
            }
            return response
        }

        let expect = expectation(description: "test report folder")
        StandardRecentListAPI.removeFromRecentList(objToken: mockToken, docType: mockType)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected failed: \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 2)
    }

    
}
