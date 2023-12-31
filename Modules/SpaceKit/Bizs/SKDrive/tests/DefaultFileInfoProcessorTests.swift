//
//  DefaultFileInfoProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/3/28.
//

import XCTest
import SKFoundation
@testable import SKDrive

class DefaultFileInfoProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCanOpenFromCache() {
        let meta = metaData(size: 1024, fileName: "test.jpg")
        let sut = createSut(size: 1024, name: "test.jpg", node: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let resutl = sut.getCachePreviewInfo(fileInfo: fileInfo)
        XCTAssertNil(resutl)
    }

    // 文件过大，文件大小为零等场景
    func testFileInfoUnsupport() {
        let meta = metaData(size: 0, fileName: "test.jpg")
        let node = cacheNode(fileName: "test.jpg", meta: meta)
        let sut = createSut(size: 0, name: "test.jpg", node: node)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case .unsupport(_) = result {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testCacheFileUnsupport() {
        let meta = metaData(size: 0, fileName: "test.unknown")
        let node = cacheNode(fileName: "test.unknown", meta: meta)
        let sut = createSut(size: 0, name: "test.unknown", node: node)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case .unsupport(_) = result {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testPreferPreview() {
        let meta = metaData(size: 1024, fileName: "test.txt")
        let node = cacheNode(fileName: "test.txt", meta: meta)
        let sut = createSut(size: 1024, name: "test.txt", node: node)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(_, info) = result {
            if case .local(_, _) = info {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testCacheLocalMedia() {
        let meta = metaData(size: 1024, fileName: "test.mp4")
        let node = cacheNode(fileName: "test.mp4", meta: meta)
        let sut = createSut(size: 1024, name: "test.mp4", node: node)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(_, info) = result {
            if case .localMedia(_, _) = info {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testHandleHasOpenedFromCache() {
        let meta = metaData(size: 1024, fileName: "test.txt")
        let node = cacheNode(fileName: "test.txt", meta: meta)
        let sut = createSut(size: 1024, name: "test.txt", node: node)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .transcodedPlainText)
        let expect = expectation(description: "wait handle fileinfo")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: true) { result in
            XCTAssertNil(result)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testHandlePreferPreview() {
        // 已缓存，本地不支持预览，后端支持转码
        let meta = metaData(size: 1024, fileName: "test.psd")
        let node = cacheNode(fileName: "test.psd", meta: meta)
        let sut = createSut(size: 1024, name: "test.psd", node: node, preferPreview: true)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .jpg, previewStatus: 1)
        let expect = expectation(description: "wait handle fileinfo")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: true) { result in
            if case .startPreviewGet = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testHandlePreferPreviewTranscodeFailedAndLocalSupport() {
        // 无缓存，本地支持预览，后端支持转码
        let meta = metaData(size: 1024, fileName: "test.heic")
        let sut = createSut(size: 1024, name: "test.psd", node: nil, preferPreview: true)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .jpg, previewStatus: 7)
        let expect = expectation(description: "wait handle fileinfo")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: false) { result in
            if case .downloadOrigin = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    
    func testHandleDownloadOrigin() {
        // 无缓存，本地支持预览
        let meta = metaData(size: 1024, fileName: "test.jpg")
        let sut = createSut(size: 1024, name: "test.jpg", node: nil, preferPreview: false)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let expect = expectation(description: "wait handle fileinfo")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: false) { result in
            if case .downloadOrigin = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    // 无缓存，不支持转码
    func testHandleNocacheUsupport() {
        let meta = metaData(size: 1024, fileName: "test.o")
        let sut = createSut(size: 1024, name: "test.o", node: nil)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .jpg, previewStatus: nil)
        let expect = expectation(description: "wait handle fileinfo")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: false) { result in
            if case .unsupport(_) = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testPreferRemotePreviewWhenReachable() {
        var result = DriveFileInfoProcessorConfig.preferRemotePreviewWhenReachable(type: .svg)
        XCTAssertTrue(result == DocsNetStateMonitor.shared.isReachable)
        result = DriveFileInfoProcessorConfig.preferRemotePreviewWhenReachable(type: .png)
        XCTAssertFalse(result)
    }

    func testDriveFileInfoProcessorConfigPreferPreview() {
        var result = DriveFileInfoProcessorConfig.preferPreview(fileType: .doc, previewFrom: .docsList, isInVCFollow: false)
        XCTAssertFalse(result)
        result = DriveFileInfoProcessorConfig.preferPreview(fileType: .doc, previewFrom: .docsList, isInVCFollow: true)
        XCTAssertTrue(result)
        result = DriveFileInfoProcessorConfig.preferPreview(fileType: .doc, previewFrom: .history, isInVCFollow: false)
        XCTAssertTrue(result)
    }
}


extension DefaultFileInfoProcessorTests {
    private func createSut(size: UInt64, name: String, node: DriveCache.Node?, preferPreview: Bool = true) -> DefaultFileInfoProcessor {
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview:preferPreview,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let type = SKFilePath.getFileExtension(from: name) ?? ""
        let meta = metaData(size: size, fileName: name)
        let cacheService = MockCacheService()
        cacheService.fileExist = (node != nil)
        let node = cacheNode(fileName: name, meta: meta)
        cacheService.fileResult = .success(node)

        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = DefaultFileInfoProcessor(cacheService: cacheService, fileInfo: fileInfo, config: config)
        return sut
    }
}
