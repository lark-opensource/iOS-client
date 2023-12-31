//
//  DocsFeedViewModelObservableTests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon
import RxSwift
import SwiftyJSON

class DocsFeedViewModelObservableTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    
    /// 完成解析的异步预期
    var didFinishModelMapping: XCTestExpectation!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        didFinishModelMapping = self.expectation(description: "DocsFeedViewModelObservableTest 未完成解析")
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMapFeedModel() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        do {
            let path = Bundle(for: type(of: self)).path(forResource: "feed_response", ofType: "json")!
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
            let listDict = (originDict["message"] as? [[String: Any]]) ?? []
            let observable = Observable.of(listDict)
            let mapped = observable.mapFeedModel(type: [FeedMessageModel].self, queue: DispatchQueue.main)
            mapped.subscribe(onNext: { [weak self] (elements: [FeedMessageModel]) in
                if elements.count == 14, elements.first?.replyId == "7070019092324827142" {
                    self?.didFinishModelMapping.fulfill()
                } else {
                    XCTFail("model parse failed：\(elements)")
                }
            }, onError: { error in
                XCTFail(error.localizedDescription)
            }).disposed(by: disposeBag)
        } catch {
            XCTFail("decode data failed")
        }
        
        
        // 最多等待秒数
        waitForExpectations(timeout: 10) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
}
