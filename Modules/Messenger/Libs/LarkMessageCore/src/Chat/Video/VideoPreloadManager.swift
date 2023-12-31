//
//  VideoPreloadManager.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2022/2/24.
//

import UIKit
import Foundation
import LarkContainer
import TTVideoEngine
import LarkModel
import LarkSetting
import LarkCache
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkAccountInterface
import LarkSDKInterface
import Reachability
import LKCommonsTracker
import LarkVideoDirector
import RustPB

private typealias Path = LarkSDKInterface.PathWrapper

struct VideoPreloadTask {
    let fileKey: String
    let url: String
    let session: String
}

public final class VideoPreloadManager {

    enum ResultType: String {
        case success
        case failed
        case cancel
    }

    static let logger = Logger.log(VideoPreloadManager.self, category: "Module.VideoPreloadManager")

    public static let shared = VideoPreloadManager()

    private var result: SafeDictionary<String, ResultType> = [:] + .readWriteLock
    private var tasks: SafeArray<VideoPreloadTask> = [] + .semaphore
    private var downloading: Bool = false
    private var downloadingTaskKey: String?

    let reach: Reachability? = {
        let reachability = Reachability()
        try? reachability?.startNotifier()
        return reachability
    }()

    public func preloadVideoIfNeeded(_ media: Moments_V1_Media, currentAccessToken: String?, userResolver: UserResolver) {
        guard let task = preoloadTask(media, currentAccessToken: currentAccessToken) else {
            return
        }
        self.preloadVideoIfNeeded(task: task, userResolver: userResolver)
    }

    public func cancelPreloadVideoIfNeeded(_ media: Moments_V1_Media, currentAccessToken: String?) {
        guard let task = preoloadTask(media, currentAccessToken: currentAccessToken) else {
            return
        }
        self.cancelPreloadVideoIfNeeded(task: task)
    }

    public func preloadVideoIfNeeded(_ video: MediaContent, currentAccessToken: String?, userResolver: UserResolver) {
        guard let task = preoloadTask(video, currentAccessToken: currentAccessToken) else {
            return
        }
        self.preloadVideoIfNeeded(task: task, userResolver: userResolver)
    }

    public func cancelPreloadVideoIfNeeded(_ video: MediaContent, currentAccessToken: String?) {
        guard let task = preoloadTask(video, currentAccessToken: currentAccessToken) else {
            return
        }
        self.cancelPreloadVideoIfNeeded(task: task)
    }

    public func preloadVideoIfNeeded(_ mediaPropertys: [Basic_V1_RichTextElement.MediaProperty], currentAccessToken: String?, userResolver: UserResolver) {
        mediaPropertys.forEach { property in
            guard let task = self.preoloadTask(property, currentAccessToken: currentAccessToken) else {
                return
            }
            self.preloadVideoIfNeeded(task: task, userResolver: userResolver)
        }
    }

    public func cancelPreloadVideoIfNeeded(_ mediaPropertys: [Basic_V1_RichTextElement.MediaProperty], currentAccessToken: String?) {
        mediaPropertys.forEach { property in
            guard let task = self.preoloadTask(property, currentAccessToken: currentAccessToken) else {
                return
            }
            self.cancelPreloadVideoIfNeeded(task: task)
        }
    }

    private func preloadVideoIfNeeded(task: VideoPreloadTask, userResolver: UserResolver) {
        guard needPreload(task, userResolver: userResolver) else {
            return
        }
        if let result = self.result[task.fileKey],
           result != .cancel {
            return
        }
        VideoPreloadManager.logger.info("add preload task \(task.fileKey)")
        self.tasks.append(task)

        var preloadDelay: TimeInterval = 0
        if let settings = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "im_video_player_config")),
          let videoConfig = settings["lark"] as? [String: Any],
           let preloadDelayConfig = videoConfig["preload_delay"] as? TimeInterval {
            preloadDelay = preloadDelayConfig
        }
        if preloadDelay == 0 {
            self.checkNextTask(userResolver: userResolver)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + preloadDelay / 1000) { [weak self] in
                self?.checkNextTask(userResolver: userResolver)
            }
        }
    }

    private func cancelPreloadVideoIfNeeded(task: VideoPreloadTask) {
        if let index = self.tasks.firstIndex(where: { preloadTask in
            return task.fileKey == preloadTask.fileKey
        }) {
            VideoPreloadManager.logger.info("cancel preload task \(task.fileKey)")
            self.tasks.remove(at: index)
        }

        if self.downloadingTaskKey == task.fileKey {
            VideoPreloadManager.logger.info("cancel preload downloading task \(task.fileKey)")
            TTVideoEngine.ls_cancelTask(byKey: task.fileKey)
            self.downloading = false
            self.downloadingTaskKey = nil
        }
    }

    public func cancelAllPreloadTask() {
        VideoPreloadManager.logger.info("cancel all preload tasks \(self.tasks.count) downloading \(self.downloading)")
        self.tasks.removeAll()
        if downloading {
            TTVideoEngine.ls_cancelAllIdlePreloadTasks()
            self.downloading = false
            self.downloadingTaskKey = nil
        }
    }

    private func needPreload(_ video: VideoPreloadTask, userResolver: UserResolver) -> Bool {
        guard let settings = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "im_video_player_config")),
          let videoConfig = settings["lark"] as? [String: Any],
          let preloadEnable = videoConfig["preload_enable"] as? Int,
            let cellularPreloadEnable = videoConfig["cellular_preload_enable"] as? Int else {
              return false
        }
        if preloadEnable == 0 { return false }
        var isWifi = false
        switch self.reach?.connection ?? .none {
        case .wifi:
            isWifi = true
        default:
            isWifi = false
        }
        if !isWifi && cellularPreloadEnable == 0 { return false }
        return true
    }

    private func replacePathHomeDirectory(with path: String?) -> String? {
        guard let path = path, !path.isEmpty else { return nil }
        return VideoCacheConfig.replaceHomeDirectory(forPath: path)
    }

    private func preoloadTask(_ video: MediaContent, currentAccessToken: String?) -> VideoPreloadTask? {
        // 原视频不支持预加载
        if video.isPCOriginVideo {
            return nil
        }
        // 本地有缓存
        if let path = replacePathHomeDirectory(with: video.filePath),
            Path(path).exists {
            return nil
        }
        guard !video.url.isEmpty,
          let key = cacheKey(for: video.url),
          let session = currentAccessToken else {
              return nil
          }
        return VideoPreloadTask(fileKey: key, url: video.url, session: session)
    }

    private func preoloadTask(_ mediaProperty: Basic_V1_RichTextElement.MediaProperty, currentAccessToken: String?) -> VideoPreloadTask? {
        // 本地沙盒中是否有该文件
        if let path = replacePathHomeDirectory(with: mediaProperty.originPath),
           Path(path).exists {
            return nil
        }
        let url: String = mediaProperty.url
        guard let key = cacheKey(for: url),
            let session = currentAccessToken else {
            return nil
        }
        return VideoPreloadTask(fileKey: key, url: url, session: session)
    }

    private func preoloadTask(_ media: Moments_V1_Media, currentAccessToken: String?) -> VideoPreloadTask? {
        // 本地沙盒中是否有该文件
        if let path = replacePathHomeDirectory(with: media.localURL),
           Path(path).exists {
            return nil
        }
        let url: String = media.driveURL
        guard let key = cacheKey(for: url),
            let session = currentAccessToken else {
            return nil
        }
        return VideoPreloadTask(fileKey: key, url: url, session: session)
    }

    private func cacheKey(for videoURL: String) -> String? {
        guard !LarkCache.isCryptoEnable() else { return nil }
        return videoURL.kf.md5
    }

    private func checkNextTask(userResolver: UserResolver) {
        if self.downloading || self.tasks.isEmpty {
            return
        }
        let first = self.tasks.remove(at: 0)
        self.downloadVideo(fileKey: first.fileKey, url: first.url, session: first.session, userResolver: userResolver)
    }

    private func downloadVideo(fileKey: String, url: String, session: String, userResolver: UserResolver) {
        var preloadSize = 500 * 1024 // 预加载视频头部大小
        var preloadFooterSize = 0   // 预加载视频尾部大小

        if let settings = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "im_video_player_config")),
           let videoConfig = settings["lark"] as? [String: Any] {
            if let preloadSizeConfig = videoConfig["preload_size"] as? NSInteger {
                preloadSize = preloadSizeConfig
            }
            if let preloadSizeConfig = videoConfig["preload_footer_size"] as? NSInteger {
                preloadFooterSize = preloadSizeConfig
            }
        }
        ///视频预加载接入 abtest
        if let abSetting = Tracker.experimentValue(key: "im_video_player_ab_config", shouldExposure: true) as? [String: Any],
           let preloadConfig = abSetting["preload"] as? [String: Any] {
            if let preloadSizeConfig = preloadConfig["preload_size"] as? NSInteger {
                preloadSize = preloadSizeConfig
            }
            if let preloadSizeConfig = preloadConfig["preload_footer_size"] as? NSInteger {
                preloadFooterSize = preloadSizeConfig
            }
        }
        Tracker.post(TeaEvent("preload_video_start_dev"))
        /// 初始化 MDL
        if LarkPlayerKit.isEnabled(userResolver: userResolver) {
            LarkPlayerKit.setupMDLAndStartIfNeeded(userResolver: userResolver)
        } else {
            /// 初始化 VideoEngineDelegate
            VideoEngineSetupManager.shared.setupVideoEngineDelegateIfNeeded()
            /// 开启预加载引擎
            if !TTVideoEngine.ls_isStarted() {
                TTVideoEngine.ls_start()
            }
        }

        if let item = TTVideoEnginePreloaderURLItem(key: fileKey, videoId: nil, urls: [url], preloadSize: preloadSize) {
            if preloadFooterSize > 0 {
                item.preloadFooterSize = preloadFooterSize
            }
            var startTime = CACurrentMediaTime()
            let nextBlock = { [weak self] (result: ResultType) in
                var cost = (CACurrentMediaTime() - startTime) * 1000
                Tracker.post(
                    TeaEvent("preload_video_finish_dev", params: [
                        "result": result.rawValue,
                        "duration": cost
                    ])
                )
                self?.downloading = false
                self?.downloadingTaskKey = nil
                self?.result[fileKey] = result
                self?.checkNextTask(userResolver: userResolver)
            }
            self.downloading = true
            self.downloadingTaskKey = fileKey
            item.setCustomHeaderValue("session=" + session, forKey: "cookie")
            item.preloadEnd = { [weak self] (_, error) in
                guard let self = self else { return }
                if let error = error {
                    VideoPreloadManager.logger.error("preload task failed \(error)")
                    nextBlock(.failed)
                } else {
                    VideoPreloadManager.logger.info("preload task end")
                    nextBlock(.success)
                }
            }
            item.preloadCanceled = {
                VideoPreloadManager.logger.info("preload task cancel")
                nextBlock(.cancel)
            }
            item.preloadDidStart = { _ in
                VideoPreloadManager.logger.info("preload task did start")
            }
            VideoPreloadManager.logger.info("preload task info size \(item.preloadSize) footer \(item.preloadFooterSize) \(item.key)")
            TTVideoEngine.ls_addTask(with: item)
        }
    }
}
