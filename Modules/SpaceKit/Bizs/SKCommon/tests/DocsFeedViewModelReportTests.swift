//
//  DocsFeedViewModelReportTests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon

class DocsFeedViewModelReportTests: XCTestCase {
    
    /// 被测对象
    var testObj: DocsFeedViewModel!
    
    var timeoutExpectation: XCTestExpectation!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        testObj = DocsFeedViewModel(api: MockDocsFeedAPI(),
                                    from: FeedFromInfo(),
                                    docsInfo: DocsInfo(type: .unknownDefaultType, objToken: ""),
                                    param: nil,
                                    controller: UIViewController())
        
        FeedTimeStage.allCases.enumerated().forEach { (i, stage) in
            self.testObj.timeStamp[stage] = TimeInterval(i)
        }
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetStageTime() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let cases = FeedTimeStage.allCases
        
        let indexA = (0 ..< cases.count).randomElement()!
        let indexB = (0 ..< cases.count).randomElement()!
        
        let caseA = cases[indexA]
        let caseB = cases[indexB]
        
        let time = testObj.getStageTime(from: caseA, to: caseB)
        XCTAssert(time == TimeInterval(indexB - indexA))
    }
    
    func testRecordTimeout() {
        
        timeoutExpectation = self.expectation(description: "DocsFeedViewModelReportTest 超时预期异常")
        
        testObj.recordTimeout(1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.testObj.status == .timeout {
                self.timeoutExpectation.fulfill()
            } else {
                XCTFail("status is NOT `timeout`")
            }
        }
        
        // 最多等待秒数
        waitForExpectations(timeout: 3) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
}
