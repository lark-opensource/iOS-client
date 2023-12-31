//
//  SecretPermissionInfoViewModelTests.swift
//  SKCommon-Unit-Tests
//
//  Created by tanyunpeng on 2023/4/28.
//  


import XCTest
import OHHTTPStubs
@testable import SKCommon
import RxSwift
import RxRelay
import SKFoundation
import SwiftyJSON
import SKInfra

class SecretPermissionInfoViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getSecLabelList)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("secretPermissionVisible.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    func testRequestVisibleSuccess() {
        let secInfo = ["sec_label": ""]
        let sut = SecretPermissionInfoViewModel(level: SecretLevel(json: JSON(secInfo)), wikiToken: nil, token: "123", type: 1, permStatistic: nil, viewFrom: .moreMenu)
        let sutVC = SecretPermissionDetailViewController(viewModel: sut)
        let expect = expectation(description: "test CollaboratorSearchViewModel")
        sutVC.request()
        async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(sut.dataSource.count > 0)
    }

  
    func async(completion: @escaping() -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: completion)
    }
}

