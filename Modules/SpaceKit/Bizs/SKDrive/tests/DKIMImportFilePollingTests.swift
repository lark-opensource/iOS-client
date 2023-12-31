//
//  DKIMImportFilePollingTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/5/26.
//

import XCTest
import RxSwift
import SKCommon
import SwiftyJSON
@testable import SKDrive

class DKIMImportFilePollingTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testNextInterval() {
        let sut = DKIMImportFilePolling(timeOut: 100)
        if case let .interval(interval) = sut.nextInterval() {
            XCTAssertTrue(interval == 1)
        }
        if case let .interval(interval) = sut.nextInterval() {
            XCTAssertTrue(interval == 3)
        }
    }
    
    func testTimeout() {
        let sut = DKIMImportFilePolling(timeOut: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            if case .end = sut.nextInterval() {
                XCTAssertTrue(true)
            } else {
                XCTFail("should timeout with end")
            }
        }
    }
    
    func testShouldPolling() {
        let sut = DKIMImportFilePolling(timeOut: 1)
        var r = sut.shouldPolling(data: nil, error: nil)
        XCTAssertFalse(r)
        var string = """
                    {
                        "code": 0,
                        "data": {
                        "result": {
                            "job_status": 1,
                            "token": "shtcni37Md9mmWSTpYC8I8Zk1Gg",
                            "type": "sheet",
                            "url": "https://bytedance.feishu.cn/sheets/shtcni37Md9mmWSTpYC8I8Zk1Gg"
                            }
                        }
                    }
                    """
        var data = JSON(parseJSON: string)
        r = sut.shouldPolling(data: data, error: nil)
        XCTAssertTrue(r)
        
        string = """
                {
                  "code": 0
                }
                """
        data = JSON(parseJSON: string)
        r = sut.shouldPolling(data: data, error: nil)
        XCTAssertFalse(r)
        string = """
                {
                  "code": 0,
                  "data": {
                    "result": {
                      "extra": {
                        "2000": "1"
                      }
                    }
                  }
                }
                """
        data = JSON(parseJSON: string)
        r = sut.shouldPolling(data: data, error: nil)
        XCTAssertFalse(r)
    }
}
