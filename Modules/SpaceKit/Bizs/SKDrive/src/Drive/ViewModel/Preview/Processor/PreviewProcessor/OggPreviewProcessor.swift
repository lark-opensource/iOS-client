//
//  OggPreviewProcessor.swift
//  SKECM
//
//  Created by ZhangYuanping on 2021/6/6.
//  

import SKFoundation

class OggPreviewProcessor: DefaultPreviewProcessor {
    override func handleReady(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        handler?.updateState(.endTranscoding(status: preview.previewStatus))
        guard let mimeTypeString = preview.mimeType else {
            // 转码失败，下载视频原文件播放
            DocsLogger.driveInfo("OggPreviewProcessor -- preview failed, not support")
            handler?.updateState(.unsupport(type: .typeUnsupport))
            return
        }
        guard let onlineString = fileInfo.getPreviewDownloadURLString(previewType: .ogg),
              let onlineURL = URL(string: onlineString) else {
            DocsLogger.error("OggPreviewProcessor -- sessionPreviewDownloadURLString is nil!")
            handler?.updateState(.unsupport(type: .typeUnsupport))
            return
        }
        
        let cacheKey = fileInfo.videoCacheKey
        let video = DriveVideo(type: .online(url: onlineURL),
                               info: nil,
                               title: fileInfo.name,
                               size: fileInfo.size,
                               cacheKey: cacheKey,
                               authExtra: config.authExtra)
        let info = DriveProccesPreviewInfo.streamVideo(video: video)
        handler?.updateState(.setupPreview(fileType: .ogg, info: info))

        // 保存ogg信息
        let oggInfo = DriveOggInfo(mimeType: mimeTypeString, previewType: DrivePreviewFileType.ogg.rawValue)
        saveCacheData(oggInfo, type: .oggInfo)
    }
}
