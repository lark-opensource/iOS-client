//
//  DocsFeedViewModelUITests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon

class DocsFeedViewModelUITests: XCTestCase {

    /// 被测对象
    var testObj: DocsFeedViewModel!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        testObj = DocsFeedViewModel(api: MockDocsFeedAPI(),
                                    from: FeedFromInfo(),
                                    docsInfo: DocsInfo(type: .unknownDefaultType, objToken: ""),
                                    param: nil,
                                    controller: UIViewController())
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testShouldDisplayRedDot() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let mockData = MockFeedCommentCellDataSource()
        mockData.messageId = "testId"
        
        testObj.readedMessages["testId"] = nil
        mockData.showRedDot = true
        let result1 = testObj.shouldDisplayRedDot(cell: UITableViewCell(), data: mockData)
        XCTAssert(result1 == true)
        
        testObj.readedMessages["testId"] = nil
        mockData.showRedDot = false
        let result2 = testObj.shouldDisplayRedDot(cell: UITableViewCell(), data: mockData)
        XCTAssert(result2 == false)
        
        testObj.readedMessages["testId"] = true
        mockData.showRedDot = true
        let result3 = testObj.shouldDisplayRedDot(cell: UITableViewCell(), data: mockData)
        XCTAssert(result3 == false)
        
        testObj.readedMessages["testId"] = true
        mockData.showRedDot = false
        let result4 = testObj.shouldDisplayRedDot(cell: UITableViewCell(), data: mockData)
        XCTAssert(result4 == false)
    }

}

class MockFeedCommentCellDataSource: FeedCellDataSource {
    
    /// 返回图片urlString 以及占位图
    var avatarResouce: (url: String?, placeholder: UIImage?, defaultDocsImage: UIImage?) { (nil, nil, nil) }
    
    var titleText: String = ""
    
    var quoteText: String?
    
    /// 返回评论内容， 因处理耗时， 可能是异步的，需要通过block返回
    func getContentConfig(result: @escaping (FeedMessageContent) -> Void) {}
    
    /// 返回翻译内容，同上。
    func getTranslateConfig(result: @escaping (FeedMessageContent) -> Void) {}
    
    /// 返回时间，同上。
    func getTime(time: @escaping (String) -> Void) {}
    
    var showRedDot: Bool = true
    
    var cellIdentifier: String { "" }
    
    var messageId = ""
    
    var contentCanCopy: Bool = false
}
