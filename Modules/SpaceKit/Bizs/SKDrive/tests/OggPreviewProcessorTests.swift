//
//  OggPreviewProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/25.
//

import XCTest
import SKFoundation
@testable import SKDrive
class OggPreviewProcessorTests: XCTestCase {
    var handler: MockPreviewProcessHandler!

    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }

    // handle ready with mimeType
    // update state endTranscoding -> setupPreview
    func testHandleReadyWithMimeType() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ogg",
                            previewType: .ogg,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let extra = "{\"mime_type\": \"video/ogg\"}"
        let context = DriveFilePreviewContext(status: 0, extra: extra)
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
    // handle ready with out extra
    // update state endTranscoding -> unsupport
    func testHandleReadyWithOutMime() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.ogg",
                            previewType: .ogg,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 0)
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
        let extra = "{\"mine_type\": \"video/ogg\"}"
        let context = DriveFilePreviewContext(status: 0, extra: extra)
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
}
extension OggPreviewProcessorTests {
    func createSut(fileName: String,
                   previewType: DrivePreviewFileType? = nil,
                   allowDowngradeToOrigin: Bool,
                   isInVCFollow: Bool = false,
                   canDownloadOrigin: Bool = false,
                   handler: PreviewProcessHandler) -> OggPreviewProcessor {
        let cacheService = MockCacheService()
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: allowDowngradeToOrigin,
                                                 canDownloadOrigin: canDownloadOrigin,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard)
        let meta = metaData(size: 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: previewType)
        let sut = OggPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: handler, config: config)
        return sut
        
    }
}
