//
//  FileInfoProviderTests.swift
//  SpaceDemoTests
//
//  Created by bupozhuang on 2022/2/15.
//  Copyright © 2022 Bytedance. All rights reserved.
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
@testable import SKDrive
import SKInfra

class DriveFileInfoProviderTests: XCTestCase {
    var bag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        // 没有设置baseURL，网路请求会中assert
        print("xxxx - setup")
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        print("xxxx - tearDown")
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }

    func testFetchFileInfoSucess() {
        // stub network dependency
        print("start setup http stubs")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveFileInfoSucc.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
                

        let sut = createSut()
        let expect = expectation(description: "test fetch fileInfo")

        sut.request(version: "newVersion").subscribe(onNext: { result in
            if case let .succ(info) = result {
                XCTAssertNotNil(info)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testFetchFileInfoPolling() {
        // stub network dependency
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveFileInfoPolling.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        
        let sut = createSut()
        let expectPolling = expectation(description: "test fetch fileInfo polling")
        let expectFailed = expectation(description: "test fetch fileInfo failed")
        // first return storing, second return error
        sut.request(version: "newVersion").subscribe(onNext: { result in
            if case .storing = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expectPolling.fulfill()
        }, onError: { error in
            XCTAssertNotNil(error)
            expectFailed.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }

    }
    
    
}

extension DriveFileInfoProviderTests {
    private func createSut() -> DriveFileInfoProvider {
        let logger = DrivePerformanceRecorder(fileToken: "testToken",
                                              fileType: "testType",
                                              previewFrom: .docsList,
                                              sourceType: .preview,
                                              additionalStatisticParameters: nil)
        let meta = DriveFileMeta(size: 1024,
                                 name: "testFile",
                                 type: "testType",
                                 fileToken: "testToken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataVersion",
                                 source: .cache,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let netManager = DrivePreviewNetManager(logger, fileInfo: fileInfo)
        return DriveFileInfoProvider(netManager: netManager,
                                     showInfRecent: true,
                                     pollingStrategy: MockPollingStrategy())
    }
}

class MockPollingStrategy: DrivePollingStrategy {
    private let intervals: [Int] = [1]
    private var index: Int = 0
    public func nextInterval() -> PollingInterval {
        let pre = index
        index += 1
        if pre < intervals.count {
            return .interval(intervals[pre])
        } else {
            return .end
        }
    }
    
    public func shouldPolling(data: JSON?, error: Error?) -> Bool {
        guard let json = data,
              let code = json["code"].int,
              code == DriveFileInfoErrorCode.fileCopying.rawValue else {
                return false
        }
        return true
    }
}
