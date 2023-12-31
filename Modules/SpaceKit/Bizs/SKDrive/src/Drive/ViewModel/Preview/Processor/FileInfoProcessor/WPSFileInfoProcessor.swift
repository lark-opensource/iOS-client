//
//  WPSFileInfoProcessor.swift
//  SKECM
//
//  Created by ZhangYuanping on 2021/3/30.
//  


import Foundation
import SKCommon
import SKFoundation

class WPSFileInfoProcessor: DefaultFileInfoProcessor {
    override func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState? {
        if !networkStatus.isReachable {
            return super.getCachePreviewInfo(fileInfo: fileInfo)
        }
        
        // vcfollow需要走转码、IM需要走wps, IM的其他场景都需要走转码（相似文件）
        let enableWPS = (!config.preferPreview) || config.isIMFile
        guard enableWPS else {
            return super.getCachePreviewInfo(fileInfo: fileInfo)
        }
        
        if isWebOfficeFromCache(fileInfo: fileInfo) {
            return .setupPreview(fileType: fileInfo.fileType, info: .previewWPS)
        }
        
        return nil
    }
    
    override func handleSuccess(_ fileInfo: DKFileProtocol) -> DriveProccessState? {

        // vcfollow需要走转码、IM需要走wps, IM的其他场景都需要走转码（相似文件）
        let enableWPS = (!config.preferPreview) || config.isIMFile
        
        guard fileInfo.webOffice && enableWPS else {
            // 走父类方法，使用缓存/下载文件进行预览
            return super.handleSuccess(fileInfo)
        }
        
        // 保存 WPS 的 WebOffice 信息
        let webOfficeInfo = DriveWebOfficeInfo(enable: fileInfo.webOffice)
        saveCacheData(webOfficeInfo, type: .webOfficeInfo, fileInfo: fileInfo)
        
        return .setupPreview(fileType: fileInfo.fileType, info: .previewWPS)
    }
    
    override func cacheFileIsSupported(fileInfo: DKFileProtocol) -> Bool {
        // WPS 缓存的数据是 webOfficeInfo 的数据
        return networkStatus.isReachable
    }
    
    /// 从缓存中检查是否支持 WPS 在线预览
    private func isWebOfficeFromCache(fileInfo: DKFileProtocol) -> Bool {
        guard let (_, data) = try? cacheService.getData(type: .webOfficeInfo,
                                                        fileExtension: fileInfo.fileExtension,
                                                        dataVersion: fileInfo.dataVersion).get() else {
            DocsLogger.driveInfo("WPSFileInfoProcessor --- weboffice data not found in cache")
            return false
        }
        
        do {
            let decoder = JSONDecoder()
            let officeInfo = try decoder.decode(DriveWebOfficeInfo.self, from: data)
            return officeInfo.enable
        } catch {
            DocsLogger.error("decode officeInfo failed with error", error: error)
            return false
        }
    }
}
