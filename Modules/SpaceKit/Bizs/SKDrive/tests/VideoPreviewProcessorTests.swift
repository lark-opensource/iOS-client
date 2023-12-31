//
//  VideoPreviewProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/25.
//

import XCTest
@testable import SKFoundation
@testable import SKDrive
import SwiftyJSON

class VideoPreviewProcessorTests: XCTestCase {
    var handler: MockPreviewProcessHandler!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    // handle ready with videoInfo
    // update state endTranscoding -> setupPreview
    func testHandleReadyWithVideoInfo() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.mp4",
                            previewType: .linerizedPDF,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let videoInfo = DriveVideoInfo(type: 1, transcodeURLs: ["360": "https://video.mp4"])
        let context = DriveFilePreviewContext(status: 0,
                                              interval: nil,
                                              longPushInterval: nil,
                                              previewURL: nil,
                                              previewFileSize: nil,
                                              linearized: nil,
                                              videoInfo: videoInfo,
                                              extra: nil)
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
    
    // handle ready with out videoInfo, and local support and canDownloadOrigin
    // update state endTranscoding -> downloadOrigin
    func testHandleReadyWithoutVideoInfo() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.mp4",
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
        
        if case .downloadOrigin = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // handle ready with out videoInfo, and local unsupport
    // update state endTranscoding -> .unsupport
    func testHandleReadyWithoutVideoInfoLocalUnsupport() {
        handler = MockPreviewProcessHandler()
        let sut = createSut(fileName: "test.webm",
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
        
        if case .unsupport = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }

    // Downgrade video playing to origin online playing
    // Check video meta
    // update state: endTranscoding -> endTranscoding -> setupPreview
    func testDowngradeToOriginOnlinePlayingWithLimitation() {
        _testDowngradeToOriginOnlinePlaying(do_not_check_meta: false)
    }

    // Downgrade video playing to origin online playing
    // Do not check video meta
    // update state: endTranscoding -> endTranscoding -> setupPreview
    func testDowngradeToOriginOnlinePlayingWithoutLimitation() {
        _testDowngradeToOriginOnlinePlaying(do_not_check_meta: true)
    }

    // Check and use local cache to playback if the status is generating
    // update state: endTranscoding -> setupPreview
    func testHandleGeneratingWithCache() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.drive.mobile.enable_user_download_video_during_transcoding",
                                      value: true)

        handler = MockPreviewProcessHandler()
        let fileName = "test.mp4"
        let fileSize: UInt64 = 1024
        let cacheNode = createCacheNode(recordType: .preview, fileName: fileName, fileSize: fileSize)
        let sut = createSut(fileName: fileName,
                            fileSize: fileSize,
                            previewType: .mp4,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: false,
                            cacheNode: cacheNode,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 1)
        let preview = DriveFilePreview(context: context)

        sut.handleGenerating(preview: preview, pullInterval: 60 * 1000) {
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

    // No cache available
    // Can not downgrade to origin online playing
    // update state: endTranscoding -> fetchPreviewURLFail
    func testHandleFailedNoRetryWithoutCache() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.drive.mobile.drop_origin_video_preview_limitation",
                                      value: false)
        UserScopeNoChangeFG.setMockFG(key: "ccm.drive.mobile.enable_user_download_video_during_transcoding",
                                      value: true)

        handler = MockPreviewProcessHandler()
        let fileName = "test.mp4"
        let fileSize: UInt64 = 10 * 1024 * 1024 * 1024
        let sut = createSut(fileName: fileName,
                            fileSize: fileSize,
                            previewType: .mp4,
                            allowDowngradeToOrigin: false,
                            isInVCFollow: false,
                            canDownloadOrigin: false,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        let context = DriveFilePreviewContext(status: 3)
        let preview = DriveFilePreview(context: context)

        sut.handleFailedNoRetry(preview: preview) {
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
        
        if case .fetchPreviewURLFail = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }

    private func _testDowngradeToOriginOnlinePlaying(do_not_check_meta: Bool) {
        UserScopeNoChangeFG.setMockFG(key: "ccm.drive.mobile.drop_origin_video_preview_limitation",
                                      value: do_not_check_meta)

        let extra = generateDriveMediaMetaJsonString(codecName: "h264",
                                                     codecType: "video",
                                                     bitRate: "8000")
        XCTAssertNotNil(extra)

        handler = MockPreviewProcessHandler()
        let context = DriveFilePreviewContext(status: 0, extra: extra ?? "{}")
        let preview = DriveFilePreview(context: context)
        let videoMeta: [DrivePreviewFileType: DriveFilePreview] = [.videoMeta: preview]
        let sut = createSut(fileName: "test.mp4",
                            fileSize: 10 * 1024 * 1024 * 1024,
                            previewType: .mp4,
                            allowDowngradeToOrigin: true,
                            isInVCFollow: false,
                            canDownloadOrigin: true,
                            previewMetas: videoMeta,
                            handler: handler)
        let expect = expectation(description: "handle update state")
        sut.handleReady(preview: preview) {
            expect.fulfill()
        }
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(handler.states.count == 3)
        if case .endTranscoding = handler.states[0] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        if case .endTranscoding = handler.states[1] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        if case .setupPreview = handler.states[2] {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
}

extension VideoPreviewProcessorTests {
    func createSut(fileName: String,
                   fileSize: UInt64 = 1024,
                   previewType: DrivePreviewFileType? = nil,
                   allowDowngradeToOrigin: Bool,
                   isInVCFollow: Bool = false,
                   canDownloadOrigin: Bool = false,
                   previewMetas: [DrivePreviewFileType: DriveFilePreview] = [:],
                   cacheNode: DriveCache.Node? = nil,
                   handler: PreviewProcessHandler) -> VideoPreviewProcessor {
        let cacheService = MockCacheService()
        if let cacheNode = cacheNode {
            cacheService.fileResult = .success(cacheNode)
        }
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: allowDowngradeToOrigin,
                                                 canDownloadOrigin: canDownloadOrigin,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard)
        let meta = metaData(size: fileSize, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: previewType, previewMetas: previewMetas)
        let sut = VideoPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: handler, config: config)
        return sut
    }

    func createCacheNode(recordType: DriveCache.Record.RecordType,
                         fileName: String,
                         fileSize: UInt64) -> DriveCache.Node {
        let record = DriveCache.Record(token: "token",
                                       version: "",
                                       recordType: recordType,
                                       originName: fileName,
                                       originFileSize: fileSize,
                                       fileType: nil,
                                       cacheType: .transient)
        let cacheNode = DriveCache.Node(record: record,
                             fileName: fileName,
                             fileSize: fileSize,
                             fileURL: SKFilePath(absPath: "file:///local/cache/\(fileName)"))
        return cacheNode
    }
}

extension VideoPreviewProcessorTests {
    private struct ExtraMetaInfo: Codable {
        let metaInfo: DriveMediaMetaInfo
        private enum CodingKeys: String, CodingKey {
            case metaInfo = "meta_info"
        }
    }

    private func generateDriveMediaMetaJsonString(codecName: String,
                                                  codecType: String,
                                                  bitRate: String) -> String? {
        let videoMeta = DriveVideoMeta(
            codecName: codecName,
            codecType: codecType,
            codecTag: "avc1",
            bitRate: bitRate,
            width: 1280,
            height: 720)
        let extraMetaInfo = ExtraMetaInfo(metaInfo: DriveMediaMetaInfo(streams: [videoMeta]))

        guard let data = try? JSONEncoder().encode(extraMetaInfo) else {
            return nil
        }
        guard let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}
