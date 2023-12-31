//
//  DocsInfoDetailHelperTests.swift
//  SKCommon-Unit-Tests
//
//  Created by huayufan on 2022/3/21.
//  


import XCTest
import OHHTTPStubs
@testable import SKCommon
import RxSwift
import RxCocoa
import SKFoundation
import SpaceInterface
import SKInfra
class DocsInfoDetailHelperTests: XCTestCase {

    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testFetchEntityInfo() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getEntityInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("v2_entity_info.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]).requestTime(1, responseTime: 0.5)
        })

        let expect = expectation(description: "test fetch doc entity")
        DocsInfoDetailHelper.fetchEntityInfo(objToken: "bascnHvte81F1Ww1HZgMExt1yKb", objType: DocsType.bitable)
            .subscribe { _ in
                XCTAssert(true)
                expect.fulfill()
            } onError: { _ in
                XCTAssert(false)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testFetchDetail() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains("api/meta/?token")
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("bitable_meta.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]).requestTime(1, responseTime: 0.5)
        })
        let expect = expectation(description: "test fetch detail")
        DocsInfoDetailHelper.fetchDetail(token: "bascnCXhRYVm2g98dcEyUd8X5wh", type: .bitable)
            .subscribe { _ in
                XCTAssert(true)
                expect.fulfill()
            } onError: { _ in
                XCTAssert(false)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testUpdateDocsInfo() {
        let docsInfo = DocsInfo(type: .bitable, objToken: "xxxx")
        let detailInfo = ["template_type": 1]
        DocsInfoDetailHelper.update(docsInfo: docsInfo, detailInfo: detailInfo, needUpdateStar: false)
        XCTAssert(docsInfo.templateType == .pgcTemplate)
    }
    
    func testDisplayName() {
        let docsInfo = DocsInfo(type: .docX, objToken: "doxcnXXXXXXXXX")
        let alias = UserAliasInfo(displayName: "MOCK_DISPLAY_NAME", i18nDisplayNames: ["zh_cn": "MOCK_CN_DISPLAY_NAME"])
        let detailInfo: [String: Any] = [
            "owner_user_display_name": [
                "value": alias.displayName ?? "",
                "i18n_value": alias.i18nDisplayNames
            ]
        ]
        DocsInfoDetailHelper.update(docsInfo: docsInfo, detailInfo: detailInfo, needUpdateStar: false)
        XCTAssertEqual(docsInfo.ownerAliasInfo, alias)
    }
}
