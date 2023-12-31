//
//  DocsVersionsPanelViewModelTests.swift
//  SKCommon-Unit-Tests
//
//  Created by GuoXinyi on 2022/12/6.
//

import XCTest
import OHHTTPStubs
@testable import SKCommon
import RxSwift
import RxCocoa
import SKFoundation
import SKInfra

class DocsVersionsPanelViewModelTests: XCTestCase {
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }
    
    func testFetchVersionData() {
        let expect = expectation(description: "test params")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getVersionData)
            return contain
        }, response: { request in
            expect.fulfill()
            let queryParameters = request.url?.queryParameters ?? [:]
            
            return HTTPStubsResponse(jsonObject: ["code": 400, "msg": "fail", "data": queryParameters], statusCode: 200, headers: ["Content-Type": "application/x-www-form-urlencoded"])
        })
        
        let pannelViewModel = DocsVersionsPanelViewModel(token: "WTnodP7eaoJ4pUxPOaqcU0qfnvf", type: .docX, fromSource: FromSource.sourceVersionList)
        pannelViewModel.loadData(loadMore: false)
        wait(for: [expect], timeout: 2)
    }
}
