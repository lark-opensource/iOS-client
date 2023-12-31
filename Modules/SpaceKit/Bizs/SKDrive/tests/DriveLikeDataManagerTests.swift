//
//  DriveLikeDataManagerTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/6/16.
//  


import XCTest
import SKCommon
import SKFoundation
import OHHTTPStubs
@testable import SKDrive
import SKInfra

class DriveLikeDataManagerTests: XCTestCase {
    
    private var testObj: DriveLikeDataManager?
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        
        let docsInfo = DocsInfo(type: .unknownDefaultType, objToken: "fakeToken")
        testObj = DriveLikeDataManager(docInfo: docsInfo, canShowCollaboratorInfo: true)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
    }

    func testLoadLikeData() {
        
        // 点赞数量
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.likesCount)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("likeCount.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        
        let expect = expectation(description: "test drive like count")
        testObj?.forceLoadLikeData {
            if let count = self.testObj?.count, count == 2 {
                XCTAssertEqual(count, 2)
            } else {
                XCTFail("user count is not expected!")
            }
            expect.fulfill()

        }
        wait(for: [expect], timeout: 2)
    }
    
    func testLike() {
        // 点赞
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.like)
            return contain
        }, response: { _ in
            let string = """
            {
                "code": -1,
                "data": {
                    "id": "7109747247776202754"
                },
                "msg": "Failed"
            }
            """
            let data = string.data(using: .utf8) ?? Data()
            return HTTPStubsResponse(data: data,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test like")
        testObj?.like(completion: { succ in
            expect.fulfill()
            XCTAssert(!succ)
        })
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
    
    func testDislike() {
        // 取消点赞
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.dislike)
            return contain
        }, response: { _ in
            let string = """
            {
                "code": -1,
                "data": {},
                "msg": "Failed"
            }
            """
            let data = string.data(using: .utf8) ?? Data()
            return HTTPStubsResponse(data: data,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "dislike")
        testObj?.dislike(completion: { succ in
            expect.fulfill()
            XCTAssert(!succ)
        })
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
    
    func testGetUserInfo() {

        // 点赞数量
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.likesCount)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("likeCount.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })

        // 点赞用户列表
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.likesList)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("likeList.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        
        let expect = expectation(description: "test drive like list")
        testObj?.forceLoadLikeData {
            let user0 = self.testObj?.getUserInfo(with: 0)
            let user1 = self.testObj?.getUserInfo(with: 1)
            if user0?.name == "张三", user1?.name == "李四" {
                XCTAssertTrue(true)
            } else {
                XCTFail("userInfo is not expected!")
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 4) { error in
            XCTAssertNil(error)
        }
    }
}
