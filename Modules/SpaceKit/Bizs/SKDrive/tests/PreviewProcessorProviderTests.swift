//
//  PreviewProcessorProviderTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/24.
//

import XCTest
import SKFoundation
@testable import SKDrive

class PreviewProcessorProviderTests: XCTestCase {
    var handler: PreviewProcessHandler!
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // jpglin、pnglin 类型使用LinearizedImagePreviewProcessor
    func testLinearizedPreviewType() {
        let sut = createDefaultSut()
        handler = MockPreviewProcessHandler()
        let meta = metaData(size: 1024, fileName: "test.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .docsList,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .pngLin, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is LinearizedImagePreviewProcessor)
    }
    
    // linerizedPDF with vcFollow 使用 DefaultPreviewProcessor
    func testLinearizedPDFInVCFollow() {
        let sut = createDefaultSut()
        handler = MockPreviewProcessHandler()
        let meta = metaData(size: 1024, fileName: "test.pdf")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .vcFollow,
                                                 isInVCFollow: true,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .linerizedPDF, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is DefaultPreviewProcessor)
    }
    
    // archive类型使用ArchivePreviewProcessor
    func testArchive() {
        let sut = createDefaultSut()
        handler = MockPreviewProcessHandler()
        let meta = metaData(size: 1024, fileName: "test.zip")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .docsList,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .archive, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is ArchivePreviewProcessor)
    }
    
    // mp4使用VideoPreviewProcessor
    func testMp4() {
        let sut = createDefaultSut()
        handler = MockPreviewProcessHandler()
        let meta = metaData(size: 1024, fileName: "test.mp4")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .docsList,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .mp4, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is VideoPreviewProcessor)
    }
    // html类型使用DriveHTMLPreviewProcessor
    func testHtml() {
        let sut = createDefaultSut()
        handler = MockPreviewProcessHandler()
        let meta = metaData(size: 1024, fileName: "test.excel")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .docsList,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .html, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is DriveHTMLPreviewProcessor)
    }
    // ogg使用OggPreviewProcessor
    func testOgg() {
        let sut = createDefaultSut()
        handler = MockPreviewProcessHandler()
        let meta = metaData(size: 1024, fileName: "test.ogg")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .docsList,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .ogg, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is OggPreviewProcessor)
    }
    
    // 其他类型使用DefaultPreviewProcessor
    func testOtherType() {
        let sut = createDefaultSut()
        handler = MockPreviewProcessHandler()
        let meta = metaData(size: 1024, fileName: "test.gif")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .docsList,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .similarFiles, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is DefaultPreviewProcessor)
    }
    
    // jpglin、pnglin 类型使用LinearizedImagePreviewProcessor
    func testIMLinearizedPreviewType() {
        let sut = createIMSut()
        handler = MockPreviewProcessHandler()
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "fileid",
                                  name: "test.jpg",
                                  size: 1024,
                                  fileToken: "fileToken",
                                  authExtra: nil)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .im,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .jpgLin, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is LinearizedImagePreviewProcessor)
    }
    
    // linerizedPDF withOut vcFollow 并且fg 关闭 使用DefaultPreviewProcessor
    func testIMLinearizedPDFWithFGClosed() {
        let sut = createIMSut()
        handler = MockPreviewProcessHandler()
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "fileid",
                                  name: "test.pdf",
                                  size: 1024,
                                  fileToken: "fileToken",
                                  authExtra: nil)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .im,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .linerizedPDF, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is DefaultPreviewProcessor)
    }
    
    // archive类型使用ArchivePreviewProcessor
    func testIMArchive() {
        let sut = createIMSut()
        handler = MockPreviewProcessHandler()
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "fileid",
                                  name: "test.zip",
                                  size: 1024,
                                  fileToken: "fileToken",
                                  authExtra: nil)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .im,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .archive, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is ArchivePreviewProcessor)
    }
    
    // mp4使用VideoPreviewProcessor
    func testIMMp4() {
        let sut = createIMSut()
        handler = MockPreviewProcessHandler()
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "fileid",
                                  name: "test.mov",
                                  size: 1024,
                                  fileToken: "fileToken",
                                  authExtra: nil)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .im,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .mp4, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is VideoPreviewProcessor)
    }
    // html类型使用DefaultPreviewProcessor, im场景不支持html转码预览
    func testIMHtml() {
        let sut = createIMSut()
        handler = MockPreviewProcessHandler()
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "fileid",
                                  name: "test.xls",
                                  size: 1024,
                                  fileToken: "fileToken",
                                  authExtra: nil)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .im,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .html, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is DefaultPreviewProcessor)
    }
    // ogg使用OggPreviewProcessor
    func testIMOgg() {
        let sut = createIMSut()
        handler = MockPreviewProcessHandler()
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "fileid",
                                  name: "test.ogg",
                                  size: 1024,
                                  fileToken: "fileToken",
                                  authExtra: nil)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .im,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .ogg, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is OggPreviewProcessor)
    }
    
    // 其他类型使用DefaultPreviewProcessor
    func testIMOtherType() {
        let sut = createIMSut()
        handler = MockPreviewProcessHandler()
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "fileid",
                                  name: "test.gif",
                                  size: 1024,
                                  fileToken: "fileToken",
                                  authExtra: nil)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: .im,
                                                 isInVCFollow: false,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let result = sut.processor(with: .similarFiles, fileInfo: fileInfo, resultHandler: handler, config: config)
        XCTAssertTrue(result is DefaultPreviewProcessor)
    }
}

extension PreviewProcessorProviderTests {
    func createDefaultSut(pdfLinearEnable: Bool = true) -> DefaultPreviewProcessorProvider {
        let sut = DefaultPreviewProcessorProvider(cacheService: MockCacheService())
        return sut
    }
    
    func createIMSut() -> IMPreivewProcesorProvider {
        let sut = IMPreivewProcesorProvider(cacheService: MockCacheService())
        return sut
    }
}


class MockPreviewProcessHandler: PreviewProcessHandler {
    var states = [DriveProccessState]()
    func updateState(_ state: DriveProccessState) {
        states.append(state)
    }

    var isWaitTranscoding: Bool {
        return false
    }
}
