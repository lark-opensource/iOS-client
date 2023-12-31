//
//  WPSFileInfoProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/22.
//

import XCTest
import SKFoundation
import SKCommon
@testable import SKDrive
class WPSFileInfoProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // WPS缓存的是 webOffice 信息，无网情况应该不走 WPSFileInfoProcessor(具体查看DefaultFileInfoProcessorProvider)
    // 所以如果是无网络情况，如果走入 WPSFileInfoProcessor 的缓存是不支持的
    func testGetCacheWhenUnReachable() {
        let meta = metaData(size: 1024, fileName: "test.docx")
        let node = cacheNode(fileName: "test.docx", meta: meta)
        let sut = createSut(size: 1024, name: "test.docx", node: node, reachable: false, preferPreview: false)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .unsupport(type) = result {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // wps vcfollow需要走转码, 无缓存
    func testGetCacheWhenInVCFollowWithoutCache() {
        let meta = metaData(size: 1024, fileName: "test.docx")
        let sut = createSut(size: 1024,
                            name: "test.docx",
                            node: nil,
                            reachable: true,
                            previewFrom: .vcFollow,
                            preferPreview: true)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        XCTAssertNil(result)
    }
    
    // wps vcfollow需要走转码, 有缓存
    func testGetCacheWhenInVCFollowHasCache() {
        let meta = metaData(size: 1024, fileName: "test.docx")
        // 缓存转码文件pdf
        let node = cacheNode(fileName: "test.pdf", meta: meta)
        let sut = createSut(size: 1024,
                            name: "test.docx",
                            node: node,
                            reachable: true,
                            previewFrom: .vcFollow,
                            preferPreview: true)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(type, info) = result {
            XCTAssertTrue(type == .pdf)
            if case .local(_, _) = info {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // wps 有网络情况并且非vcfollow下使用wps缓存信息
    func testGetCacheWhenNotFollowAndReachable() {
        let meta = metaData(size: 1024, fileName: "test.docx")
        let node = cacheNode(fileName: "test.docx", meta: meta)
        let sut = createSut(size: 1024,
                            name: "test.docx",
                            node: node,
                            reachable: true,
                            previewFrom: .docsList,
                            preferPreview: false)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        if case let .setupPreview(type, info) = result {
            XCTAssertTrue(type == .docx)
            if case .previewWPS = info {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }
    }

    // wps 获取fileInfo成功后使用线上wps预览
    func testHandleSuccessPreviewWithWPS() {
        let meta = metaData(size: 1024, fileName: "test.docx")
        let node = cacheNode(fileName: "test.docx", meta: meta)
        let sut = createSut(size: 1024,
                            name: "test.docx",
                            node: node,
                            reachable: true,
                            previewFrom: .docsList,
                            preferPreview: false)
        let fileInfo = DriveFileInfo(fileMeta: meta, webOffice: true)
        let result = sut.handleSuccess(fileInfo)
        if case let .setupPreview(type, info) = result {
            XCTAssertTrue(type == .docx)
            if case .previewWPS = info {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }
    }
    
    // wps vcfollow获取fileInfo成功后使用缓存转码文件
    func testHandleSuccessPreviewWithLocalPDF() {
        let meta = metaData(size: 1024, fileName: "test.docx")
        let sut = createSut(size: 1024,
                            name: "test.docx",
                            node: nil,
                            reachable: true,
                            previewFrom: .vcFollow,
                            preferPreview: true)
        // 支持转码为pdf
        let fileInfo = DriveFileInfo(fileMeta: meta,
                                     previewType: .linerizedPDF,
                                     previewStatus: 1,
                                     webOffice: true)
        let result = sut.handleSuccess(fileInfo)
        if case .startPreviewGet = result {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
}

extension WPSFileInfoProcessorTests {
    private func createSut(size: UInt64,
                           name: String,
                           node: DriveCache.Node?,
                           reachable: Bool,
                           previewFrom: DrivePreviewFrom = .docsList,
                           preferPreview: Bool = true) -> WPSFileInfoProcessor {
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview:preferPreview,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: previewFrom,
                                                  isInVCFollow: false, appID: "1001", scene: .im)
        let meta = metaData(size: size, fileName: name)
        let cacheService = MockCacheService()
        cacheService.fileExist = (node != nil)
        if let node = node {
            cacheService.fileResult = .success(node)
            let info = DriveWebOfficeInfo(enable: true)
            let encoder = JSONEncoder()
            let data = try? encoder.encode(info)
            cacheService.wpsData = .success((node, data!))
        }

        let mockNetStatus = MockNetworkStatusMonitor()
        mockNetStatus.isReachable = reachable
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = WPSFileInfoProcessor(cacheService: cacheService,
                                       fileInfo: fileInfo,
                                       config: config,
                                       networkStatus: mockNetStatus)
        return sut
    }
}
