//
//  TemplateDataProviderTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/10/12.
//  


import XCTest
import OHHTTPStubs
@testable import SKCommon
import RxSwift
import RxCocoa
import SKFoundation
import SKInfra

class TemplateDataProviderTests: XCTestCase {

    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testSearchEcologyTemplatesParams() {
        let expect = expectation(description: "test params")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.searchTemplate)
            return contain
        }, response: { request in
            expect.fulfill()
            let queryParameters = request.url?.queryParameters ?? [:]
            XCTAssertNotNil(queryParameters["obj_type"])
            XCTAssertNotNil(queryParameters["offset"])
            XCTAssertNotNil(queryParameters["page_count"])
            XCTAssertNotNil(queryParameters["keyword"])
            XCTAssertNotNil(queryParameters["buffer"])
            XCTAssertNotNil(queryParameters["source"])
            XCTAssertNotNil(queryParameters["docx_template"])
            XCTAssertNotNil(queryParameters["user_recommend"])
            XCTAssertNotNil(queryParameters["ecology"])
            
            return HTTPStubsResponse(jsonObject: ["code": 4, "msg": "failure", "data": [:]], statusCode: 200, headers: ["Content-Type": "application/json"])
        })
        let dataProvider = TemplateDataProvider()
        
        dataProvider.searchTemplates(
            keyword: "searchKey",
            offset: 0,
            docsType: .docX,
            docxEnable: true,
            tabType: .gallery,
            userRecommend: false,
            buffer: ""
        ).subscribe { _ in
            
        }.disposed(by: disposeBag)
        wait(for: [expect], timeout: 2)
    }
    
    func testFetchTemplatesParams() {
        let expect = expectation(description: "test params")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getCategoryTemplateList)
            return contain
        }, response: { request in
            expect.fulfill()
            let queryParameters = request.url?.queryParameters ?? [:]
            XCTAssertNotNil(queryParameters["version"])
            XCTAssertNotNil(queryParameters["platform"])
            XCTAssertNotNil(queryParameters["template_collection"])
            XCTAssertNotNil(queryParameters["docx_template"])
            XCTAssertNotNil(queryParameters["category_id"])
            XCTAssertNotNil(queryParameters["page_size"])
            XCTAssertNotNil(queryParameters["page_number"])
            XCTAssertNotNil(queryParameters["ecology"])
            
            return HTTPStubsResponse(jsonObject: ["code": 4, "msg": "failure", "data": [:]], statusCode: 200, headers: ["Content-Type": "application/json"])
        })
        let dataProvider = TemplateDataProvider()
        
        
        dataProvider.fetchTemplates(of: "xx", at: 0, pageSize: nil, docsType: .docX, docxEnable: true)
                     .subscribe { _ in
            
                     }.disposed(by: disposeBag)
        wait(for: [expect], timeout: 2)
    }
    
    func testFetchCustomTemplates() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getCustomTemplate)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("template_custom.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "testFetchCustomTemplates")
        let dataProvider = TemplateDataProvider()
        dataProvider.fetchCustomTemplates(objType: 1, dataType: nil, index: "0")
            .subscribe(onNext: { model in
                expect.fulfill()
                XCTAssertFalse(model.own.isEmpty)
                XCTAssertFalse(model.share.isEmpty)
                for model in model.own {
                    XCTAssertEqual(model.tag, TemplateModel.Tag.customOwn)
                }
                for model in model.share {
                    XCTAssertEqual(model.tag, TemplateModel.Tag.customShare)
                }
                
            }).disposed(by: disposeBag)
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
}
