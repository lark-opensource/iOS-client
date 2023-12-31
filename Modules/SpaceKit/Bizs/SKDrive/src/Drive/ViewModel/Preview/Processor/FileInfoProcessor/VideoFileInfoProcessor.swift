//
//  VideoFileInfoProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/7.
//

import Foundation
import SKCommon
import SKFoundation

class VideoFileInfoProcessor: DefaultFileInfoProcessor {
    override func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState? {
        if !networkStatus.isReachable {
            DocsLogger.driveError("VideoFileInfoProcessor -- no network")
            return super.getCachePreviewInfo(fileInfo: fileInfo)
        }
        guard let videoInfo = checkVideoCache(fileInfo: fileInfo) else {
            DocsLogger.driveInfo("VideoFileInfoProcessor -- video info for file not found in cache")
            return nil
        }
        DocsLogger.driveInfo("VideoFileInfoProcessor -- preview online video with video info from cache, cacheKey: \(videoInfo.cacheKey)")
        let info = DriveProccesPreviewInfo.streamVideo(video: videoInfo)
        return .setupPreview(fileType: .mp4, info: info)
    }
    
    // 视频需要判断是否有video缓存
    override func cacheFileIsSupported(fileInfo: DKFileProtocol) -> Bool {
        if checkVideoCache(fileInfo: fileInfo) != nil && networkStatus.isReachable {
            return true
        }
        return super.cacheFileIsSupported(fileInfo: fileInfo)
    }

    private func checkVideoCache(fileInfo: DKFileProtocol) -> DriveVideo? {
        guard let urlString = fileInfo.getPreviewDownloadURLString(previewType: DrivePreviewFileType.mp4),
              let previewURL = URL(string: urlString) else {
            DocsLogger.driveInfo("VideoFileInfoProcessor --- unable to start video streaming, failed to generate previewURL")
            return nil
        }
        guard let (fileNode, data) = try? cacheService.getData(type: .videoInfo,
                                                         fileExtension: fileInfo.fileExtension,
                                                         dataVersion: fileInfo.dataVersion).get() else {
            DocsLogger.driveInfo("VideoFileInfoProcessor --- unable to start video streaming, video data not found in cache")
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let videoInfo = try decoder.decode(DriveVideoInfo.self, from: data)
            let videoSize = fileNode.record.originFileSize ?? fileNode.fileSize
            let video = DriveVideo(type: .online(url: previewURL), info: videoInfo, title: fileInfo.name, size: videoSize, cacheKey: fileInfo.videoCacheKey, authExtra: config.authExtra)
            return video
        } catch {
            DocsLogger.error("VideoFileInfoProcessor -- decode video info failed with error", error: error)
            return nil
        }
    }
}
