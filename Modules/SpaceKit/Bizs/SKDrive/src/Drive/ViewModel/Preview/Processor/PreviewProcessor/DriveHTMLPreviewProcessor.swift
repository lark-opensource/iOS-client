//
//  DriveHTMLPreviewProcessor.swift
//  SKECM
//
//  Created by zenghao on 2021/1/19.
//

import Foundation
import SKFoundation
import SKCommon
import SwiftyJSON

class DriveHTMLPreviewProcessor: DefaultPreviewProcessor {
    private let tabMaxSize: UInt64
    init(cacheService: DKCacheServiceProtocol,
         fileInfo: DKFileProtocol,
         handler: PreviewProcessHandler,
         config: DrivePreviewProcessorConfig,
         tabMaxSize: UInt64 = DriveFeatureGate.excelHtmlTabPreviewMaxSize) {
        self.tabMaxSize = tabMaxSize
        super.init(cacheService: cacheService, fileInfo: fileInfo, handler: handler, config: config)
    }
    override func handleReady(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        DocsLogger.driveInfo("DriveHTMLPreviewProcessor -- preview get success handle ready: downloadPreview")
        handler?.updateState(.endTranscoding(status: preview.previewStatus))
        let tabMaxSize = DriveFeatureGate.excelHtmlTabPreviewMaxSize
        if let extraInfo = preview.extra,
           DriveHTMLDataProvider.canPreviewHtmlByMaxSize(extraInfo: extraInfo,
                                                         tabMaxSize: tabMaxSize) {
            DocsLogger.driveInfo("riveHTMLPreviewProcessor -- preview html file")
            let info = DriveProccesPreviewInfo.previewHtml(extraInfo: extraInfo)
            handler?.updateState(.setupPreview(fileType: fileInfo.fileType, info: info))
            saveHtmlExtraInfo(extraInfo: extraInfo, fileInfo: fileInfo)
        } else {
            // 转码失败或者大小受限，下载视频原文件播放
            DocsLogger.driveInfo("riveHTMLPreviewProcessor -- handle HMLT Preview to download file")
            downloadOriginOrSimilarIfNeed()
        }
    }
    private func saveHtmlExtraInfo(extraInfo: String, fileInfo: DKFileProtocol) {
        let dataProvider = DriveHTMLDataProvider(fileToken: fileInfo.fileID,
                                                 dataVersion: fileInfo.dataVersion,
                                                 fileSize: fileInfo.size,
                                                 authExtra: config.authExtra,
                                                 mountPoint: fileInfo.mountPoint)
        dataProvider.saveExtraInfo(extraInfo, fileName: fileInfo.name)
    }
}
