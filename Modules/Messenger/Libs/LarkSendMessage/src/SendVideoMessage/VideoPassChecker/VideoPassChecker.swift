//
//  VideoPassChecker.swift
//  LarkSendMessage
//
//  Created by 李晨 on 2022/11/29.
//

import UIKit
import Foundation
import ThreadSafeDataStructure // SafeArray
import LKCommonsTracker // Tracker
import LKCommonsLogging // Logger
import TTVideoEditor // VEVideoInterleaveChecker
import RxSwift // DisposeBag
import LarkSDKInterface // UserGeneralSettings
import LarkContainer // InjectedLazy
import LarkFoundation // Utils
import LarkCache // Cache
import LarkStorage // IsoPath
import LarkAccountInterface
import LarkDebug // appCanDebug

private typealias Path = LarkSDKInterface.PathWrapper

/// 视频是否可以透传检测组件
/// https://bytedance.feishu.cn/wiki/wikcnrHbR2t386SKdwNWIhDUQcf
/// https://bytedance.feishu.cn/docx/PLchdNCvwoFVytxRYwfcIkzWnqe

enum VideoPassError: Error {
    case noNeedPassthrough                  // 已经有转码产物
    case videoParseInfoError                // 视频信息存在问题 视频不存在等
    case fileSizeLimit(UInt64)              // 文件大小限制
    case videoBitrateLimit(CGFloat)         // 文件码率限制
    case videoSizeLimit(CGFloat, CGFloat)   // 文件分辨率限制
    case videoHDRLimit                      // 视频是 HDR 被限制，需要不是 HDR
    case videoEncodeLimit                   // 编码判断限制，需要为 H264
    case remuxLimit                         // 转封装判断限制
    case interleaveLimit(NSInteger)         // 视频交织判断限制
    case canntPassResult                    // 缓存中的结果
    case createIESMMTranscoderParamError    // 创建 IESMMTranscoderParam 失败
}

class VideoPassCheckerResult: NSObject, NSCoding {

    enum ResultEnum {
        case success
        case failed(error: VideoPassError)
    }

    // 非原图结果
    var enable: ResultEnum = ResultEnum.success
    // 原图结果
    var originEnable: ResultEnum = ResultEnum.success

    override init() {
        super.init()
    }

    func encode(with coder: NSCoder) {
        if case .success = self.enable {
            coder.encodeCInt(1, forKey: "enable")
        } else {
            coder.encodeCInt(0, forKey: "enable")
        }
        if case .success = self.originEnable {
            coder.encodeCInt(1, forKey: "origin")
        } else {
            coder.encodeCInt(0, forKey: "origin")
        }
    }

    required init?(coder: NSCoder) {
        let enableValue = coder.decodeCInt(forKey: "enable")
        let originValue = coder.decodeCInt(forKey: "origin")
        self.enable = enableValue == 1 ? .success : .failed(error: VideoPassError.canntPassResult)
        self.originEnable = originValue == 1 ? .success : .failed(error: VideoPassError.canntPassResult)
        super.init()
    }

    var resultValue: Int {
        switch (self.enable, self.originEnable) {
        case (.success, .success):
            return 4
        case (.success, .failed):
            return 2
        case (.failed, .success):
            return 3
        case (.failed, .failed):
            return 1
        }
    }

    override var description: String {
        var description = "result "
        switch self.enable {
        case .success:
            description += "normal success "
        case .failed(error: let error):
            description += "normal failed \(error) "
        }
        switch self.originEnable {
        case .success:
            description += "origin success "
        case .failed(error: let error):
            description += "origin failed \(error) "
        }
        return description
    }

    override var debugDescription: String {
        return self.description
    }
}

final class VideoPassChecker {
    let userResolver: UserResolver

    static let logger = Logger.log(VideoPassChecker.self, category: "LarkMessageCore.Chat.Video")

    private var userGeneralSettings: UserGeneralSettings

    let cache: Cache

    var tasks: SafeArray<(VideoPassCheckerTask, () -> Void)> = [] + .readWriteLock

    var currrentTask: SafeAtomic<(VideoPassCheckerTask, () -> Void)?> = nil + .readWriteLock

    var disposeBag = DisposeBag()

    lazy var abEnable: Bool = {
        // alpha beta 版本默认开启 ab
        if appCanDebug() {
            return true
        }
        if let messengerVideoPassthrough = Tracker.experimentValue(key: "messenger_video_passthrough", shouldExposure: true) as? Int,
            messengerVideoPassthrough == 1 {
            return true
        }
        return false
    }()

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.userGeneralSettings = try userResolver.resolve(assert: UserGeneralSettings.self)
        self.cache = VideoPassCache(userID: userResolver.userID)
    }

    /// 检测是否可以透传
    func checkVideoCanPassthrough(videoInfo: VideoParseInfo, callback: @escaping () -> Void) {
        guard self.enable() else {
            callback()
            return
        }
        let key = Self.cacheKey(info: videoInfo)
        // 如果本地有缓存 也直接跳过
        if self.cache.containsObject(forKey: key) {
            callback()
            return
        }

        let rawConfig = userGeneralSettings.videoPreprocessConfig.value.raw

        // 添加任务
        let task = VideoPassCheckerTask(
            userResolver: userResolver,
            videoInfo: videoInfo,
            userGeneralSettings: self.userGeneralSettings
        )
        Self.logger.info("append video pass task \(task.key)")
        self.tasks.append((task, callback))

        // 删除多余任务
        if self.tasks.count > rawConfig.tps {
            Self.logger.info("remove task")
            self.tasks.remove(at: 0)
        }
        self.checkNextTask()
    }

    /// 从缓存结果中查询是否可以透传
    func videoCanPassthrough(videoInfo: VideoParseInfo, isOriginal: Bool) -> Bool {
        guard self.enable() else {
            return false
        }
        let key = Self.cacheKey(info: videoInfo)
        if let cacheObject: NSCoding = self.cache.object(forKey: key),
            let result = cacheObject as? VideoPassCheckerResult {
            Self.logger.info("get video pass task key \(key) isOriginal \(isOriginal) result \(result)")
            if isOriginal {
                if case .success = result.originEnable {
                    return true
                }
                return false
            } else {
                if case .success = result.enable {
                    return true
                }
                return false
            }
        }
        return false
    }

    // 取消所有检测透传任务
    func cancelAllTasks() {
        SendVideoLogger.info("cancel all pass check tasks", .lifeCycle, pid: "", cid: "",
                             params: ["count": "\(tasks.count)",
                                      "keys": "\(tasks.map({ $0.0.key }))"])
        self.tasks.removeAll()
        self.disposeBag = DisposeBag()
        self.currrentTask.value = nil
    }

    private func checkNextTask() {
        guard self.currrentTask.value == nil &&
            !self.tasks.isEmpty else {
            return
        }

        // 检测 CPU
        let rawConfig = userGeneralSettings.videoPreprocessConfig.value.raw
        let averageCPUUsage = (try? Utils.averageCPUUsage) ?? 100
        guard rawConfig.cpuUsageLimit > averageCPUUsage else {
            Self.logger.info("video pass check cpu limit remove all task \(self.tasks.count)")
            self.tasks.removeAll()
            return
        }

        let current = self.tasks.remove(at: 0)
        let key = current.0.key

        // 每次执行任务前 再次检查 cache
        // 如果缓存已经存在 则跳过本次任务
        if self.cache.containsObject(forKey: key) {
            Self.logger.info("video pass check task \(key) had cached")
            self.checkNextTask()
            return
        }

        self.currrentTask.value = current
        Self.logger.info("start video pass check task \(key)")
        var startTime = Date().timeIntervalSince1970
        current.0.start().subscribe(onNext: { [weak self] (result) in
            let _: String? = self?.cache.setObject(result, forKey: key)
            var params: [AnyHashable: Any] = [
                "cpuUsage": averageCPUUsage,
                "duration": (Date().timeIntervalSince1970 - startTime) * 1000,
                "result": result.resultValue
            ]
            Tracker.post(TeaEvent(
                "video_predicte_check_raw_dev",
                params: params
            ))
            Self.logger.info("video pass check task \(key) result \(result) params \(params)")
        }, onDisposed: { [weak self] in
            Self.logger.info("video pass check task \(key) dispose")
            self?.currrentTask.value?.1()
            self?.currrentTask.value = nil
            self?.checkNextTask()
        }).disposed(by: self.disposeBag)
    }

    private func enable() -> Bool {
        guard self.abEnable else {
            return false
        }
        let rawConfig = userGeneralSettings.videoPreprocessConfig.value.raw
        return rawConfig.enable
    }

    static func cacheKey(info: VideoParseInfo) -> String {
        if !info.assetUUID.isEmpty {
            return info.assetUUID
        } else {
            return info.exportPath.md5()
        }
    }
}

class VideoPassCheckerTask: NSObject, VEVideoInterleaveCheckerDelegate {
    let userResolver: UserResolver
    static let logger = Logger.log(VideoPassCheckerTask.self, category: "LarkMessageCore.Chat.Video")

    var key: String
    var videoInfo: VideoParseInfo
    var userGeneralSettings: UserGeneralSettings
    var interleaveChecker: VEVideoInterleaveChecker
    var interleaveObserver: AnyObserver<VideoPassCheckerResult>?

    var result = VideoPassCheckerResult()

    init(userResolver: UserResolver, videoInfo: VideoParseInfo, userGeneralSettings: UserGeneralSettings) {
        self.userResolver = userResolver
        let rawConfig = userGeneralSettings.videoPreprocessConfig.value.raw
        let key = VideoPassChecker.cacheKey(info: videoInfo)
        self.key = key
        self.videoInfo = videoInfo
        self.userGeneralSettings = userGeneralSettings

        // VEVideoInterleaveChecker在模拟器不生效，不会有delegate回调
        self.interleaveChecker = VEVideoInterleaveChecker(
            filePath: videoInfo.exportPath,
            abnormalInterleaveInterval: rawConfig.diffMax
        )
        super.init()
        self.interleaveChecker.setDelegate(self)
    }

    func start() -> Observable<VideoPassCheckerResult> {
        return self.checkFileInfo(result: self.result)
            .flatMap({ [weak self] (result) -> Observable<VideoPassCheckerResult> in
                guard let self = self else {
                    return .just(result)
                }
                if case .failed = result.enable,
                   case .failed = result.originEnable {
                    return .just(result)
                } else {
                    return self.checkVideoRemuxEnable(result: result)
                }
            }).flatMap({ [weak self] (result) -> Observable<VideoPassCheckerResult> in
                guard let self = self else {
                    return .just(result)
                }
                if case .failed = result.enable,
                   case .failed = result.originEnable {
                    return .just(result)
                } else {
                    return self.checkVideoInterleaveEnable(result: result)
                }
            })
    }

    /// 检测文件属性是否符合预期
    func checkFileInfo(result: VideoPassCheckerResult) -> Observable<VideoPassCheckerResult> {
        return Observable.create { [weak self] observer in
            Self.logger.info("video pass check start checkFileInfo")
            guard let self = self else {
                return Disposables.create()
            }
            // 检查是否已经存在转码结果, 如果已经存在 则不需要检测
            let compressPath = self.videoInfo.compressPath
            if Path(compressPath).exists {
                result.enable = .failed(error: VideoPassError.noNeedPassthrough)
                result.originEnable = .failed(error: VideoPassError.noNeedPassthrough)
                observer.onNext(result)
                observer.onCompleted()
                return Disposables.create()
            }

            // 检查 VideoParseInfo 状态以及文件是否存在
            let exportPath = self.videoInfo.exportPath
            if !Path(exportPath).exists {
                result.enable = .failed(error: VideoPassError.videoParseInfoError)
                result.originEnable = .failed(error: VideoPassError.videoParseInfoError)
                observer.onNext(result)
                observer.onCompleted()
                return Disposables.create()
            }
            let avasset = AVURLAsset(url: URL(fileURLWithPath: exportPath), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
            let rawConfig = self.userGeneralSettings.videoPreprocessConfig.value.raw
            let videoParseInfo = self.videoInfo

            // 检查文件大小、分辨率、码率、HDR、H264
            var checkResult = { (isOriginal: Bool) -> VideoPassCheckerResult.ResultEnum in
                let rawSceneLimit = isOriginal ? rawConfig.originLimit : rawConfig.commonLimit
                if videoParseInfo.filesize > rawSceneLimit.fileSize {
                    return .failed(error: VideoPassError.fileSizeLimit(videoParseInfo.filesize))
                }

                if let videoInfo = VideoTranscoder.videoInfo(avasset: avasset) {
                    if videoInfo.1 > rawSceneLimit.videoBitrate {
                        return .failed(error: VideoPassError.videoBitrateLimit(videoInfo.1))
                    }

                    if videoInfo.2.width * videoInfo.2.height > rawSceneLimit.videoWidth * rawSceneLimit.videoHeight {
                        return .failed(error: VideoPassError.videoSizeLimit(videoInfo.2.width, videoInfo.2.height))
                    }
                }

                let isHDRVideo = Utils.isSimulator ? false : VEHDRDetectionUtils.isHDRVideo(avasset)
                if isHDRVideo {
                    return .failed(error: VideoPassError.videoHDRLimit)
                }

                let isH264Video = Utils.isSimulator ? true : IESMMMpeg.isH264Video(avasset)
                if !isH264Video {
                    return .failed(error: VideoPassError.videoEncodeLimit)
                }
                return .success
            }
            if case .success = result.enable {
                result.enable = checkResult(false)
            }

            if case .success = result.originEnable {
                result.originEnable = checkResult(true)
            }
            observer.onNext(result)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    /// 检测是否是否可以转封装
    func checkVideoRemuxEnable(result: VideoPassCheckerResult) -> Observable<VideoPassCheckerResult> {
        return Observable.create { [weak self] observer in
            Self.logger.info("video pass check start checkVideoRemuxEnable")
            guard let self = self else {
                return Disposables.create()
            }
            let transcodeConfigFactory = VideoTranscodeConfigFactory(
                videoSetting: self.userGeneralSettings.videoSynthesisSetting
            )
            // 检查 VideoParseInfo 状态以及文件是否存在
            let exportPath = self.videoInfo.exportPath
            let avasset = AVURLAsset(url: URL(fileURLWithPath: exportPath), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

            var checkResult = { (isOriginal: Bool) -> VideoPassCheckerResult.ResultEnum in
                if let videoData = HTSVideoData() {
                    videoData.videoAssets.add(avasset)
                    videoData.useAVAssetReader = true
                    var strategy = VideoTranscodeStrategy()
                    strategy.isOriginal = isOriginal
                    let transcodeConfig = transcodeConfigFactory.config(strategy: strategy, avasset: avasset).videoTranscodeConfig
                    guard let params = VideoTranscodeStrategyImpl.adjustTranscoderParam(
                        avasset: avasset,
                        transcodeConfig: transcodeConfig,
                        config: self.userGeneralSettings.videoSynthesisSetting.value
                    ) else {
                        return .failed(error: VideoPassError.createIESMMTranscoderParamError)
                    }
                    videoData.transParam = params
                    let config = IESMMTransProcessData()
                    let process = VEEffectProcess.effectProcess(with: videoData)
                    // VECompileTaskManagerSession.isPreUploadable在模拟器稳定为false
                    let canPreUpload = VECompileTaskManagerSession.sharedInstance().isPreUploadable(videoData, transConfig: config, videoProcess: process)
                    if canPreUpload {
                        return .success
                    } else {
                        return .failed(error: VideoPassError.remuxLimit)
                    }
                } else {
                    return .success
                }
            }

            if case .success = result.enable {
                result.enable = checkResult(false)
            }

            if case .success = result.originEnable {
                result.originEnable = checkResult(true)
            }
            observer.onNext(result)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    /// 检测视频是否有交织
    func checkVideoInterleaveEnable(result: VideoPassCheckerResult) -> Observable<VideoPassCheckerResult> {
        return Observable.create { [weak self] observer in
            Self.logger.info("video pass check start checkVideoInterleaveEnable")
            self?.interleaveObserver = observer
            self?.interleaveChecker.start()
            return Disposables.create { [weak self] in
                self?.interleaveObserver = nil
                self?.interleaveChecker.stop()
            }
        }
    }

    /// VEVideoInterleaveCheckerDelegate
    func checker(_ checker: VEVideoInterleaveChecker, onRecCheck event: VEVideoInterleaveCheckerEvent) {
        guard self.interleaveObserver != nil else {
            return
        }
        Self.logger.info("video pass check status \(event.status) pos \(event.pos) isAbnormalInterleaved \(event.isAbnormalInterleaved)")
        if event.isAbnormalInterleaved ||
          event.status == VEVideoInterleaveCheckerStatusFailed {
            if case .success = self.result.enable {
                self.result.enable = .failed(error: .interleaveLimit(event.pos))
            }
            if case .success = self.result.originEnable {
                self.result.originEnable = .failed(error: .interleaveLimit(event.pos))
            }
            let interleaveObserver = self.interleaveObserver
            self.interleaveObserver = nil
            interleaveObserver?.onNext(self.result)
            interleaveObserver?.onCompleted()
            DispatchQueue.main.async {
                checker.stop()
            }
        } else if event.status == VEVideoInterleaveCheckerStatusStopped {
            self.interleaveObserver?.onNext(self.result)
            self.interleaveObserver?.onCompleted()
            self.interleaveObserver = nil
        }
    }
}

// MARK: VideoPassCache

private let VideoPassDomain = Domain.biz.messenger.child("VideoPass")
public func VideoPassRootPath(userID: String) -> IsoPath {
    return .in(space: .user(id: userID), domain: VideoPassDomain).build(.cache)
}

private func VideoPassCache(userID: String) -> Cache {
    return CacheManager.shared.cache(
        rootPath: VideoPassRootPath(userID: userID),
        cleanIdentifier: "library/Caches/messenger/user_id/videoPass"
    )
}
