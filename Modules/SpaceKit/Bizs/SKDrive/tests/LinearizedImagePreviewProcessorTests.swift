//
//  LinearizedImagePreviewProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/25.
//

import XCTest
import SKFoundation
@testable import SKDrive
class LinearizedImagePreviewProcessorTests: XCTestCase {
    var handler: MockPreviewProcessHandler!

    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }

    // handle ready with linearized is true
    // update state endTranscoding -> setupPreview
    func testHandleReadyWithPreviewTypeAndLinearized() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.png",
                            previewType: .pngLin,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 0, linearized: true)
        let preview = DriveFilePreview(context: context)
        sut.handleReady(preview: preview) {
            expect.fulfill()
        }
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 2)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
        if case .setupPreview = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    // handle ready with linearized is false and local support
    // update state endTranscoding -> downloadOrigin
    func testHandleReadyNoLinearizedAndSupport() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.png",
                            previewType: .pngLin,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 0, linearized: false)
        let preview = DriveFilePreview(context: context)
        sut.handleReady(preview: preview) {
            expect.fulfill()
        }
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
    
    // handle ready with no linearized and unsupport
    // update state endTranscoding -> unsupport
    func testHandleReadyNoLinearizedAndLocalUnsupport() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.sketch",
                            previewType: .pngLin,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 0, linearized: false)
        let preview = DriveFilePreview(context: context)
        sut.handleReady(preview: preview) {
            expect.fulfill()
        }
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
    
    // handle ready with out previewType
    // update state endTranscoding -> unsupport
    func testHandleReadyWithoutPreviewType() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.sketch",
                            previewType: nil,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 0, linearized: false)
        let preview = DriveFilePreview(context: context)
        sut.handleReady(preview: preview) {
            expect.fulfill()
        }
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
    
    func testDowngradeWhenGenerating() {
        handler = MockPreviewProcessHandler()
        var sut = createSut(fileName: "test.sketch",
                            previewType: nil,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        XCTAssertTrue(sut.downgradeWhenGenerating)
        sut = createSut(fileName: "test.sketch",
                            previewType: nil,
                            allowDowngradeToOrigin: false,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        XCTAssertFalse(sut.downgradeWhenGenerating)
    }

}
extension LinearizedImagePreviewProcessorTests {
    func createSut(fileName: String,
                   previewType: DrivePreviewFileType? = nil,
                   allowDowngradeToOrigin: Bool,
                   isInVCFollow: Bool = false,
                   canDownloadOrigin: Bool = false,
                   handler: PreviewProcessHandler) -> LinearizedImagePreviewProcessor {
        let cacheService = MockCacheService()
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: allowDowngradeToOrigin,
                                                 canDownloadOrigin: canDownloadOrigin,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard)
        let meta = metaData(size: 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: previewType)
        let sut = LinearizedImagePreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: handler, config: config)
        return sut
        
    }
}
