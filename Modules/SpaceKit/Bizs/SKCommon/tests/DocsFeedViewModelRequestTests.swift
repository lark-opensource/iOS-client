//
//  DocsFeedViewModelRequestTests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/15.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon
import OHHTTPStubs
import RxSwift
import RxRelay
import HandyJSON
import SKFoundation
import SKInfra

class DocsFeedViewModelRequestTests: XCTestCase {

    let disposeBag = DisposeBag()
    
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCacheValid() {
        
        let testObj = createTestObject()
        
        testObj.output?.data.subscribe(onNext: { (element: FeedDataType) in
            if case .cache(let models) = element {
                XCTAssert(models.count == 14)
            } else {
                XCTFail("FeedData is abnormal：\(element)")
            }
        }, onError: { error in
            XCTFail(error.localizedDescription)
        }).disposed(by: disposeBag)
        
        let path = Bundle(for: type(of: self)).path(forResource: "feed_response", ofType: "json")!
        let string = (try? String(contentsOf: URL(fileURLWithPath: path))) ?? ""
        let jsonData = string.data(using: .utf8) ?? Data()
        let fullDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        let data_obj = fullDict?["data"] as? [String: Any]
        let list_obj = (data_obj?["message"] as? [[String: Any]]) ?? []
        let list_data = (try? JSONSerialization.data(withJSONObject: list_obj, options: [])) ?? Data()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let list: [FeedMessageModel] = (try? decoder.decode([FeedMessageModel].self, from: list_data)) ?? []
        
        testObj.feedCache.setCache(list)
        testObj.fetchCache()
    }
    
    func testRequestFeedData() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let testObj = createTestObject()
        
        let requestExpectation = self.expectation(description: "DocsFeedViewModelRequestTest request failed")
        
        testObj.output?.data.subscribe(onNext: { (element: FeedDataType) in
            if case .server(let models) = element, models.count == 14 {
                requestExpectation.fulfill()
            } else {
                XCTFail("FeedData is abnormal：\(element)")
            }
        }, onError: { error in
            XCTFail(error.localizedDescription)
        }).disposed(by: disposeBag)
        
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getFeedV2)
            return contain
        }, response: { _ in
            let resp =
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("feed_response.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
            return resp
        })
        
        testObj.fetchServiceData()
        
        wait(for: [requestExpectation], timeout: 10)
    }
    
    private func createTestObject() -> DocsFeedViewModel {
        let testObj = DocsFeedViewModel(api: MockDocsFeedAPI(),
                                        from: FeedFromInfo(),
                                        docsInfo: DocsInfo(type: .unknownDefaultType, objToken: ""),
                                        param: nil,
                                        controller: UIViewController())
        
        let trigger = BehaviorRelay<[String: Any]>(value: [:])
        let eventDrive = PublishRelay<FeedPanelViewController.Event>()
        let input = DocsFeedViewModel.Input(trigger: trigger, eventDrive: eventDrive, scrollEndRelay: PublishRelay<[IndexPath]>())
        _ = testObj.transform(input: input)
        return testObj
    }
}
