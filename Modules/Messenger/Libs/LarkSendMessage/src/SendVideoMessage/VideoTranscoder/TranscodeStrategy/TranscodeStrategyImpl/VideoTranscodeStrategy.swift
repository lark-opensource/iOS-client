//
//  VideoTranscodeStrategy.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2021/11/18.
//

import UIKit
import Foundation
import RxSwift // DisposeBag
import RxCocoa // BehaviorRelay
import TTVideoEditor // VECompileTaskManagerSession
import LarkSDKInterface // VideoSynthesisSetting
import LarkFoundation // Utils
import LarkDebug // appCanDebug
import ThreadSafeDataStructure // SafeAtomic
import LarkPerf // DeviceExtension
import LarkVideoDirector // VideoEditorManager
import LarkSetting
import LarkContainer

private typealias Path = LarkSDKInterface.PathWrapper

public enum Status {
    case start
    case finish(info: VideoTrackInfo)
}

public typealias TranscodeInfo = (key: String, status: Status)
/// progress (0 ~ 1)
public typealias ProgressHandler = (_ progress: Double) -> Void
public typealias VideoDataCBHandler = (_ data: Data, _ offset: Int64, _ size: Int32, _ isFinish: Bool) -> Void

public struct VideoTranscodeStrategy {
    public var isOriginal: Bool = false // 是否是原图发送
    public var isWeakNetwork: Bool = false // 是否是弱网发送
    public var isForceReencode: Bool = false // 是否是强制转码
    public var isPassthrough: Bool = false // 是否是透传视频

    public init() {}
}

public struct VideoTranscodeWrapError: Error, CustomDebugStringConvertible, CustomStringConvertible {
    public var error: Error
    public var trackInfo: VideoTrackInfo?
    public init(error: Error, trackInfo: VideoTrackInfo?) {
        self.error = error
        self.trackInfo = trackInfo
    }

    public var debugDescription: String {
        return self.description
    }

    public var description: String {
        return "\(error)"
    }
}

// 新版对接 VE 透传配置方案转码  https://bytedance.feishu.cn/docs/doccnhpxogaMJvBFO70frfp2SQc
final class VideoTranscodeStrategyImpl: TranscodeStrategy, UserResolverWrapper {
    let userResolver: UserResolver

    private let videoSettingRelay: BehaviorRelay<VideoSynthesisSetting>

    private let transcodeConfigFactory: VideoTranscodeConfigFactory
    // 低端机是否支持边压边传
    private var enableUploadWhenTranscodeOnLowDevice: Bool { userResolver.fg.staticFeatureGatingValue(with: "video_compress_upload_at_same_time") }

    private static let transcodeQueue = DispatchQueue(label: "lark.video-transcode", qos: .userInteractive)
    private var useTranscodeQueue: Bool { userResolver.fg.dynamicFeatureGatingValue(with: "core.video_transcode_queue")}

    // 当前 app 是否处于后台
    private var isInBackground: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    private var disposeBag = DisposeBag()

    private var videoSetting: VideoSynthesisSetting {
        return self.videoSettingRelay.value
    }

    // 当前正在转码的 track info
    private var currentTrackInfo: SafeAtomic<VideoTrackInfo?> = nil + .readWriteLock

    var encodeDataCB: ((Data, Int64, Int32, Bool) -> Void)? {
        didSet {
            VideoMessageSend.logger.info("set encodeDataCB \(self.encodeDataCB)")
            VECompileTaskManagerSession.sharedInstance().encodeDataCB = encodeDataCB
        }
    }

    init(userResolver: UserResolver, videoSetting: BehaviorRelay<VideoSynthesisSetting>) {
        self.userResolver = userResolver
        self.videoSettingRelay = videoSetting
        self.transcodeConfigFactory = VideoTranscodeConfigFactory(videoSetting: videoSetting)
        // 监听 app 前后台切换
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func cancelVideoTranscode() {
        VECompileTaskManagerSession.sharedInstance().cancelTranscode()
    }

    func transcode(
        key: String,
        form: String,
        to: String,
        strategy: VideoTranscodeStrategy,
        videoSize: CGSize,
        extraInfo: [String: Any],
        progressBlock: ProgressHandler?,
        dataBlock: VideoDataCBHandler?,
        retryBlock: (() -> Void)?
    ) -> Observable<TranscodeInfo> {
        // 得到源视频信息
        let avasset = AVURLAsset(url: URL(fileURLWithPath: form), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        var fileSize = VideoTranscoder.filesize(for: avasset)
        if fileSize == 0, let res = try? avasset.url.resourceValues(forKeys: [.fileSizeKey]), let size = res.fileSize {
            fileSize = Float64(size)
        }
        let isH264Video = Utils.isSimulator ? true : IESMMMpeg.isH264Video(avasset)
        let isH265Video = Utils.isSimulator ? false : IESMMMpeg.isByteVC1Video(avasset)
        let isHDRVideo = Utils.isSimulator ? false : VEHDRDetectionUtils.isHDRVideo(avasset)

        // 原文件信息填充到埋点信息上
        var trackInfo = VideoTrackInfo()
        if isH264Video {
            trackInfo.origin.encodeType = "H264"
        } else if isH265Video {
            trackInfo.origin.encodeType = "H265"
        }
        trackInfo.isHDR = isHDRVideo
        trackInfo.isOriginal = strategy.isOriginal
        // isWeakNetwork：是否使用弱网配置，原图不使用弱网配置；isWeakNetwork不是"当前是否是弱网"的意思
        trackInfo.isWeakNetwork = strategy.isOriginal ? false : strategy.isWeakNetwork
        if let videoInfo = VideoTranscoder.videoInfo(avasset: avasset) {
            // 从Data层面获取视频格式，不从文件后缀名判断
            func fileFormat() -> String {
                let inputStream = Path(form).inputStream()
                inputStream?.open()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 2048)

                defer {
                    buffer.deallocate()
                    inputStream?.close()
                }

                // 异常情况按照unknown处理
                guard let read = inputStream?.read(buffer, maxLength: 2048), read > 0 else {
                    return "unknown"
                }
                var data = Data()
                data.append(buffer, count: read)
                // 判断格式
                switch data.lf.fileFormat() {
                // 只处理视频格式
                case .video(let format): return format.rawValue
                // 其他格式一律按照unknown处理
                default: return "unknown"
                }
            }
            trackInfo.origin.type = fileFormat()
            trackInfo.origin.rate = videoInfo.0
            trackInfo.origin.bitrate = Int32(videoInfo.1)
            // 不能用传入的videoSize参数，因为被调整过，不是原文件分辨率
            trackInfo.origin.videoSize = videoInfo.2
            trackInfo.origin.fileSize = fileSize
            trackInfo.duration = ceil(Double(avasset.duration.value) / Double(avasset.duration.timescale))
        }

        // 因为每次发视频（即使是相同的视频）时都会用UUID()生成路径，如果目标路径文件存在，则肯定是重新发送视频&之前转码成功场景
        if Path(to).exists {
            trackInfo.compressType = "reuse"
            // 有缓存直接返回进度
            progressBlock?(1)
            return .just((key, .finish(info: trackInfo)))
        }

        // 后续的操作涉及到复制移动文件，在此之前检查磁盘空间是否足够
        let mediaDiskUtil = MediaDiskUtil(userResolver: userResolver)
        guard mediaDiskUtil.checkVideoCompressEnable(content: .fileURL(Path(form).url)) else {
            return .error(NSError(domain: "lark.media.diskNotEnough.error", code: -97))
        }

        // 判断是否视频透传，不进行转码/转封装处理
        if strategy.isPassthrough, Path(form).exists {
            do {
                try Path(form).copyFile(to: Path(to))
                trackInfo.isPassthrough = true
                trackInfo.compressType = "raw"
                // 有缓存直接返回进度
                progressBlock?(1)
                return .just((key, .finish(info: trackInfo)))
            } catch { error
                VideoMessageSend.logger.error("video send error: copy file failed \(error)")
            }
        }

        // 模拟器转码稳定失败，所以直接发送原视频
        if Utils.isSimulator {
            do {
                try Path(form).forceMoveFile(to: Path(to))
                trackInfo.compressType = "origin"
                return .just((key, .finish(info: trackInfo)))
            } catch let error {
                return .error(error)
            }
        }

        // 进入转封装/转码逻辑
        guard let videoData = HTSVideoData() else {
            return .error(NSError(domain: "lark.media.create.videoData.error", code: -98, userInfo: nil))
        }
        videoData.videoAssets.add(avasset)
        return Observable<TranscodeInfo>.create { [weak self] (observer) -> Disposable in
            guard let self = self else {
                VideoMessageSend.logger.error("video send error: self deinit")
                return Disposables.create()
            }
            // 标记当前正在转码的 track info
            self.currentTrackInfo.value = trackInfo
            // 记录任务开始时是否在后台
            trackInfo.isInBackground = self.isInBackground.value

            observer.onNext((key, .start))

            // 调整videoData属性
            self.adjustVideoData(avasset: avasset, videoSize: videoSize, strategy: strategy, videoData: videoData, config: self.videoSetting, trackInfo: &trackInfo)

            // 开始转封装/转码
            let transcodeBegin = NSDate().timeIntervalSince1970

            let config = IESMMTransProcessData()

            self.adjustTranscodeConfig(strategy: strategy, config: config, trackInfo: trackInfo)
            VECompileTaskManagerSession.sharedInstance().progressBlock = { progressBlock?(Double($0) / 100) }

            /// 低端机灰度支持边压边传 观测性能
            let isLowDeviceClassify = DeviceExtension.isLowDeviceClassify
            if !isLowDeviceClassify || self.enableUploadWhenTranscodeOnLowDevice,
                let dataBlock = dataBlock {
                self.encodeDataCB = { [weak self] (data, offset, size, isFinish) in
                    guard let self = self else { return }
                    dataBlock(data, offset, size, isFinish)
                }
            } else {
                self.encodeDataCB = nil
            }

            let param: IESMMTranscoderParam = videoData.transParam
            VideoMessageSend.logger.info("""
                [send video] transcode IESMMTranscoderParam \
                frameRate \(param.frameRate); bitrate \(param.bitrate); \
                videoSize \(param.videoSize); timeoutPeriod: \(config.timeOutPeriod); AICodec \(trackInfo.param.aiCodecStatus); \
                forceReencode \(param.forceReencode); useUserBitrate \(param.useUserBitrate); \
                adjustBitrateWithResolution \(param.adjustBitrateWithResolution); \
                adjustBitrateWithEffectFilter \(param.adjustBitrateWithEffectFilter); \
                adjustBitrateWithVideoRate \(param.adjustBitrateWithVideoRate); \
                adjustBitrateAndKeyFrameIntervalWithAccelerateInfo \(param.adjustBitrateAndKeyFrameIntervalWithAccelerateInfo);
                """
            )
            self.innerTrans(videoData, config, 0, {
                retryBlock?()
            }) { [weak self] (res) in
                // 得到转封装/转码耗时
                let cost = NSDate().timeIntervalSince1970 - transcodeBegin
                trackInfo.finishIsInBackground = self?.isInBackground.value ?? false
                var result: VideoTranscodeTracker.Result = .success
                defer {
                    VideoTranscodeTracker.transcode(info: trackInfo, result: result)
                }
                // 优先处理错误
                if let error = res?.error {
                    observer.onError(VideoTranscodeWrapError(error: error, trackInfo: trackInfo))
                    result = .failed(error: error)
                    return
                }
                // 获取IES转码后的文件路径，此路径是IES内部的，我们无法外部指定
                guard let res = res, let mergeUrl = res.mergeUrl else {
                    let error = NSError(domain: "lark.media.transcode.error", code: -1, userInfo: nil)
                    observer.onError(VideoTranscodeWrapError(error: error, trackInfo: trackInfo))
                    result = .failed(error: error)
                    return
                }
                do {
                    // 清除 track info
                    self?.currentTrackInfo.value = nil
                    // 移动文件到目标路径
                    try Path(mergeUrl.path).forceMoveFile(to: Path(to))
                    // 设置打点信息：结果文件信息
                    let avasset = AVURLAsset(url: URL(fileURLWithPath: to), options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                    if let videoInfo = VideoTranscoder.videoInfo(avasset: avasset) {
                        VideoMessageSend.logger.info("get video info \(videoInfo)")
                        trackInfo.result.rate = videoInfo.0
                        trackInfo.result.bitrate = Int32(min(CGFloat(Int32.max), videoInfo.1))
                        trackInfo.result.videoSize = videoInfo.2
                    } else {
                        VideoMessageSend.logger.error("get video info failed \(avasset.tracks)")
                        // 无法获取的话 使用异步加载的方式获取信息
                        if #available(iOS 15.0, *) {
                            avasset.loadTracks(withMediaType: .video, completionHandler: { (tracks, error) in
                                if let track = tracks?.first {
                                    // 帧率
                                    let currVideoRate = CGFloat(track.nominalFrameRate)
                                    // 码率
                                    let currVideoBitrate = CGFloat(track.estimatedDataRate)
                                    // 分辨率，需要考虑旋转信息
                                    let degress = VideoTranscoder.degress(with: track.preferredTransform)
                                    let currVideoSize = VideoTranscoder.videoPreviewSize(with: track.naturalSize, degress: degress)
                                    trackInfo.result.rate = currVideoRate
                                    trackInfo.result.bitrate = Int32(min(CGFloat(Int32.max), currVideoBitrate))
                                    trackInfo.result.videoSize = currVideoSize
                                } else {
                                    VideoMessageSend.logger.error("get video info failed \(error)")
                                }
                            })
                        }
                    }
                    if let self, self.userResolver.fg.staticFeatureGatingValue(with: "im.message.send_mov_video") {
                        trackInfo.result.type = "mov" // VE 目前所有的转码产物都是 mov
                    } else {
                        trackInfo.result.type = "mp4"
                    }
                    var fileSize = VideoTranscoder.filesize(for: avasset)
                    if fileSize == 0, let res = try? avasset.url.resourceValues(forKeys: [.fileSizeKey]), let size = res.fileSize {
                        fileSize = Float64(size)
                    }
                    trackInfo.result.fileSize = fileSize
                    if res.encodeType == .byteVC1 {
                        trackInfo.result.encodeType = "H265"
                    } else if res.encodeType == .H264 {
                        trackInfo.result.encodeType = "H264"
                    }
                    trackInfo.transcodeDuration = cost * 1000
                    trackInfo.notRemuxErrorcode = res.notRemuxErrorcode
                    if res.isReendcode {
                        // 转码打点
                        trackInfo.compressType = "encode"
                    } else {
                        // 转封装打点
                        trackInfo.compressType = "muxer"
                    }
                    // 是否使用智能合成
                    trackInfo.result.useAICodec = res.lensIsRunSuccess
                    observer.onNext((key, .finish(info: trackInfo)))
                    observer.onCompleted()
                } catch let error {
                    observer.onError(VideoTranscodeWrapError(error: error, trackInfo: trackInfo))
                    result = .failed(error: error)
                }
            }
            // 不能直接cancel转码任务，怕取消了其他的转码任务，需要上层自己判断是否取消
            return Disposables.create()
        }
    }

    func innerTrans(
        _ videoData: HTSVideoData,
        _ transConfig: IESMMTransProcessData,
        _ currentTime: Int,
        _ retryBlock: @escaping () -> Void,
        _ completeBlock: @escaping (IESMMTranscodeRes?) -> Void
    ) {
        /// 切换到主线程来调用 ve 接口虽然可以提升速度,但是在 VTCompressionSessionCreate 内有一定几率卡死
        /// 尝试切换到专有高优线程
        let queue = useTranscodeQueue ? Self.transcodeQueue : DispatchQueue.main
        queue.async { [weak self] in
            VECompileTaskManagerSession.sharedInstance().trans(with: videoData, transConfig: transConfig, videoProcess: nil) { (res) in
                guard let self = self else {
                    return
                }
                // 最大重试次数
                var maxRetryTimes = 5
                /// 如果出现失败则进行重试
                /// 不处理 cancel
                if let error = res?.error as? NSError,
                   error.code != HTS_CANCELED,
                   currentTime < maxRetryTimes {
                    VideoMessageSend.logger.error("video editor failed \(error) times \(currentTime)")
                    retryBlock()
                    // 如果转码出错结束时处于后台 则等待回到前台时再进行下一次重试
                    if self.isInBackground.value {
                        self.isInBackground
                            .distinctUntilChanged()
                            .filter { $0 == false }
                            .take(1)
                            .subscribe(onNext: { [weak self] (_) in
                                VideoMessageSend.logger.error("video info transcode when enter foreground")
                                self?.innerTrans(videoData, transConfig, currentTime + 1, retryBlock, completeBlock)
                                self?.disposeBag = DisposeBag()
                            }).disposed(by: self.disposeBag)
                    } else {
                        // 第二次转码强制转码 避免一系列转封装错误
                        videoData.transParam.forceReencode = true
                        self.innerTrans(videoData, transConfig, currentTime + 1, retryBlock, completeBlock)
                    }
                } else {
                    completeBlock(res)
                }
            }
        }
    }

    @objc
    func enterBackground() {
        self.isInBackground.accept(true)
        self.currentTrackInfo.value?.isInBackground = true
    }

    @objc
    func enterForeground() {
        self.isInBackground.accept(false)
    }

    func adjustVideoSize(_ naturalSize: CGSize, strategy: VideoTranscodeStrategy) -> CGSize {
        // 根据原图/若网/低码率等场景，获取对应压缩配置
        let result = self.transcodeConfigFactory.config(strategy: strategy, avasset: nil)
        return Self.adjustVideoSize(naturalSize, transcodeConfig: result.videoTranscodeConfig)
    }

    static func adjustVideoSize(_ naturalSize: CGSize, transcodeConfig: VideoTranscodeConfig) -> CGSize {
        var resultSize = naturalSize
        // 获取宽窄边云配置
        let bigSideMax: CGFloat = CGFloat(transcodeConfig.bigSideMax)
        let smallSideMax: CGFloat = CGFloat(transcodeConfig.smallSideMax)
        // 获取当前视频宽边窄边
        let width = max(resultSize.width, resultSize.height)
        let narrow = min(resultSize.width, resultSize.height)

        // 确保宽边窄边乘积大于阈值的时候才进行压缩
        guard width * narrow > bigSideMax * smallSideMax else {
            return resultSize
        }
        // 宽边压缩率
        let widthRate = max(width / bigSideMax, 1)
        // 窄边压缩率
        let narrowRate = max(narrow / smallSideMax, 1)
        // 目标压缩率取小值
        let targetRate = min(widthRate, narrowRate)

        resultSize = CGSize(width: resultSize.width / targetRate, height: resultSize.height / targetRate)
        return resultSize
    }

    private func adjustVideoData(avasset: AVAsset, videoSize: CGSize, strategy: VideoTranscodeStrategy, videoData: HTSVideoData, config: VideoSynthesisSetting, trackInfo: inout VideoTrackInfo) {
        // 获取配置
        let result = self.transcodeConfigFactory.config(strategy: strategy, avasset: avasset)
        let transcodeConfig = result.videoTranscodeConfig
        // 构造转码参数
        guard let param = Self.adjustTranscoderParam(avasset: avasset, transcodeConfig: transcodeConfig, config: config) else {
            VideoMessageSend.logger.error("failed to create param!")
            return
        }

        // 设置打点信息：转码参数信息
        trackInfo.param.rate = param.frameRate
        trackInfo.param.bitrate = param.bitrate
        trackInfo.param.videoSize = param.videoSize
        trackInfo.compileScene = result.compileScene
        trackInfo.compileQuality = result.compileQuality

        // 开启VE侧音视频交织处理
        param.enableAVInterLeaving = true
        // 设置是否需要强制转码
        let needReencode = trackInfo.origin.fileSize > self.videoSetting.veSetting.remuxMaxFileSize
        if needReencode || transcodeConfig.isForceReencode || strategy.isForceReencode {
            param.forceReencode = true
        }

        // 设置转码参数
        videoData.transParam = param
        if !appCanDebug() {
            // 隐藏敏感参数
            videoData.compileHideSensitiveMetadata = true
        }

        // 支持后台转码的话使用 AVAssetReader
        videoData.useAVAssetReader = true

        VideoMessageSend.logger.info("param videoSize: \(videoSize), isOriginal: \(strategy.isOriginal), isWeakNetwork: \(strategy.isWeakNetwork)")
        VideoMessageSend.logger.info("IESMMParamModule.sharedInstance().editFpsLimited \(IESMMParamModule.sharedInstance().editFpsLimited)")
        VideoMessageSend.logger.info("param.remuxBitrateLimitJson \(param.remuxBitrateLimitJson)")
        VideoMessageSend.logger.info("param.bitrateSetting \(param.bitrateSetting)")
        VideoMessageSend.logger.info("origin remuxResolutionSetting; \(param.remuxResolutionLimit); remuxResolutionSetting  \(param.remuxResolutionLimit)")
    }

    private func adjustTranscodeConfig(strategy: VideoTranscodeStrategy, config: IESMMTransProcessData, trackInfo: VideoTrackInfo) {
        let result = self.transcodeConfigFactory.config(strategy: strategy, avasset: nil)
        // 超时
        if let timeoutPeriod = result.timeoutPeriod {
            config.timeOutPeriod = timeoutPeriod
        }
        // 智能合成
        let aiResult = result.aiCodec
        switch aiResult {
        case .success(let modelURL):
            config.smartCodecModel = modelURL
            config.isEnableAICodec = true
            trackInfo.param.aiCodecStatus = "success"
        case .failure(let error):
            trackInfo.param.aiCodecStatus = error.rawValue
        }
    }

    static func adjustTranscoderParam(avasset: AVAsset, transcodeConfig: VideoTranscodeConfig, config: VideoSynthesisSetting) -> IESMMTranscoderParam? {
        // 获取当前视频的帧率、码率和分辨率，如果获取不到则随便设置一个(真获取不到则不会走到此转码流程，在之前的步骤就会提示错误)
        let videoInfo = VideoTranscoder.videoInfo(avasset: avasset) ?? (30, 1_500_000, CGSize(width: 960, height: 540))

        // 得到应设的帧率 = min(最大帧率限制，视频原有帧率)
        let targetRate = min(
            CGFloat(transcodeConfig.fpsMax),
            videoInfo.0
        )
        // 得到应设的分辨率 = 参数有设置则使用参数(目前使用场景传入的参数都已调整过，无需再调整)，否则用原有分辨率(需要调整)
        let targetVideoSize = Self.adjustVideoSize(videoInfo.2, transcodeConfig: transcodeConfig)

        // 构造转码参数
        guard let param = IESMMTranscoderParam() else {
            return nil
        }
        param.frameRate = targetRate
        param.videoSize = targetVideoSize
        param.useVideoDataOutputSize = true
        // 透传码率配置
        param.bitrateSetting = transcodeConfig.bitrateSetting
        // 不使用用户设置码率，由bitrateSetting代替
        param.useUserBitrate = false
        param.useUserRemuxResolutionLimit = true
        // 设置省略二次编码码率阈值，转封装/转码目前交由VE通过阀值判断
        IESMMParamModule.sharedInstance().editFpsLimited = transcodeConfig.remuxFPSSetting
        param.remuxBitrateLimitJson = transcodeConfig.remuxBitratelimitSetting
        param.remuxResolutionLimit = transcodeConfig.remuxResolutionSetting
        return param
    }
}
