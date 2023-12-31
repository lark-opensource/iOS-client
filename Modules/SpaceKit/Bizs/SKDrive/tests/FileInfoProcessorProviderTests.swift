//
//  FileInfoProcessorProviderTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/23.
//

import XCTest
import SKFoundation
@testable import SKDrive

class FileInfoProcessorProviderTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // ogg使用OggFileInfoProcessor
    func testDefaultFileInfoProviderWithOgg() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: true, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.ogg")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2",
                                                  scene: DKPreviewScene.space)
        let result = sut.processor(with: .ogg, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is OggFileInfoProcessor)
        
    }
    // 压缩文件使用ArchiveFileInfoProcessor
    func testDefaultFileInfoProviderWithArchive() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: true, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.zip")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .zip, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is ArchiveFileInfoProcessor)
    }
    
    // mp4使用VideoFileInfoProcessor
    func testDefaultFileInfoProviderWithVideo() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: true, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.mp4")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .mp4, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is VideoFileInfoProcessor)
    }

    // doc有网络，并且wps可用的情况下使用 WPSFileInfoProcessor
    func testDefaultFileInfoProviderWithWpsEnable() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: true, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.doc")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .doc, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is WPSFileInfoProcessor)
    }
    
    // doc有网络，并且wps不可用， 使用DefaultFileInfoProcessor
    func testDefaultFileInfoProviderWithWpsDisable() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: false, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.doc")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .doc, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is DefaultFileInfoProcessor)
    }
    
    // excel,wps可用，无网络使用HtmlFileInfoProcessor
    func testDefaultFileInfoProviderExcelWithWpsEnableNoNet() {
        let sut = createDefaultSut(isReachable: false, wpsEnable: true, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.xls")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .xls, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is HtmlFileInfoProcessor)
    }
    
    func testDefaultFileInfoProviderExcelWithWpsDisable() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: false, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.xls")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .xls, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is HtmlFileInfoProcessor)
    }

    func testDefaultFileInfoProviderWithLinealizedPDF() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: true, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.pdf")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .pdf, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is PDFFileInfoProcessor)
    }
    
    func testDefaultFileInfoProviderWithDefault() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: true, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.key")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .space)
        let result = sut.processor(with: .key, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is DefaultFileInfoProcessor)
    }
    
    // im 场景视频类型使用VideoFileInfoProcessor
    func testIMFileInfoProviderWithVideo() {
        let sut = createIMSut(wpsEnable: true)
        let meta = metaData(size: 1024, fileName: "file.mp4")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "1001", scene: .im)
        let result = sut.processor(with: .mp4, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is VideoFileInfoProcessor)
    }
    
    // im场景压缩文件使用ArchiveFileInfoProcessor
    func testIMFileInfoProviderWithArchive() {
        let sut = createIMSut(wpsEnable: true)
        let meta = metaData(size: 1024, fileName: "file.zip")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "1001", scene: .im)
        let result = sut.processor(with: .zip, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is ArchiveFileInfoProcessor)
    }
    
    // im场景doc，wps可用的情况下使用 WPSFileInfoProcessor
    func testIMFileInfoProviderWithWpsEnable() {
        let sut = createIMSut(wpsEnable: true)
        let meta = metaData(size: 1024, fileName: "file.doc")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .im)
        let result = sut.processor(with: .doc, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is WPSFileInfoProcessor)
    }
    
    // im场景doc，wps不可用可用的情况下使用 DefaultFileInfoProcessor
    func testIMFileInfoProviderWithWpsDisable() {
        let sut = createIMSut(wpsEnable: false)
        let meta = metaData(size: 1024, fileName: "file.doc")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .im)
        let result = sut.processor(with: .doc, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is DefaultFileInfoProcessor)
    }
    
    // im场景pdf文件 使用PDFFileInfoProcessor
    func testIMFileInfoProviderWithLinealizedPDF() {
        let sut = createIMSut(wpsEnable: true)
        let meta = metaData(size: 1024, fileName: "file.pdf")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .im)
        let result = sut.processor(with: .pdf, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is PDFFileInfoProcessor)
    }
    
    // im场景其他文件类型使用 DefaultFileInfoProcessor
    func testIMFileInfoProviderWithDefault() {
        let sut = createIMSut(wpsEnable: true)
        let meta = metaData(size: 1024, fileName: "file.key")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .linerizedPDF, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .im)
        let result = sut.processor(with: .png, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is DefaultFileInfoProcessor)
    }
    
    // 附件场景开启缩略图预览 预览图片图片文件使用ThumbfileInfoProcessor
    func testDefaultProviderWithImageWithThumbnailPreviewEnable() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: false, thumbPreviewEnable: true)
        let meta = metaData(size: 1024, fileName: "file.png")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .pngLin, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .attach)
        let result = sut.processor(with: .png, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is ThumbFileInfoProcessor)
    }
    
    // 附件场景关闭缩略图预览 预览图片图片文件使用DefaultFileInfoProcessor
    func testDefaultProviderWithImageWithThumbnailPreviewDisable() {
        let sut = createDefaultSut(isReachable: true, wpsEnable: false, thumbPreviewEnable: false)
        let meta = metaData(size: 1024, fileName: "file.png")
        let fileInfo = DriveFileInfo(fileMeta: meta, previewType: .pngLin, previewStatus: 1, webOffice: true)
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: false,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .docsList,
                                                  isInVCFollow: false, appID: "2", scene: .attach)
        let result = sut.processor(with: .png, originFileInfo: fileInfo, config: config)
        XCTAssertTrue(result is DefaultFileInfoProcessor)
    }
}

extension FileInfoProcessorProviderTests {
    func createDefaultSut(isReachable: Bool, wpsEnable: Bool, thumbPreviewEnable: Bool) -> DefaultFileInfoProcessorProvider {
        let cacheSerive = MockCacheService()
        let netStatus = MockNetworkStatusMonitor()
        netStatus.isReachable = isReachable
        let performanceLogger = DrivePerformanceRecorder(fileToken: "token",
                                                         fileType: "type",
                                                         previewFrom: .docsList,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        let sut = DefaultFileInfoProcessorProvider(cacheService: cacheSerive,
                                                   netStatus: netStatus,
                                                   wpsEnable: wpsEnable,
                                                   thumbnailPreviewEnable: thumbPreviewEnable,
                                                   performanceLogger: performanceLogger)
        return sut
    }
    
    func createIMSut(wpsEnable: Bool) -> DKFileInfoProcessorProvider {
        let cacheSerive = MockCacheService()
        let sut = DKFileInfoProcessorProvider(cacheService: cacheSerive, wpsEnable: wpsEnable)
        return sut
    }

}
