//
//  ConvertFileHelperTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/5/26.
//

import XCTest
import RxSwift
import SKCommon
@testable import SKDrive
import SpaceInterface

class ConvertFileHelperTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testHandleConvertResult() {
        // 数据无法解析
        var convertResult = [:] as [String: Any]
        let sut = ConvertFileHelper()
        var r = sut.handleConvertResult(convertResult, fileType: "sheet")
        if case let .showFailedView(viewType) = r.first {
            XCTAssertTrue(viewType == .importFailedRetry)
        }
        
        // code 不为0
        convertResult = ["code": 1,
                             "data": ["result": ["token": "token",
                                                  "job_status": 0,
                                                  "type": "sheet",
                                                  "url": "https://xx.xx"]
                                      ]
                             ] as [String: Any]
        
        
        r = sut.handleConvertResult(convertResult, fileType: "sheet")
        if case let .showFailedView(viewType) = r.first {
            XCTAssertTrue(viewType == .contactService)
        }
        
        // data数据有问题
        convertResult = ["code": 0,
                             "data": ""
                             ] as [String: Any]
        
        
        r = sut.handleConvertResult(convertResult, fileType: "sheet")
        if case let .showFailedView(viewType) = r.first {
            XCTAssertTrue(viewType == .importFailedRetry)
        }
        // jobstatus != 0
        convertResult = ["code": 0,
                             "data": ["result": ["token": "token",
                                                  "job_status": 1,
                                                  "type": "sheet",
                                                  "url": "https://xx.xx"]
                                      ]
                             ] as [String: Any]
        
        
        r = sut.handleConvertResult(convertResult, fileType: "sheet")
        if case let .showFailedView(viewType) = r.first {
            XCTAssertTrue(viewType == .contactService)
        }
        
        // token 长度为0
        convertResult = ["code": 0,
                             "data": ["result": ["token": "",
                                                  "job_status": 0,
                                                  "type": "sheet",
                                                  "url": "https://xx.xx"]
                                      ]
                             ] as [String: Any]
        
        
        r = sut.handleConvertResult(convertResult, fileType: "sheet")
        if case let .showFailedView(viewType) = r.first {
            XCTAssertTrue(viewType == .contactService)
        }
        
        // extra错误信息
        convertResult = ["code": 0,
                             "data": ["result": ["token": "token",
                                                  "job_status": 0,
                                                  "type": "sheet",
                                                 "url": "https://xx.xx",
                                                 "extra": ["2000": "1"]
                                                ]
                                      ]
                             ] as [String: Any]
        
        
        r = sut.handleConvertResult(convertResult, fileType: "sheet")
        if case .showToast = r.first {
            XCTAssertTrue(true)
        } else {
            XCTFail("result is \(r)")
        }
        
        // 成功
        convertResult = ["code": 0,
                             "data": ["result": ["token": "token",
                                                  "job_status": 0,
                                                  "type": "sheet",
                                                  "url": "https://xx.xx"]
                                      ]
                             ] as [String: Any]
        r = sut.handleConvertResult(convertResult, fileType: "xls")
        if case let .routedToExternal(token, type) = r.first {
            XCTAssertTrue(token == "token")
            XCTAssertTrue(type == DocsType.sheet)
        }
    }

    func testHandleOldErrorCode() {
        let sut = ConvertFileHelper()
        var r = sut.handleOldErrorCode(code: 0)
        XCTAssertNil(r)
        r = sut.handleOldErrorCode(code: 100)
        XCTAssertTrue(r == .contactService)
        r = sut.handleOldErrorCode(code: 101)
        XCTAssertTrue(r == .unsupportType)
        r = sut.handleOldErrorCode(code: 102)
        XCTAssertTrue(r == .unsupportEncryptFile)
        r = sut.handleOldErrorCode(code: 103)
        XCTAssertTrue(r == .importFailedRetry)
        r = sut.handleOldErrorCode(code: 104)
        XCTAssertTrue(r == .importFailedRetry)
        r = sut.handleOldErrorCode(code: 105)
        XCTAssertTrue(r == .importFailedRetry)
        r = sut.handleOldErrorCode(code: 11001)
        XCTAssertTrue(r == .numberOfFileExceedsTheLimit)
        r = sut.handleOldErrorCode(code: 7000)
        XCTAssertTrue(r == .amountExceedLimit)
        r = sut.handleOldErrorCode(code: 7001)
        XCTAssertTrue(r == .hierarchyExceedLimit)
        r = sut.handleOldErrorCode(code: 7002)
        XCTAssertTrue(r == .sizeExceedLimit)
        r = sut.handleOldErrorCode(code: 900004230)
        XCTAssertTrue(r == .dataLockedForMigration)
        r = sut.handleOldErrorCode(code: 900004510)
        XCTAssertTrue(r == .unavailableForCrossTenantGeo)
        r = sut.handleOldErrorCode(code: 900004511)
        XCTAssertTrue(r == .unavailableForCrossBrand)
    }
    
    func testHandleNewErrorCode() {
        let sut = ConvertFileHelper()
        var r = sut.handleNewErrorCode(code: 0)
        XCTAssertTrue(r == .contactService)
        r = sut.handleNewErrorCode(code: 1)
        XCTAssertTrue(r == .contactService)
        r = sut.handleNewErrorCode(code: 113)
        XCTAssertTrue(r == .contactService)
        r = sut.handleNewErrorCode(code: 1009)
        XCTAssertTrue(r == .importTooLarge)
        r = sut.handleNewErrorCode(code: 110)
        XCTAssertTrue(r == .noPermission)
        r = sut.handleNewErrorCode(code: 104)
        XCTAssertTrue(r == .spaceBillingUnavailable)
        r = sut.handleNewErrorCode(code: 119)
        XCTAssertTrue(r == .mountNotExist)
        r = sut.handleNewErrorCode(code: 100)
        XCTAssertTrue(r == .unsupportEncryptFile)
        r = sut.handleNewErrorCode(code: 1015)
        XCTAssertTrue(r == .importFileSizeZero)
        r = sut.handleNewErrorCode(code: 3)
        XCTAssertTrue(r == .importFailedRetry)
        r = sut.handleNewErrorCode(code: 7000)
        XCTAssertTrue(r == .amountExceedLimit)
        r = sut.handleNewErrorCode(code: 7001)
        XCTAssertTrue(r == .hierarchyExceedLimit)
        r = sut.handleNewErrorCode(code: 7002)
        XCTAssertTrue(r == .sizeExceedLimit)
        r = sut.handleNewErrorCode(code: 900004230)
        XCTAssertTrue(r == .dataLockedForMigration)
        r = sut.handleNewErrorCode(code: 900004510)
        XCTAssertTrue(r == .unavailableForCrossTenantGeo)
        r = sut.handleNewErrorCode(code: 900004511)
        XCTAssertTrue(r == .unavailableForCrossBrand)
    }
    
    func testHandleNetworkError() {
        
    }
}
