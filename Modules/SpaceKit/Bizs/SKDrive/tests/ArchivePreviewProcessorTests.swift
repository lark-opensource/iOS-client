//
//  ArchivePreviewProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/25.
//

import XCTest
import SKFoundation
@testable import SKDrive
class ArchivePreviewProcessorTests: XCTestCase {
    var handler: MockPreviewProcessHandler!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // handle ready
    // update state endTranscoding -> setupPreview
    func testHandleReady() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.zip",
                            previewType: .linerizedPDF,
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
        
        if case .setupPreview = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
}
extension ArchivePreviewProcessorTests {
    func createSut(fileName: String,
                   previewType: DrivePreviewFileType? = nil,
                   allowDowngradeToOrigin: Bool,
                   isInVCFollow: Bool = false,
                   canDownloadOrigin: Bool = false,
                   handler: PreviewProcessHandler) -> ArchivePreviewProcessor {
        let cacheService = MockCacheService()
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: allowDowngradeToOrigin,
                                                 canDownloadOrigin: canDownloadOrigin,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard)
        let meta = metaData(size: 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: previewType)
        let sut = ArchivePreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: handler, config: config)
        return sut
        
    }
}
