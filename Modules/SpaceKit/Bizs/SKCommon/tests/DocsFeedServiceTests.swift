//
//  DocsFeedServiceTests.swift
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

class DocsFeedServiceTests: XCTestCase {

    var mockURL: URL {
        return URL(string: "https://bytedance.feishu.cn/docs/doccni4jqvrtiJ5i6tHj7Y3p8gg")!
    }
    
    var mockToken = "doccni4jqvrtiJ5i6tHj7Y3p8gg"
    
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    func testMassDataRequest() {
        mockNetwork()
        let service = getDocsFeedServiceInstance()
        var count = 0
        let expect = expectation(description: "test request feed data")
        service.requestFeedData()
               .observeOn(MainScheduler.instance)
               .subscribe(onNext: { (data) in
                   if count == 0 { // 先渲染首屏
                       XCTAssertTrue(data.messages.count == 20)
                   } else {
                       XCTAssertTrue(data.messages.count > 20)
                       expect.fulfill()
                   }
                   count += 1
        }, onError: { error in
            XCTAssertNil(error)
        }).disposed(by: disposeBag)
     
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    
    func testRequestPendingStatus() {
        mockNetwork()
        let time = Date().timeIntervalSince1970 * 1000
        DocsFeedService.loadFeedData(url: mockURL, timestamp: time)
        let expect = expectation(description: "test request feed data status")
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
            let taskId = DocsFeedService.getTaskId(self.mockToken, DocsType.doc.rawValue, time)
            // pending态
            if case .pending(_) = DocsFeedService.tasks[taskId] {
                DocsFeedService.inspectPending(taskId: taskId) { _ in
                    expect.fulfill()
                }
            } else {
                XCTAssertTrue(false, "status is incorrect")
            }
        }

        waitForExpectations(timeout: 8) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRequestFulfillStatus() {
        mockNetwork()
        let time = Date().timeIntervalSince1970 * 1000
        DocsFeedService.loadFeedData(url: mockURL, timestamp: time)
        let expect = expectation(description: "test request feed data status")
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(4)) {
            let taskId = DocsFeedService.getTaskId(self.mockToken, DocsType.doc.rawValue, time)
            if case .fulfilled(_) = DocsFeedService.tasks[taskId] {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false, "status is incorrect")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 8) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRequestForbiddenStatus() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getFeedV2)
            return contain
        }, response: { _ in
            HTTPStubsResponse(jsonObject: ["code": 4, "msg": "failure", "data": [:]], statusCode: 200, headers: ["Content-Type": "application/json"])
        })
        let service = getDocsFeedServiceInstance()
        let expect = expectation(description: "test forbidden status")
        service.requestFeedData()
               .observeOn(MainScheduler.instance)
               .subscribe(onNext: { _ in
        }, onError: { error in
            if let err = error as? DocsFeedService.FeedError {
                XCTAssertEqual(err, DocsFeedService.FeedError.forbidden)
            } else {
                XCTAssertTrue(false, "status is incorrect")
            }
            expect.fulfill()
        }).disposed(by: disposeBag)
     
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
        
    }
    
    private func getDocsFeedServiceInstance() -> DocsFeedService {
        let from = FeedFromInfo()
        from.isFromLarkFeed = true
        from.record(.larkFeed)
        return DocsFeedService(DocsInfo(type: .doc, objToken: mockToken), from)
    }
    
    private func mockNetwork() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getFeedV2)
            return contain
        }, response: { _ in
            HTTPStubsResponse( // 数据大于20条
                fileAtPath: OHPathForFile("get_message.v3.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]).requestTime(1, responseTime: 0.5)
        })
    }
}
