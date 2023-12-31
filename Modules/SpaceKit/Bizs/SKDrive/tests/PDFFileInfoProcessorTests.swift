//
//  PDFFileInfoProcessorTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ZhangYuanping on 2022/6/20.
//  


import XCTest
import SKFoundation
@testable import SKDrive
class PDFFileInfoProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    // 在有 partialPDF 缓存下，且在 VCFollow 下，不使用流式预览的缓存
    func testGetLinearPDFCacheInVCFollow() {
        let meta = metaData(size: 1024, fileName: "test.pdf")
        let node = cacheNode(fileName: "test.pdf", meta: meta)
        let sut = createSut(size: 1024, name: "test.pdf", fileExist: true,
                            fileResult: .failure(DriveError.fileInfoError),
                            fileData: .success((node, Data())),
                            reachable: true,
                            preferPreview: true,
                            isInVCFollow: true)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let result = sut.getCachePreviewInfo(fileInfo: fileInfo)
        XCTAssertNil(result)
    }
    
    // 获取到完整 PDF 缓存
    func testGetCachePreviewInfo() {
        let meta = metaData(size: 1024, fileName: "test.pdf")
        let node = cacheNode(fileName: "test.pdf", meta: meta)
        let sut = createSut(size: 1024, name: "test.pdf", fileExist: true,
                            fileResult: .success(node),
                            fileData: .success((node, Data())),
                            reachable: true,
                            preferPreview: true,
                            isInVCFollow: true)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let processState = sut.getCachePreviewInfo(fileInfo: fileInfo)
        var result = false
        if case .setupPreview(_, let info) = processState {
            if case .local(_, _) = info {
                result = true
            }
        }
        XCTAssertTrue(result)
    }
}

extension PDFFileInfoProcessorTests {
    private func createSut(size: UInt64,
                           name: String,
                           fileExist: Bool,
                           fileResult: Result<DriveCache.Node, Error>,
                           fileData: Result<(DriveCache.Node, Data), Error>,
                           reachable: Bool,
                           preferPreview: Bool = true,
                           isInVCFollow: Bool = false) -> PDFFileInfoProcessor {
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview:preferPreview,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: isInVCFollow, appID: "2", scene: .space)
        let meta = metaData(size: size, fileName: name)
        let cacheService = MockCacheService()
        cacheService.fileExist = fileExist
        cacheService.fileResult = fileResult
        cacheService.pdfData = fileData

        let mockNetStatus = MockNetworkStatusMonitor()
        mockNetStatus.isReachable = reachable
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let sut = PDFFileInfoProcessor(cacheService: cacheService,
                                       fileInfo: fileInfo,
                                       config: config,
                                       networkStatus: mockNetStatus)
        return sut
    }
}
