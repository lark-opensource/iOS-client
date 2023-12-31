//
//  DefaultPreviewProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/25.
//

import XCTest
import SKFoundation
import SKCommon
@testable import SKDrive
class DefaultPreviewProcessorTests: XCTestCase {
    var handler: MockPreviewProcessHandler!
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    
    // downgradeWhenGeneerating is false
    func testDowngradeWhenGenerating() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.gif", allowDowngradeToOrigin: true, handler: handler)
        XCTAssertFalse(sut.downgradeWhenGenerating)
    }
    
    // 本地文件支持预览，并且支持下载源文件的场景，在转码失败情况下降级预览
    func testDowngradeWhenPreviewUnavailable() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.gif", allowDowngradeToOrigin: true, handler: handler)
        // 本地支持预览
        var meta = metaData(size: 1024, fileName: "test.gif")
        var fileinfo = DriveFileInfo(fileMeta: meta)
        let result1 = sut.downgradeWhenPreviewUnavailable(for: fileinfo)
        XCTAssertTrue(result1)
        
        // 本地不支持预览
        meta = metaData(size: 1024, fileName: "test.tt")
        fileinfo = DriveFileInfo(fileMeta: meta)
        let result2 = sut.downgradeWhenPreviewUnavailable(for: fileinfo)
        XCTAssertFalse(result2)
    }
    
    // 异常情况， 返回unsupport
    // handle preview ready with preview type is nil
    func testHandlePreviewReadyWithPreviewTypeNil() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ppt", allowDowngradeToOrigin: true, handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 0)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
        if case .unsupport = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // 正常情况， 返回downloadPreview
    // handle preview ready with preview type is not nil
    // update state endTranscoding -> downloadPreview
    func testHandlePreviewReadyWithPreviewType() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ppt", previewType: .linerizedPDF, allowDowngradeToOrigin: true, isInVCFollow: false, handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 0)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
        if case .downloadPreview = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    // handle preview generating with longpullinterval can not downgradeWhenGenerating
    // update state startTranscoding
    func testHandlePreviewGeneratingWithLongPullInterval() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ppt", previewType: .linerizedPDF, allowDowngradeToOrigin: true, isInVCFollow: false, handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 1,
                                              interval: nil,
                                              longPushInterval: 600,
                                              previewURL: nil,
                                              previewFileSize: nil,
                                              linearized: nil,
                                              videoInfo: nil,
                                              extra: nil)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 1)
        if case .startTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle preview generating without longpullinterval can not downgradeWhenGenerating && allowDowngradeToOrigin = false
    // update state endTranscoding -> fetchPreviewURLFail
    func testHandlePreviewGeneratingWithOutLongPullInterval() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ppt", previewType: .linerizedPDF, allowDowngradeToOrigin: false, isInVCFollow: false, handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 1)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
        if case .fetchPreviewURLFail = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle ppt preview failedNoRetry can downgradeWhenPreviewUnavailable && canDwonloadOrigin = true
    // update state downloadOrigin
    func testHandlePreviewFailedNoRetryDownloadOrigin() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ppt", previewType: .linerizedPDF, allowDowngradeToOrigin: true, isInVCFollow: false, canDownloadOrigin: true, handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 3)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        if case .downloadOrigin = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle ppt preview failedNoRetry can downgradeWhenPreviewUnavailable && canDwonloadOrigin = false
    // update state downloadPreview
    func testHandlePreviewFailedNoRetryDownloadPreview() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ppt",
                            previewType: .linerizedPDF,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: false,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 3)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        if case .downloadPreview = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle local unsupport preview failedNoRetry cannot downgradeWhenPreviewUnavailable
    // update state fetchPreviewURLFail
    func testHandlePreviewFailedNoRetryFetchPreviewFailed() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.sketch",
                            previewType: .jpg,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: false,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 3)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        if case .fetchPreviewURLFail = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle  preview failed can downgradeWhenPreviewUnavailable && canDwonloadOrigin = true
    // update state downloadOrigin
    func testHandlePreviewFailedDownloadOrigin() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ppt", previewType: .linerizedPDF, allowDowngradeToOrigin: true, isInVCFollow: false, canDownloadOrigin: true, handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 4)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        if case .downloadOrigin = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle local unsupport preview failed can downgradeWhenPreviewUnavailable && canDwonloadOrigin = true
    // update state unsupport
    func testHandlePreviewFailedUnsupport() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.sketch", previewType: .jpg, allowDowngradeToOrigin: true, isInVCFollow: false, canDownloadOrigin: true, handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 4)
        let preview = DriveFilePreview(context: context)
        sut.handle(preview: preview, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        if case .unsupport = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle error with local unsupport
    // update state fetchPreviewURLFail
    func testHandleErrorUnsupport() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.sketch", previewType: .jpg, allowDowngradeToOrigin: true, isInVCFollow: false, canDownloadOrigin: true, handler: handler)
        let expect = expectation(description: "handle update state")
        sut.handle(error: DriveError.previewFetchError, completion: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 1)
        if case .fetchPreviewURLFail = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }

    }
}

extension DefaultPreviewProcessorTests {
    func createSut(fileName: String,
                   previewType: DrivePreviewFileType? = nil,
                   allowDowngradeToOrigin: Bool,
                   isInVCFollow: Bool = false,
                   canDownloadOrigin: Bool = false,
                   handler: PreviewProcessHandler) -> DefaultPreviewProcessor {
        let cacheService = MockCacheService()
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: allowDowngradeToOrigin,
                                                 canDownloadOrigin: canDownloadOrigin,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard)
        let meta = metaData(size: 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: previewType)
        let sut = DefaultPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: handler, config: config)
        return sut
        
    }
}
