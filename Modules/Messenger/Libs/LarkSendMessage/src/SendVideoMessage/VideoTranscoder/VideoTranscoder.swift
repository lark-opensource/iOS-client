//
//  VideoTranscodeTool.swift
//  Action
//
//  Created by kongkaikai on 2019/6/18.
//

import UIKit
import Foundation
import RxSwift // AnyObserver
import TTVideoEditor // HTS_CANCELED
import LKCommonsLogging // Logger
import ThreadSafeDataStructure // SafeArray
import LarkVideoDirector // LVDCameraConfig
import LarkMonitor // BDPowerLogManager

/// 视频转码服务
public protocol VideoTranscodeService {
    func isTranscoding() -> Bool
    /// 转码
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
    ) -> Observable<TranscodeInfo>

    /// 取消视频转码
    func cancelVideoTranscode(key: String)

    /// 更新转码任务的 key
    func updateVideoTranscodeKey(from key: String, to newKey: String)

    /// 缩放视频尺寸，目前会根据时长区别缩放
    func adjustVideoSize(_ naturalSize: CGSize, strategy: VideoTranscodeStrategy) -> CGSize
}

private final class VideoTranscodeTask {
    var taskKey: String = UUID().uuidString
    var key: String
    var from: String
    var to: String
    var strategy: VideoTranscodeStrategy
    var videoSize: CGSize
    var progressBlock: ProgressHandler?
    var dataBlock: VideoDataCBHandler?
    var retryBlock: (() -> Void)?
    var extraInfo: [String: Any]
    var observer: AnyObserver<TranscodeInfo>

    init(
        key: String,
        from: String,
        to: String,
        strategy: VideoTranscodeStrategy,
        videoSize: CGSize,
        extraInfo: [String: Any],
        observer: AnyObserver<TranscodeInfo>,
        progressBlock: ProgressHandler?,
        dataBlock: VideoDataCBHandler?,
        retryBlock: (() -> Void)?
    ) {
        self.key = key
        self.from = from
        self.to = to
        self.strategy = strategy
        self.videoSize = videoSize
        self.extraInfo = extraInfo
        self.observer = observer
        self.progressBlock = progressBlock
        self.dataBlock = dataBlock
        self.retryBlock = retryBlock
    }

    func start(transcoder: VideoTranscoder, callback: @escaping () -> Void) {
        let key = self.key
        Self.startPowerEvent(key: key)
        transcoder.transcodeStrategy
            .transcode(
                key: key,
                form: from,
                to: to,
                strategy: strategy,
                videoSize: videoSize,
                extraInfo: extraInfo,
                progressBlock: progressBlock,
                dataBlock: dataBlock,
                retryBlock: retryBlock
            )
            .do(onDispose: {
                Self.endPowerEvent(key: key)
                callback()
            })
            .subscribe(self.observer)
    }

    static func startPowerEvent(key: String) {
        BDPowerLogManager.beginEvent("messenger_video_transcode", params: self.getPowerParams(key: key))
    }

    static func endPowerEvent(key: String) {
        BDPowerLogManager.endEvent("messenger_video_transcode", params: self.getPowerParams(key: key))
    }

    static func getPowerParams(key: String) -> [String: Any] {
        var params: [String: Any] = [:]
        params["key"] = key
        return params
    }
}

/// 视频转码
final class VideoTranscoder: VideoTranscodeService {

    static let logger = Logger.log(VideoTranscoder.self, category: "LarkMessageCore.Chat.Video,VideoTranscode")

    /// 转码策略
    let transcodeStrategy: TranscodeStrategy

    /// 转码任务队列
    private var transcoderTasks: SafeArray<VideoTranscodeTask> = [] + .semaphore

    /// 当前转码任务的key
    private var inTranskdingKey: SafeAtomic<String> = "" + .readWriteLock

    init(transcodeStrategy: TranscodeStrategy) {
        self.transcodeStrategy = transcodeStrategy
    }

    func isTranscoding() -> Bool {
        return !(self.inTranskdingKey.value).isEmpty ||
            !transcoderTasks.isEmpty
    }

    // MARK: - VideoTranscodeService
    /// 转码
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
        return Observable<TranscodeInfo>.create({ [weak self] (observer) -> Disposable in
            let task = VideoTranscodeTask(
                key: key,
                from: form,
                to: to,
                strategy: strategy,
                videoSize: videoSize,
                extraInfo: extraInfo,
                observer: observer,
                progressBlock: progressBlock,
                dataBlock: dataBlock,
                retryBlock: retryBlock
            )
            self?.transcoderTasks.append(task)
            Self.logger.info("add video trancode task to queue \(key)")
            self?.checkNextTask()
            return Disposables.create()
        })
    }

    func updateVideoTranscodeKey(from key: String, to newKey: String) {
        Self.logger.info("update video trancode task \(key) to \(newKey)")
        if let firstIndex = self.transcoderTasks.firstIndex(where: { task in
            return task.key == key
        }) {
            Self.logger.info("update task index \(firstIndex) \(key) to \(newKey)")
            self.transcoderTasks[firstIndex].key = newKey
        }
        if self.inTranskdingKey.value == key {
            Self.logger.info("update current task \(key) to \(newKey)")
            self.inTranskdingKey.value = newKey
        }
    }

    func cancelVideoTranscode(key: String) {
        Self.logger.info("cancel video trancode task \(key), current \(self.inTranskdingKey.value)")
        if let firstIndex = self.transcoderTasks.firstIndex(where: { task in
            return task.key == key
        }) {
            Self.logger.info("cancel task index \(firstIndex) \(key)")
            let task = self.transcoderTasks[firstIndex]
            self.transcoderTasks.remove(at: firstIndex)
            task.observer.onError(NSError(domain: "Video.Transcoder", code: Int(HTS_CANCELED)))
        }
        if self.inTranskdingKey.value == key {
            Self.logger.info("cancel current task \(key)")
            self.transcodeStrategy.cancelVideoTranscode()
        }
    }

    /// 缩放视频尺寸，目前会根据时长区别缩放
    func adjustVideoSize(_ naturalSize: CGSize, strategy: VideoTranscodeStrategy) -> CGSize {
        return self.transcodeStrategy.adjustVideoSize(naturalSize, strategy: strategy)
    }

    /// 检查下一个任务
    private func checkNextTask() {
        guard inTranskdingKey.value.isEmpty, !self.transcoderTasks.isEmpty else { return }
        let task = self.transcoderTasks.remove(at: 0)
        self.inTranskdingKey.value = task.key
        Self.logger.info("begin video trancode task \(task.key)")

        task.start(transcoder: self, callback: { [weak self] in
            Self.logger.info("finish video trancode task \(task.key)")
            self?.inTranskdingKey.value = ""
            self?.checkNextTask()
        })
    }

    // MARK: - 工具方法
    /// 获取视频旋转角度
    class func degress(with videoPreferredTransform: CGAffineTransform) -> Int {
        VideoTranscoder.logger.info("videoPreferredTransform: \(videoPreferredTransform)")
        var degress = 0
        let t = videoPreferredTransform
        // 修复使用前置摄像头拍摄，视频被横向拉伸的问题
        // https://bytedance.feishu.cn/docs/doccnSg9dxA9fTH5LMRhC4pK9ng#
        switch (t.a, t.b, t.c, t.d) {
        // (0, -1, -1, 0)是原图镜像后再转90度
        case (0, 1, -1, 0), (0, -1, -1, 0): degress = 90
        // (0, 1, 1, 0)是原图镜像后再转270度
        case (0, -1, 1, 0), (0, 1, 1, 0): degress = 270
        case (1, 0, 0, 1): degress = 0
        case (-1, 0, 0, -1): degress = 180
        default: degress = 0
        }
        VideoTranscoder.logger.info("degress: \(degress)")
        return degress
    }

    /// 通过旋转角度调整分辨率
    class func videoPreviewSize(with naturalSize: CGSize, degress: Int) -> CGSize {
        switch degress {
        // 如果视频旋转了90°或者270°要把长宽对调一下才是预览的size
        case 90, 270:
            return CGSize(width: naturalSize.height, height: naturalSize.width)
        default:
            return naturalSize
        }
    }

    /// 获取文件大小，单位：byte
    class func filesize(for asset: AVAsset) -> Float64 {
        var size: Float64 = 0
        for track in asset.tracks(withMediaType: .video) + asset.tracks(withMediaType: .audio) {
            let dataRate = track.estimatedDataRate
            let duration = CMTimeGetSeconds(track.timeRange.duration)
            size += Float64(dataRate) * duration / 8
        }
        if size.isNaN || size.isInfinite || size < 0 {
            return 0
        }
        return size
    }

    // 获取当前视频的帧率、码率（单位：bps）和分辨率，如AVAsset中没有视频流，则返回nil
    class func videoInfo(avasset: AVAsset) -> (CGFloat, CGFloat, CGSize)? {
        guard let track = avasset.tracks(withMediaType: .video).first else { return nil }
        // 帧率
        let currVideoRate = CGFloat(track.nominalFrameRate)
        // 码率
        let currVideoBitrate = CGFloat(track.estimatedDataRate)
        // 分辨率，需要考虑旋转信息
        let degress = VideoTranscoder.degress(with: track.preferredTransform)
        let currVideoSize = VideoTranscoder.videoPreviewSize(with: track.naturalSize, degress: degress)

        return (currVideoRate, currVideoBitrate, currVideoSize)
    }

    /// 根据分辨率、帧率和压缩倍数得到压缩后码率，单位：bps
    class func compress(size: CGSize, rate: CGFloat, scale: CGFloat) -> CGFloat {
        var compressBitrate = size.width * size.height * rate
        // yuv420p，1像素占1.5B
        compressBitrate *= 1.5
        // 单位：字节 to 位，1B = 8bit
        compressBitrate *= 8
        // 压缩指定倍数
        compressBitrate /= scale
        return compressBitrate
    }
}
