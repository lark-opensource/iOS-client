//
//  ArchiveFileInfoProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/22.
//

import XCTest
import SKFoundation
@testable import SKDrive

class ArchiveFileInfoProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testUseCacheIfExistWhenReachable() {
        let meta = metaData(size: 1024, fileName: "test.zip")
        let node = cacheNode(fileName: "test.zip", meta: meta)
        let sut = createSut(size: 1024, name: "test.zip", node: node, reachable: true)
        let result = sut.useCacheIfExist
        XCTAssertFalse(result)
    }
    
    func testUseCacheIfExistWhenUnReachable() {
        let meta = metaData(size: 1024, fileName: "test.zip")
        let node = cacheNode(fileName: "test.zip", meta: meta)
        let sut = createSut(size: 1024, name: "test.zip", node: node, reachable: false)
        let result = sut.useCacheIfExist
        XCTAssertTrue(result)
    }
}

extension ArchiveFileInfoProcessorTests {
    private func createSut(size: UInt64,
                           name: String,
                           node: DriveCache.Node?,
                           reachable: Bool,
                           preferPreview: Bool = true) -> ArchiveFileInfoProcessor {
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: preferPreview,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2",
                                                  scene: DKPreviewScene.space)
        let type = SKFilePath.getFileExtension(from: name) ?? ""
        let meta = metaData(size: size, fileName: name)
        let cacheService = MockCacheService()
        cacheService.fileExist = (node != nil)
        let node = cacheNode(fileName: name, meta: meta)
        cacheService.fileResult = .success(node)

        let mockNetStatus = MockNetworkStatusMonitor()
        mockNetStatus.isReachable = reachable
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = ArchiveFileInfoProcessor(cacheService: cacheService, fileInfo: fileInfo, config: config, networkStatus: mockNetStatus)
        return sut
    }
}
