//
//  DKIMFileConvertViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/5/20.
//

import XCTest
import RxSwift
@testable import SKDrive

class DKIMFileConvertViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testGetters() {
        let sut = createSut(fileSize: 1024, fileID: "fileID", fileName: "name.xls")
        XCTAssertEqual(sut.fileID, "fileID")
        XCTAssertEqual(sut.name, "name.xls")
        XCTAssertEqual(sut.fileType, .xls)
    }
    
    // 文件大小不超过20M
    func testFileSizeNotOverLimited() {
        let sut = createSut(fileSize: 1024)
        XCTAssertFalse(sut.isFileSizeOverLimit())
    }
    
    // 文件大小超过20M
    func testFileSizeOverLimited() {
        let sut = createSut(fileSize: 22020096)
        XCTAssertTrue(sut.isFileSizeOverLimit())
    }

    // 转在线文档成功
    func testConvertFileSuccess() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createResult = ["ticket": "xxx", "job_timeout": 10] as [String: Any]
        let convertResult = ["code": 0,
                             "data": ["result": ["token": "token",
                                                  "job_status": 0,
                                                  "type": "sheet",
                                                  "url": "https://xx.xx"]
                                      ]
                             ] as [String: Any]

        let sut = createSut(fileSize: 1024, isReachable: true, chatTokenResult: info, createTaskResult: createResult, convertResult: convertResult)
        let expect = expectation(description: "convert success")
        sut.bindAction = { action in
            if case .routedToExternal = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // create task 成功但是ticket字段不存在的异常逻辑，提示invaliddata
    func testCreateTaskSuccWithInvalidData() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createResult = ["job_timeout": 10] as [String: Any]
        let convertResult = ["code": 0,
                             "data": ["result": ["token": "token",
                                                  "job_status": 0,
                                                  "type": "sheet",
                                                  "url": "https://xx.xx"]
                                     ]
        ] as [String: Any]
        let sut = createSut(fileSize: 1024, isReachable: true, chatTokenResult: info, createTaskResult: createResult, convertResult: convertResult)
        let expect = expectation(description: "convert success")
        sut.bindAction = { action in
            if case let .showFailedView(viewType) = action {
                XCTAssertTrue(viewType == .importFailedRetry)
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 转码成功后网路网络不可用
    func testConvertSuccessWithNetworkUnreachable() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createResult = ["ticket": "xxx", "job_timeout": 10] as [String: Any]
        let convertResult = ["code": 0,
                             "data": ["result": ["token": "token",
                                                  "job_status": 0,
                                                  "type": "sheet",
                                                  "url": "https://xx.xx"]
                                     ]
                            ] as [String: Any]
        let sut = createSut(fileSize: 1024, isReachable: false, chatTokenResult: info, createTaskResult: createResult, convertResult: convertResult)
        let expect = expectation(description: "convert networkInterruption")
        sut.bindAction = { action in
            if case let .showFailedView(viewType) = action {
                XCTAssertTrue(viewType == .networkInterruption)
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 转码失败，网络不可用场景
    func testConvertFileFailedWithNetworkUnreachable() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createResult = ["ticket": "xxx", "job_timeout": 10] as [String: Any]
        let convertError = DriveConvertFileError.invalidDataError
        let sut = createSut(fileSize: 1024, isReachable: false, chatTokenResult: info, createTaskResult: createResult, convertError: convertError)
        let expect = expectation(description: "convert success")
        sut.bindAction = { action in
            if case let .showFailedView(viewType) = action {
                XCTAssertTrue(viewType == .networkInterruption)
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 导入失败接口失败，错误码1009 展示importTooLarge
    func testCreateTasklFailWithImportTooLarge() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createError = DriveConvertFileError.serverError(code: 1009)
        let convertError = DriveConvertFileError.invalidDataError
        let sut = createSut(fileSize: 1024,
                            isReachable: true,
                            chatTokenResult: info,
                            createTaskError: createError,
                            convertError: convertError)
        let expect = expectation(description: "convert success")
        sut.bindAction = { action in
            if case let .showFailedView(viewType) = action {
                XCTAssertTrue(viewType == .importTooLarge)
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCreateTaskFailWithDLPFailed() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createError = DriveConvertFileError.serverError(code: 1019)
        let convertError = DriveConvertFileError.invalidDataError
        let sut = createSut(fileSize: 1024,
                            isReachable: true,
                            chatTokenResult: info,
                            createTaskError: createError,
                            convertError: convertError)
        let expect = expectation(description: "convert success")
        sut.bindAction = { action in
            if case let .showFailedView(viewType) = action {
                if case .dlpCheckedFailed = viewType {
                    XCTAssertTrue(true)
                } else {
                    XCTAssertTrue(false)
                }
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCreateTaskFailWithDLPChecking() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createError = DriveConvertFileError.serverError(code: 1020)
        let convertError = DriveConvertFileError.invalidDataError
        let sut = createSut(fileSize: 1024,
                            isReachable: true,
                            chatTokenResult: info,
                            createTaskError: createError,
                            convertError: convertError)
        let expect = expectation(description: "convert success")
        sut.bindAction = { action in
            if case let .showFailedView(viewType) = action {
                if case .dlpChecking = viewType {
                    XCTAssertTrue(true)
                } else {
                    XCTAssertTrue(false)
                }
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    // 转在线文档失败
    func testConvertFileFailed() {
        let info = SpaceRustRouter.ConvertInfo(token: "testToken", chatToken: "chatToken")
        let createResult = ["ticket": "xxx", "job_timeout": 10] as [String: Any]
        let convertError = DriveConvertFileError.invalidDataError
        let sut = createSut(fileSize: 1024, isReachable: true, chatTokenResult: info, createTaskResult: createResult, convertError: convertError)
        let expect = expectation(description: "convert success")
        sut.bindAction = { action in
            if case .showFailedView = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("convert failed: \(action)")
            }
            expect.fulfill()
        }
        sut.convertFile()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    private func createSut(fileSize: UInt64,
                           fileID: String = "fileID",
                           fileName: String = "name.xls",
                           isReachable: Bool = true,
                           chatTokenResult: SpaceRustRouter.ConvertInfo? = nil,
                           createTaskResult: [String: Any]? = nil,
                           convertResult: [String: Any]? = nil,
                           createTaskError: Error? = nil,
                           convertError: Error? = nil) -> DKIMFileConvertViewModel {
        let fileInfo = DKFileInfo(appId: "1001", fileId: fileID, name: fileName, size: fileSize, fileToken: "fileID", authExtra: nil)
        let performanceLogger = DrivePerformanceRecorder(fileToken: "fileID",
                                                         fileType: "xls",
                                                         previewFrom: .im,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        let dependence = DKIMFileConvertVMDependencyMockImpl()
        let networkMonitor = MockNetworkStatusMonitor()
        networkMonitor.isReachable = isReachable
        dependence.getChatTokenResult = chatTokenResult
        dependence.createTaskResult = createTaskResult
        dependence.createTaskError = createTaskError
        dependence.convertError = convertError
        dependence.convertResult = convertResult
        let sut = DKIMFileConvertViewModel(fileInfo: fileInfo,
                                           msgID: "msgID",
                                           dependency: dependence,
                                           performanceLogger: performanceLogger,
                                           networkMonitor: networkMonitor)
        return sut
    }
}

class DKIMFileConvertVMDependencyMockImpl: DKIMFileConvertVMDependency {
    // getchat token result
    var getChatTokenResult: SpaceRustRouter.ConvertInfo?
    var getChatError: Error?
    // creat task result
    var createTaskResult: [String: Any]?
    var createTaskError: Error?
    
    // polling convert result
    var convertResult: [String: Any]?
    var convertError: Error?

    func getChatToken(msgID: String) -> Observable<SpaceRustRouter.ConvertInfo> {
        if let err = getChatError {
            return Observable.error(err)
        } else if let result = getChatTokenResult {
            return Observable.just(result)
        } else {
            return Observable.never()
        }
    }
    
    func createTask(msgID: String, chatToken: String, type: String?) -> Observable<[String: Any]> {
        if let err = createTaskError {
            return Observable.error(err)
        } else if let result = createTaskResult {
            return Observable.just(result)
        } else {
            return Observable.never()
        }
    }
    
    func startPolling(ticket: String, timeOut: Int) -> Observable<[String: Any]> {
            if let err = convertError {
                return Observable.error(err)
            } else if let result = convertResult {
                return Observable.just(result)
            } else {
                return Observable.never()
            }
    }
    
}
