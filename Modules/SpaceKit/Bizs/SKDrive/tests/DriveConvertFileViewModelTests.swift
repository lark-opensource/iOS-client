//
//  DriveConvertFileViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/6/1.
//

import XCTest
import RxSwift
import SKFoundation
import Foundation
import SKCommon
import OHHTTPStubs
@testable import SKDrive
import SKInfra

class DriveConvertFileViewModelTests: XCTestCase {
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        // 由于vm在初始化的时候会发送fileInfo请求，请求是异步的，导致会中DocsRequest Assert
        // 需要stub请求，同时等待请求返回才结束测试
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveFileInfoSucc.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]).requestTime(0.1, responseTime: 0.1)
        })
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testGetters() {
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        let expect = expectation(description: "wait for fileInfo")
        sut.bindAction = { action in
            if case .updateFileSizeText = action {
                expect.fulfill()
            }
        }
        XCTAssertEqual(sut.fileID, "fileID")
        XCTAssertEqual(sut.name, "name.xls")
        XCTAssertEqual(sut.fileType, .xls)
        XCTAssertEqual(sut.fileSize, 1024)
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    // 文件大小不超过20M
    func testFileSizeNotOverLimited() {
        let sut = createSut(fileSize: 1024)
        let expect = expectation(description: "wait for fileInfo")
        sut.bindAction = { action in
            if case .updateFileSizeText = action {
                expect.fulfill()
            }
        }
        XCTAssertFalse(sut.isFileSizeOverLimit())
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testGetCloudDocumentType() {
        var sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        let expect = expectation(description: "wait for fileInfo")
        sut.bindAction = { action in
            if case .updateFileSizeText = action {
                expect.fulfill()
            }
        }
        XCTAssertEqual(sut.getCloudDocumentType(), "sheet")
        sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.doc", docxImportEnabled: false)
        XCTAssertEqual(sut.getCloudDocumentType(), "doc")
        sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.doc")
        XCTAssertEqual(sut.getCloudDocumentType(), "docx")
        sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.mm")
        XCTAssertEqual(sut.getCloudDocumentType(), "mindnote")
        sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.txt")
        XCTAssertEqual(sut.getCloudDocumentType(), "")
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testConverFileCreateFailed() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.importFile)
            return contain
        }, response: { _ in
            HTTPStubsResponse(error: DocsNetworkError(1)! as Error)
        })
        let expect = expectation(description: "wait for create import")
        expect.expectedFulfillmentCount = 2
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        var actions = [DriveConvertFileAction]()
        sut.bindAction = { action in
            actions.append(action)
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 1000, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(actions.count == 2)
        if case let .showFailedView(value) = actions[0] {
            XCTAssert(value == .importFailedRetry)
        } else {
            XCTFail()
        }
    }
    
    func testConvertFileCreateFailedUnknowError() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.importFile)
            return contain
        }, response: { _ in
            HTTPStubsResponse(error: NSError(domain: "test", code: -1, userInfo: nil) as Error)
        })
        let expect = expectation(description: "wait for create import")
        expect.expectedFulfillmentCount = 2
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        var actions = [DriveConvertFileAction]()
        sut.bindAction = { action in
            actions.append(action)
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(actions.count == 2)
        if case let .showFailedView(value) = actions[0] {
            XCTAssert(value == .importFailedRetry)
        } else {
            XCTFail()
        }
    }
    
    func testConvertFileCreateFailedWithoutCode() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.importFile)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("convertCreateFailed.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "wait for create import")
        expect.expectedFulfillmentCount = 2
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        var actions = [DriveConvertFileAction]()
        sut.bindAction = { action in
            actions.append(action)
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(actions.count == 2)
        if case let .showFailedView(value) = actions[0] {
            XCTAssert(value == .importFailedRetry)
        } else {
            XCTFail()
        }
    }
    
    func testConvertFileCreateFailedWithXmlVersionNotSupport() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.importFile)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("convertCreateFailedxmlNotSupport.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "wait for create import")
        expect.expectedFulfillmentCount = 2
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        var actions = [DriveConvertFileAction]()
        sut.bindAction = { action in
            actions.append(action)
            expect.fulfill()
            print("testConvertFileCreateFailedWithXmlVersionNotSupport  fulfile action \(action)")
        }
        sut.convertFile()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(actions.count == 2)
        if case let .showFailedView(value) = actions[0] {
            XCTAssert(value == .contactService)
        } else {
            XCTFail()
        }
    }
    
    func testConvertFileCreateSuccessWithoutTicket() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.importFile)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("convertSuccessWithoutTicket.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "wait for create import")
        expect.expectedFulfillmentCount = 2
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        var actions = [DriveConvertFileAction]()
        sut.bindAction = { action in
            actions.append(action)
            expect.fulfill()
            print("testConvertFileCreateSuccessWithoutTicket  fulfile action \(action)")
        }
        sut.convertFile()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(actions.count == 2)
        if case let .showFailedView(value) = actions[0] {
            XCTAssert(value == .contactService)
        } else {
            XCTFail()
        }
    }
    
    func testConvertFileCreateSuccePushTimeout() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.importFile)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("convertFileCreateSucc.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getImportResult)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("getImportResultSucc.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "wait for get result")
        expect.expectedFulfillmentCount = 2
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls", timeOut: 0.1)
        var actions = [DriveConvertFileAction]()
        sut.bindAction = { action in
            actions.append(action)
            expect.fulfill()
            print("testConvertFileCreateSuccePushTimeout  fulfile action \(action)")
        }
        sut.convertFile()
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssert(actions.count == 2)
        if case .routedToExternal(_,_) = actions[1] {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }
    private func createSut(fileSize: UInt64,
                           fileID: String = "fileID",
                           fileName: String = "name.xls",
                           docxImportEnabled: Bool = true,
                           docxEnable: Bool = true, timeOut: TimeInterval = 60.0) -> DriveConvertFileViewModel {
        let type = SKFilePath.getFileExtension(from: fileName) ?? ""
        let meta = DriveFileMeta(size: fileSize,
                                 name: fileName,
                                 type: type,
                                 fileToken: fileID,
                                 mountNodeToken: "nodetoken",
                                 mountPoint: "mountpoint",
                                 version: nil,
                                 dataVersion: nil,
                                 source: .server,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let performanceLogger = DrivePerformanceRecorder(fileToken: "fileID",
                                                         fileType: "xls",
                                                         previewFrom: .im,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        let sut = DriveConvertFileViewModel(fileInfo: fileInfo,
                                            performanceLogger: performanceLogger,
                                            docxImportEnabled: docxImportEnabled,
                                            docxEnable: docxEnable,
                                            refreshTime: timeOut)
        return sut
    }
}
