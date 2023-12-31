//
//  PDFFileInfoProcessor.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/6/20.
//  


import Foundation
import SKCommon
import SKFoundation
import LarkDocsIcon

class PDFFileInfoProcessor: DefaultFileInfoProcessor {
    override func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState? {
        // PDF可能有三种缓存，similar、preview、partialPDF
        // 优先先判断是否已经完全下载，包括similar和preview
        // 如果没有下载完成在判断是否部分下载
        if !networkStatus.isReachable {
            return super.getCachePreviewInfo(fileInfo: fileInfo)
        }
        if let node = super.cacheFileNode(fileInfo: fileInfo) {
            DocsLogger.driveInfo("PDFFileInfoProcessor -- pdf download finished")
            guard let path = node.fileURL else {
                spaceAssertionFailure("PDFFileInfoProcessor -- cache node fileURL not set")
                return nil
            }
            return .setupPreview(fileType: .pdf,
                                 info: .local(url: path,
                                              originFileType: DriveFileType(fileExtension: node.record.originFileExtension)))
        } else {
            return nil
        }
    }
    
}
