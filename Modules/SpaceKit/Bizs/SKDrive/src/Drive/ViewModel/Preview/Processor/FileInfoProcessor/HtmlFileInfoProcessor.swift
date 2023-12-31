//
//  HtmlFileInfoProcessor.swift
//  SKECM
//
//  Created by zenghao on 2021/2/7.
//

import Foundation
import SKFoundation
import SKCommon
import LarkSecurityComplianceInterface

class HtmlFileInfoProcessor: DefaultFileInfoProcessor {

    override func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState? {
        if let state = getOfflineCACState(fileId: fileInfo.fileID) {
            return state
        }
        switch config.previewFrom {
        case .vcFollow:
            return super.getCachePreviewInfo(fileInfo: fileInfo)
        default:
            let dataProvider = DriveHTMLDataProvider(fileToken: fileInfo.fileID,
                                                     dataVersion: fileInfo.dataVersion,
                                                     fileSize: fileInfo.size,
                                                     authExtra: config.authExtra,
                                                     mountPoint: fileInfo.mountPoint)
            guard let extra = dataProvider.getExtraInfo() else {
                DocsLogger.driveInfo("html extra info for file not found in cache")
                // 有网络情况下，无 html extra 信息，则直接 return nil
                if networkStatus.isReachable {
                    return nil
                }
                return super.getCachePreviewInfo(fileInfo: fileInfo)
            }
            
            DocsLogger.driveInfo("preview html with extra info from cache")
            let info = DriveProccesPreviewInfo.previewHtml(extraInfo: extra)
            return .setupPreview(fileType: fileInfo.fileType, info: info)
        }
        
    }
}
