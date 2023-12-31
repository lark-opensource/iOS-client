//
//  OggFileInfoProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/22.
//

import XCTest
import SKFoundation
@testable import SKDrive
class OggFileInfoProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // ogg在有网络情况下不使用缓存
    func testUserCacheIfExistWhenReachable() {
        let meta = metaData(size: 1024, fileName: "test.ogg")
        let node = cacheNode(fileName: "test.ogg", meta: meta)
        let sut = createSut(size: 1024, name: "test.ogg", node: node, reachable: true)
        let result = sut.useCacheIfExist
        XCTAssertFalse(result)
    }

    // ogg在无网络情况下会使用缓存
    func testUserCacheIfExistWhenUnReachable() {
        let meta = metaData(size: 1024, fileName: "test.ogg")
        let node = cacheNode(fileName: "test.ogg", meta: meta)
        let sut = createSut(size: 1024, name: "test.ogg", node: node, reachable: false)
        let result = sut.useCacheIfExist
        XCTAssertTrue(result)
    }
    
    // ogg在无网络情况下不使用ogg缓存，使用源文件缓存, 展示不支持
    func testGetCacheWhenUnReachable() {
        let meta = metaData(size: 1024, fileName: "test.ogg")
        let node = cacheNode(fileName: "test.ogg", meta: meta)
        let sut = createSut(size: 1024, name: "test.ogg", node: node, reachable: false)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case .cacDenied = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("result is \(String(describing: result))")
        }
    }
    
    // ogg在有网络情况下使用在线视频缓存
    func testGetCacheWhenReachableWithCache() {
        let meta = metaData(size: 1024, fileName: "test.ogg")
        let node = cacheNode(fileName: "test.ogg", meta: meta)
        let sut = createSut(size: 1024, name: "test.ogg", node: node, reachable: true)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(type, _) = result {
            XCTAssertTrue(type == .ogg)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // ogg在有网络情况下没有缓存
    func testGetCacheWhenReachableWithOutCache() {
        let meta = metaData(size: 1024, fileName: "test.ogg")
        let sut = createSut(size: 1024, name: "test.ogg", node: nil, reachable: true)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        XCTAssertNil(result)
    }
}

extension OggFileInfoProcessorTests {
    private func createSut(size: UInt64,
                           name: String,
                           node: DriveCache.Node?,
                           reachable: Bool,
                           preferPreview: Bool = true) -> OggFileInfoProcessor {
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
            cacheService.oggData = .success((node, Data()))
        }

        let mockNetStatus = MockNetworkStatusMonitor()
        mockNetStatus.isReachable = reachable
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = OggFileInfoProcessor(cacheService: cacheService,
                                       fileInfo: fileInfo,
                                       config: config,
                                       networkStatus: mockNetStatus)
        return sut
    }
}
