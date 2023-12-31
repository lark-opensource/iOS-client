//
//  FolderNetworkAPITests.swift
//  SKSpace-Unit-Tests
//
//  Created by Weston Wu on 2022/11/18.
//

import XCTest
@testable import SKSpace
import SwiftyJSON
import SKFoundation
import RxSwift
import OHHTTPStubs
import SKCommon
import SKInfra

final class FolderNetworkAPITests: XCTestCase {
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
    
    func testReportFolder() {
        let mockToken = "MOCK_TOKEN"
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceOpenReport)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: ["code": 0, "data": [:], "msg": "Success"],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let bodyString = String(data: body, encoding: .utf8) else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(bodyString, "obj_token=\(mockToken)&obj_type=0")
            return response
        }

        let expect = expectation(description: "test report folder")
        V2FolderListAPI.reportViewFolder(token: mockToken)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected failed: \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
}
