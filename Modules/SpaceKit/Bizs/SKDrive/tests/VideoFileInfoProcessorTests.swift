//
//  VideoFileInfoProcessorTests.swift
//  SKDrive_Tests
//
//  Created by bupozhuang on 2022/4/10.
//

import XCTest
import SKFoundation
@testable import SKDrive

class VideoFileInfoProcessorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    // 有网络使用videoInfo缓存
    func testGetCachePreviewInfo() {
        let sut = createSut(isReachable: true)
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileinfo)
        if case let .setupPreview(type, _) = result {
            XCTAssertTrue(type == .mp4)
        } else {
            XCTAssertTrue(false)
        }
        
    }
    // 无网络不使用videoInfo缓存
    func testGetCachePreviewInfoWithNoNet() {
        let sut = createSut(isReachable: false)
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileinfo)
        if let result = result {
            if case .cacDenied = result {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(true)
        }
    }
    // videoInfo缓存支持预览
    func testcacheFileIsSupported() {
        let sut = createSut(isReachable: true)
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        let result = sut.cacheFileIsSupported(fileInfo: fileinfo)
        XCTAssertTrue(result)
    }
    
    private func createSut(isReachable: Bool) -> VideoFileInfoProcessor {
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        let cacheService = MockCacheService()
        let node = cacheNode(fileName: "test.mp4", meta: meta)
        let videoInfo = DriveVideoInfo(type: 0, transcodeURLs: ["360": "https://feishu.cn/vide0.mp4"])
        let data = try? JSONEncoder().encode(videoInfo)
        cacheService.videoData = .success((node, data!))
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview:true,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let networkStatus = MockNetworkStatusMonitor()
        networkStatus.isReachable = isReachable
        let sut = VideoFileInfoProcessor(cacheService: cacheService,
                                         fileInfo: fileinfo, config: config,
                                         networkStatus: networkStatus)
        return sut
    }
}
