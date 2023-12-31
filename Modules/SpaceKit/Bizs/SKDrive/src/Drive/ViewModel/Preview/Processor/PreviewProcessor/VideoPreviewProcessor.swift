//
//  VideoPreviewProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/8.
//

import SKFoundation
import SKCommon
import SKInfra
import LarkDocsIcon


class VideoPreviewProcessor: DefaultPreviewProcessor {
    // 转码成功
    override func handleReady(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        defer {
            completion()
        }
        handler?.updateState(.endTranscoding(status: preview.previewStatus))

        if OpenAPI.docs.driveVideoPlayOriginEnable {
            // 调试面板开启了原视频在线播放，则直接走转码中逻辑，里面包含判断小视频及低码率视频支持直接播放
            // nolint: magic number
            handleGenerating(preview: preview, pullInterval: 10000, completion: {})
        } else {
            // 正常流程
            handleVideoReady(preview: preview)
        }
    }

    // 转码中
    override func handleGenerating(preview: DriveFilePreview, pullInterval: Int64, completion: @escaping (() -> Void)) {
        canUseLocalIMVideoCache { [weak self] previewInfo in
            guard let self else { return }
            DocsLogger.driveInfo("VideoPreviewProcessor -- handleGenerating", extraInfo: ["previewInfo": previewInfo])

            if let previewInfo { // 优先获取IM本地缓存，否则继续走源地址播放或者在线播放逻辑
                self.handler?.updateState(.setupPreview(fileType: self.fileInfo.fileType, info: previewInfo))
                completion()
            } else {
                if playCachedVideoIfCapable(previewStatus: preview.previewStatus) {
                    completion()
                } else if self.playOriginVideoIfCapable() {
                    completion()
                } else {
                    self.defaultHandleGenerating(preview: preview, pullInterval: pullInterval, completion: completion)
                }
            }
        }
    }

    // 转码失败
    override func handleFailedNoRetry(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        canUseLocalIMVideoCache { [weak self] previewInfo in
            guard let self else { return }
            DocsLogger.driveInfo("VideoPreviewProcessor -- handleFailedNoRetry", extraInfo: ["previewInfo": previewInfo])

            if let previewInfo { // 优先获取IM本地缓存，否则继续走源地址播放或者在线播放逻辑
                self.handler?.updateState(.setupPreview(fileType: self.fileInfo.fileType, info: previewInfo))
                completion()
            } else {
                if playCachedVideoIfCapable(previewStatus: preview.previewStatus) {
                    completion()
                } else if self.playOriginVideoIfCapable() {
                    completion()
                } else {
                    self.defaultHandleFailedNoRetry(preview: preview, completion: completion)
                }
            }
        }
    }

    override var downgradeWhenGenerating: Bool {
        guard UserScopeNoChangeFG.ZYP.transcodingVideoDownloadEnable else {
            return super.downgradeWhenGenerating
        }
        if isSmallVideo() {
            return true
        }
        return super.downgradeWhenGenerating
    }


    // MARK: - Private function
    // swift 不允许在闭包中调用super方法，采用
    private func defaultHandleFailedNoRetry(preview: DriveFilePreview, completion: @escaping (() -> Void)) {
        super.handleFailedNoRetry(preview: preview, completion: completion)
    }

    private func defaultHandleGenerating(preview: DriveFilePreview, pullInterval: Int64, completion: @escaping (() -> Void)) {
        super.handleGenerating(preview: preview, pullInterval: pullInterval, completion: completion)
    }

    private func canUseLocalIMVideoCache(completion: @escaping (DriveProccesPreviewInfo?) -> Void) {
        DriveExternalCacheHelper.getLocalIMVideoCache(fileInfo: fileInfo) { previewInfo in
            DispatchQueue.runOnMainQueue {
                completion(previewInfo)
            }
        }
    }

    /// 生存 DriveVideo 对象
    /// - Parameters:
    ///   - shouldHasPreviewVideoInfo: 返回的 DriveVideo 是否必须包含后端转码好的视频信息
    private func getDriveVideo(preview: DriveFilePreview, shouldHasPreviewVideoInfo: Bool = true) -> DriveVideo? {
        if shouldHasPreviewVideoInfo && preview.videoInfo == nil {
            DocsLogger.info("VideoPreviewProcessor -- no videoInfo")
            return nil
        }
        // 原视频播放地址
        guard let onlineString = fileInfo.getPreviewDownloadURLString(previewType: .similarFiles) else {
            DocsLogger.error("VideoPreviewProcessor -- sessionPreviewDownloadURLString is nil!")
            return nil
        }
        guard let onlineURL = URL(string: onlineString) else {
            spaceAssertionFailure("VideoPreviewProcessor -- failed to convert video online url")
            return nil
        }

        let video = DriveVideo(type: .online(url: onlineURL),
                               info: preview.videoInfo,
                               title: fileInfo.name,
                               size: fileInfo.size,
                               cacheKey: fileInfo.videoCacheKey,
                               authExtra: config.authExtra)
        return video
    }

    private func handleVideoReady(preview: DriveFilePreview) {
        if let videoInfo = getDriveVideo(preview: preview) {
            DocsLogger.driveInfo("VideoPreviewProcessor -- preview with videoInfo")
            handler?.updateState(.setupPreview(fileType: .mp4, info: .streamVideo(video: videoInfo)))

            // 如果只有一路视频，则无需缓存后端转码后的信息
            if let info = videoInfo.info,
               let urls =  info.transcodeURLs,
               urls.count > 1 {
                DocsLogger.driveInfo("VideoPreviewProcessor -- save videos info")
                saveCacheData(videoInfo.info, type: .videoInfo)
            }
        } else {
            if playOriginVideoIfCapable() {
                return
            }

            // 转码失败，下载视频原文件播放
            if fileInfo.fileType.isSupport {
                DocsLogger.warning("VideoPreviewProcessor -- handleVideoPreview to download file")
                downloadOriginOrSimilarIfNeed()
            } else {
                DocsLogger.driveInfo("VideoPreviewProcessor -- unsupport video")
                handler?.updateState(.unsupport(type: .typeUnsupport))
            }
        }
    }

    /// 是否使用原视频播放（小视频下载原视频播放/大视频低码率在线播放）
    /// - Returns: 是否能够执行成功
    private func  playOriginVideoIfCapable() -> Bool {
        guard UserScopeNoChangeFG.ZYP.transcodingVideoPlayOriginEnable else {
            return false
        }

        guard fileInfo.fileType.isSupport else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- video file type is not supported to downgrade: \(fileInfo.fileType)")
            return false
        }

        if isSmallVideo() {
            // 转码中的小视频(<20M)直接下载播放
            DocsLogger.driveInfo("VideoPreviewProcessor -- preview get success generating can downgrade start download orgin file, size: \(fileInfo.size), settingsSize: \(DriveFeatureGate.downloadVideoSizeWhenTranscoding)")
            downloadOriginOrSimilarIfNeed()
            return true
        }

        // 大视频判断码率和编码格式是否可以在线播放
        let filePreview = fileInfo.previewMetas[.videoMeta]
        guard let filePreview = filePreview,
              isCompatibleVideo(preview: filePreview) else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- video not suitable for origin online palying: \(String(describing: filePreview))")
            return false
        }

        guard let driveVideo = getDriveVideo(preview: filePreview, shouldHasPreviewVideoInfo: false) else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- no DriveVideo: \(String(describing: filePreview))")
            return false
        }

        DocsLogger.driveInfo("VideoPreviewProcessor -- origin online palying: \(String(describing: filePreview)), " +
                             "compare bitrate: \(DriveFeatureGate.littleBitRate)")

        handler?.updateState(.endTranscoding(status: filePreview.previewStatus))
        handler?.updateState(.setupPreview(fileType: fileInfo.fileType, info: .streamVideo(video: driveVideo)))

        return true
    }

    private func isSmallVideo() -> Bool {
        // 目前配置 20M
        let size = DriveFeatureGate.downloadVideoSizeWhenTranscoding
        if fileInfo.size <= size {
            return true
        }
        return false
    }

    /// 判断码率和编码格式是否支持线播放
    private func isCompatibleVideo(preview: DriveFilePreview) -> Bool {
        DocsLogger.driveInfo("VideoPreviewProcessor -- check if origin online palying is supported: \(String(describing: preview))")
        if UserScopeNoChangeFG.CWJ.dropOriginVideoPreviewLimitation {
            DocsLogger.driveInfo("VideoPreviewProcessor -- no need to check video meta")
            return true
        }

        guard let meta = preview.mediaMeta?.streams.filter({ $0.codecType == "video" }).first else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- can not get video meta")
            return false
        }

        let supportTypes = DriveFeatureGate.suppportSourcePreviewTypes
        guard supportTypes.contains(meta.codecName) else {
            DocsLogger.error("VideoPreviewProcessor -- not compatibleVideo for codec: \(meta.codecName)")
            return false
        }
        guard let bitRate = Int(meta.bitRate),
              bitRate <= DriveFeatureGate.littleBitRate else {
            DocsLogger.error("VideoPreviewProcessor -- not compatibleVideo for bitRate: \(meta.bitRate) > \(DriveFeatureGate.littleBitRate)")
            return false
        }
        return true
    }
}

extension VideoPreviewProcessor {
    private func playCachedVideoIfCapable(previewStatus: DriveFilePreview.PreviewStatus) -> Bool {
        guard UserScopeNoChangeFG.CWJ.enableUserDownloadVideoDuringTranscoding else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- playCachedVideoIfCapable, disabled")
            return false
        }
        guard let previewInfo =  previewInfoFromCache() else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- playCachedVideoIfCapable, no cached video to playback")
            return false
        }

        DocsLogger.driveInfo("VideoPreviewProcessor -- use cached video to playback: \(previewInfo)")
        handler?.updateState(.endTranscoding(status: previewStatus))
        handler?.updateState(.setupPreview(fileType: fileInfo.fileType, info: previewInfo))
        return true
    }

    private func previewInfoFromCache() -> DriveProccesPreviewInfo? {
        guard fileInfo.fileType.isVideoPlayerSupport else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- previewInfoFromCache, " +
                                 "file type is not supported to play locally \(fileInfo.fileType)")
            return nil
        }
        guard fileInfo.size > 0 && fileInfo.size <= fileInfo.fileType.fileSizeLimits else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- previewInfoFromCache, file size is not supported: \(fileInfo.size)")
            return nil
        }

        let cacheType: DriveCacheType = config.canDownloadOrigin ? .similar : .preview
        let cacheNode = try? cacheService.getFile(type: cacheType,
                                                  fileExtension: fileInfo.fileExtension,
                                                  dataVersion: fileInfo.dataVersion).get()
        guard let cacheNode = cacheNode else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- previewInfoFromCache, file cache node not found")
            return nil
        }
        guard let fileURL = cacheNode.fileURL else {
            DocsLogger.driveInfo("VideoPreviewProcessor -- previewInfoFromCache, cache node file path not set")
            return nil
        }

        let videoInfo = DriveVideo(type: .local(url: fileURL),
                                   info: nil,
                                   title: fileInfo.name,
                                   size: fileInfo.size,
                                   cacheKey: fileInfo.videoCacheKey, authExtra: config.authExtra)
        let previewInfo: DriveProccesPreviewInfo = .localMedia(url: fileURL, video: videoInfo)
        return previewInfo
    }
}
