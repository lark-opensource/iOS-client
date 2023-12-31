//
//  OggFileInfoProcessor.swift
//  SKECM
//
//  Created by ZhangYuanping on 2021/6/8.
//  


import Foundation
import SKCommon
import SKFoundation

class OggFileInfoProcessor: DefaultFileInfoProcessor {
    
    override var useCacheIfExist: Bool {
        if networkStatus.isReachable {
            return false // 有网络不打开缓存的源文件，从网络加载转码数据
        } else {
            return true  // 无网络的情况下如果已经缓存或离线源文件，用源文件打开，显示不支持预览
        }
    }

    override func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState? {
        if !networkStatus.isReachable {
            return super.getCachePreviewInfo(fileInfo: fileInfo)
        }
        guard let video = checkVideoCache(fileInfo: fileInfo) else {
            DocsLogger.driveInfo("OggFileInfoProcessor --- unable to start ogg streaming, ogg data not found in cache")
            return nil
        }
        let previewInfo = DriveProccesPreviewInfo.streamVideo(video: video)
        return .setupPreview(fileType: .ogg, info: previewInfo)
    }
    
    // 视频需要判断是否有video缓存
    override func cacheFileIsSupported(fileInfo: DKFileProtocol) -> Bool {
        if checkVideoCache(fileInfo: fileInfo) != nil {
            return networkStatus.isReachable
        }
        return super.cacheFileIsSupported(fileInfo: fileInfo)
    }
    
    private func checkVideoCache(fileInfo: DKFileProtocol) -> DriveVideo? {
        guard let (fileNode, _) = try? cacheService.getData(type: .oggInfo,
                                                            fileExtension: fileInfo.fileExtension,
                                                            dataVersion: fileInfo.dataVersion).get() else {
            DocsLogger.driveInfo("OggFileInfoProcessor --- unable to start ogg streaming, ogg data not found in cache")
            return nil
        }
        guard let previewURL = fileInfo.getPreviewDownloadURLString(previewType: .ogg), let url = URL(string: previewURL) else {
            DocsLogger.driveInfo("OggFileInfoProcessor --- unable to start ogg streaming, failed to generate previewURL")
            return nil
        }
        let videoSize = fileNode.record.originFileSize ?? fileNode.fileSize
        let video = DriveVideo(type: .online(url: url), info: nil, title: fileInfo.name, size: videoSize, cacheKey: fileInfo.videoCacheKey, authExtra: config.authExtra)
        return video
    }
}
