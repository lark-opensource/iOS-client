//
//  ThumbFileInfoProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/8/15.
//

import XCTest
import SKCommon
import SpaceInterface
import RxSwift
import SKFoundation
@testable import SKDrive

class ThumbFileInfoProcessorTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    
    func testInitailize() {
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview:false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let meta = metaData(size: 1024, fileName: "name.png")
        let cacheService = MockCacheService()

        let mockNetStatus = MockNetworkStatusMonitor()
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = ThumbFileInfoProcessor(cacheService: cacheService,
                                       fileInfo: fileInfo,
                                       config: config,
                                         networkStatus: mockNetStatus)
        XCTAssertNotNil(sut)
    }

    func testGetCacheWithOutCache() {
        let meta = metaData(size: 1024, fileName: "test.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = createSut(size: 1024, name: "test.ogg", node: nil, cover: nil, reachable: true)
        XCTAssertNil(sut.getCachePreviewInfo(fileInfo: fileInfo))
    }
    
    func testGetCacheWithThumbCache() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let node = cacheCoverNode(fileName: fileName, meta: meta, recordType: .imageCover(width: 480, height: 300))
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: node, reachable: true)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(type, info) = result, case let .thumb(image) = info {
            XCTAssertTrue(type == .png)
            XCTAssertNotNil(image)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testGetCacheWithThumbCacheDriveDisable() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let node = cacheCoverNode(fileName: fileName, meta: meta, recordType: .imageCover(width: 480, height: 300))
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: node, reachable: true, driveEnable: false)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        XCTAssertNil(result)
    }
    
    func testGetCacheWithThumbCacheFallback() {
        let fileName = "test.png"
        let meta = metaData(size: 51 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let node = cacheCoverNode(fileName: fileName, meta: meta, recordType: .imageCover(width: 480, height: 300))
        let sut = createSut(size: 51 * 1024 * 1024, name: fileName, node: nil, cover: node, reachable: true, driveEnable: true)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(type, _) = result {
            XCTAssertTrue(type == .png)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testGetCacheWithOriginCache() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let node = cacheNode(fileName: fileName, meta: meta, recordType: .imageCover(width: 480, height: 300))
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: node, cover: nil, reachable: true)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(type, info) = result {
            XCTAssertTrue(type == .png)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testGetCacheWithThumbCacheInvalid() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let node = invalidCacheCoverNode(fileName: fileName, meta: meta, recordType: .imageCover(width: 480, height: 300))
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: node, reachable: true)
        XCTAssertNil(sut.getCachePreviewInfo(fileInfo: fileInfo))
    }
    
    // test handler fileinfo
    func testHandleFileInfoWithoutMeta() {
        let fileName = "test.png"
        let fileInfo = DKFileInfo(appId: "1001",
                                  fileId: "token",
                                  name: fileName,
                                  size: 2 * 1024 * 1024,
                                  fileToken: "token", authExtra: nil)
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: nil, reachable: true)
        let expect = expectation(description: "expect download origin")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: false) { state in
            if case .downloadOrigin = state {
                XCTAssertTrue(true)
            } else {
                XCTFail("expect download origin state")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testHandleFileInfoFallback() {
        let fileName = "test.png"
        let meta = metaData(size: 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = createSut(size: 1024, name: fileName, node: nil, cover: nil, reachable: true)
        let expect = expectation(description: "expect fallback")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: true) { state in
            XCTAssertNil(state)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    // 没有缓存、转码成功、渐进式 -> 走渐进式
    func testHandleFileInfoWithoutCacheWithImageLinPreviewType() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let context = DriveFilePreviewContext(status: 0)
        let filePreview = DriveFilePreview(context: context)
        let previewMetas = [DrivePreviewFileType.jpgLin: filePreview]
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .jpgLin, previewStatus: 0, previewMetas: previewMetas)
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: nil, reachable: true)
        let expect = expectation(description: "expect do ")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: false) { state in
            if case .startPreviewGet = state {
                XCTAssertTrue(true)
            } else {
                XCTFail("state not expect \(state)")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testHandleFileInfoHasOpenFromCache() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: nil, reachable: true)
        let expect = expectation(description: "expect do nothing")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: true) { state in
            XCTAssertNil(state)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testHandleFileInfoDownloadThumbSucess() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: nil, reachable: true)
        let expect = expectation(description: "expect do nothing")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: false) { state in
            if case let .setupPreview(type, info) = state, case let .thumb(image) = info {
                XCTAssertTrue(type == .png)
                XCTAssertNotNil(image)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testHandleFileInfoDownloadThumbFailed() {
        let fileName = "test.png"
        let meta = metaData(size: 2 * 1024 * 1024, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = createSut(size: 2 * 1024 * 1024, name: fileName, node: nil, cover: nil, reachable: true, downloadSuccess: false)
        let expect = expectation(description: "expect do nothing")
        sut.handle(fileInfo: fileInfo, hasOpenFromCache: false) { state in
            if case .downloadOrigin = state {
                XCTAssertTrue(true)
            } else {
                XCTFail("expect download origin state")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }

    private func createSut(size: UInt64,
                           name: String,
                           node: DriveCache.Node?,
                           cover: DriveCache.Node?,
                           reachable: Bool,
                           preferPreview: Bool = true,
                           driveEnable: Bool = true,
                           downloadSuccess: Bool = true) -> ThumbFileInfoProcessor {
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview:preferPreview,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let meta = metaData(size: size, fileName: name)
        let cacheService = MockCacheService()
        cacheService.fileExist = (node != nil)

        if let node = node {
            cacheService.fileResult = .success(node)
            cacheService.fileData = .success((node, Data()))
        }
        if let coverNode = cover, let fileURL = coverNode.fileURL, let data = try? Data.read(from: fileURL) {
            cacheService.coverData = .success((coverNode, data))
        }

        let mockNetStatus = MockNetworkStatusMonitor()
        mockNetStatus.isReachable = reachable
        let fileInfo = DriveFileInfo(fileMeta: meta)
        var dependency = MockThumbFileInfoDepenencyImpl()
        dependency.driveEnabled = driveEnable
        dependency.downloader.downloadSuccess = downloadSuccess
        let performanceLogger = DrivePerformanceRecorder(fileToken: fileInfo.fileToken,
                                                         fileType: fileInfo.type,
                                                         previewFrom: config.previewFrom,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        let sut = ThumbFileInfoProcessor(cacheService: cacheService,
                                       fileInfo: fileInfo,
                                         config: config,
                                         performanceLogger: performanceLogger,
                                         networkStatus: mockNetStatus,
                                         dependency: dependency)
        return sut
    }
}

struct MockThumbFileInfoDepenencyImpl: ThumbFileInfoProcessorDependency {
    var driveEnabled: Bool = true
    var apps: [String] = ["2"]
    var downloader: MockThumbDownloader = MockThumbDownloader()
    var minSizeForThumbnailPreview: UInt64 {
        return 1 * 1024 * 1024
    }
    func checkIfSupport(appID: String) -> Bool {
        return apps.contains(appID)
    }
    func maxFileSize(for type: String) -> UInt64 {
        return 50 * 1024 * 1024
    }
    func downloader(cacheCheck: @escaping () -> Data?) -> ThumbDownloaderProtocol {
        return downloader
    }
}

struct MockThumbDownloader: ThumbDownloaderProtocol {
    var downloadSuccess: Bool = true
    func downloadThumb(meta: DriveFileMeta, extra: String?, priority: DocCommonDownloadPriority, teaParams: [String : String]) -> Observable<UIImage> {
        if downloadSuccess {
            return Observable<UIImage>.just(UIImage())
        } else {
            let error = NSError(domain: "download thumbnail error", code: 999, userInfo: nil) as Error
            return Observable<UIImage>.error(error)
        }
    }
}
