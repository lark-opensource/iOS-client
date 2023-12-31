//
//  ImageRequestParams.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/11/15.
//

import Foundation

/// 图片请求选项
internal struct ImageRequestParams: ExpressibleByArrayLiteral {

    typealias Element = ImageRequestOption

    /// 任务优先级(默认: 标准)
    private(set) var priority: ImageRequest.TaskPriority = .normal

    /// 忽略缓存位置(默认: 不忽略)
    var ignoreCache: ImageCacheOptions = .none

    /// 仅查询缓存，不请求网络(默认: 关)
    var onlyQueryCache: Bool = false

    /// 下载后不进行缓存位置(默认: 全缓存)
    var notCache: ImageCacheOptions = .none

    /// 获取磁盘缓存路径(默认: false)
    var needCachePath: Bool = false

    /// 忽略图片(默认: false)
    var ignoreImage: Bool = false

    /// 禁止下载完成后自动设置图片(默认: false)
    var disableAutoSetImage: Bool = false

    /// 失败时才设置占位图
    var setPlaceholderUntilFailure: Bool = false

    /// 使用渐进式下载(默认: false)
    var progressiveDownload: Bool = false

    /// 动图使用渐进式下载(默认: false)
    var animatedImageProgressiveDownload: Bool = false

    /// 禁用下载失败自动重试(默认: false)
    var disableAutoRetryOnFailure: Bool = false

    /// 关闭预解码(默认: false)
    var notDecodeForDisplay: Bool = false

    /// 大图自动降分辨(默认: false)
    /// 1. BDImageProgressiveDownload生效时此选项失效
    /// 2. 关闭预解码时此选项失效
    var scaleDownLargeImage: Bool = false

    /// 图片设置动效
    var animation: ImageRequest.AnimationType = .none

    /// 关闭降采样(默认: false)
    var notDownsample: Bool = false

    /// 降采样大小(单位:px, 默认: ``ImageManager/defaultDownsampleSize``)
    var downsampleSize: CGSize = ImageManager.default.defaultDownsampleSize

    /// 下载后不校验Data长度、格式(默认: false)
    var notVerifyData: Bool = false

    /// 使用智能裁剪(默认: false)
    /// 需要服务端支持，在的 header 中返回智能裁剪的区域
    var smartCorp: Bool = false

    /// 忽略图片服务降级策略(默认: false)
    var ignoreCDNDowngrade: Bool = false

    /// 对动图提前解码并缓存所有帧，支持 UIImageView 播放动图(默认: false)
    var preloadAllFrames: Bool = false

    /// 使用非ByteImageView加载动图默认会preload所有帧，onlyLoadFirstFrame会覆盖preloadAllFrames
    /// 对于ByteWebImage一直是懒加载后续帧，设置非自动播放就够了
    var onlyLoadFirstFrame: Bool = false

    /// 模糊查询
    var fuzzy: Bool = false

    /// 下载器标识
    var downloaderIdentifier: String?

    /// 超时时长(默认: 30s)
    var timeoutInterval: TimeInterval = Constants.defaultTimeoutInterval

    /// 缓存标识
    var cacheIdentifier: String?

    /// 转换器
    var transformer: ProcessableWrapper?

    /// 动图支持降采样
    var enableAnimatedDownsample: Bool = false

    init(arrayLiteral elements: Element...) {
        update(elements)
    }

    init(_ elements: [Element]) {
        update(elements)
    }

    mutating func update(_ elements: Element...) {
        update(elements)
    }

    mutating func update(_ elements: [Element]) {
        for element in elements {
            switch element {
            case .priority(let priority): self.priority = priority
            case .ignoreCache(let ignoreCache): self.ignoreCache = ignoreCache
            case .onlyQueryCache: onlyQueryCache = true
            case .notCache(let notCache): self.notCache = notCache
            case .needCachePath: self.needCachePath = true
            case .ignoreImage: self.ignoreImage = true
            case .disableAutoSetImage: self.disableAutoSetImage = true
            case .setPlaceholderUntilFailure: self.setPlaceholderUntilFailure = true
            case .progressiveDownload: self.progressiveDownload = true
            case .animatedImageProgressiveDownload: self.animatedImageProgressiveDownload = true
            case .disableAutoRetryOnFailure: self.disableAutoRetryOnFailure = true
            case .notDecodeForDisplay: self.notDecodeForDisplay = true
            case .animation(let animation): self.animation = animation
            case .notDownsample: self.notDownsample = true
            case .downsampleSize(let downsampleSize):
                let scale = UIScreen.main.scale
                self.downsampleSize = CGSize(width: downsampleSize.width * scale, height: downsampleSize.height * scale)
            case .notVerifyData: self.notVerifyData = true
            case .smartCorp: self.smartCorp = true
            case .ignoreCDNDowngrade: self.ignoreCDNDowngrade = true
            case .preloadAllFrames: self.preloadAllFrames = true
            case .onlyLoadFirstFrame: self.onlyLoadFirstFrame = true
            case .fuzzy: self.fuzzy = true
            case .downloader(let identifier): self.downloaderIdentifier = identifier
            case .timeout(let interval): self.timeoutInterval = interval
            case .cache(let identifier): self.cacheIdentifier = identifier
            case .transformer(let transformer): self.transformer = transformer
            case .enableAnimatedDownsample: self.enableAnimatedDownsample = true
            }
        }
    }
}

extension ImageRequestParams: CustomStringConvertible, CustomDebugStringConvertible {

    var description: String {
        var array: [String] = []

        if priority != .normal { array.append("priority:\(priority)") }
        if ignoreCache != .none { array.append("ignoreCache:\(ignoreCache)") }
        if onlyQueryCache { array.append("onlyQueryCache") }
        if notCache != .none { array.append("notCache:\(notCache)") }
        if needCachePath { array.append("needCachePath") }
        if ignoreImage { array.append("ignoreImage") }
        if disableAutoSetImage { array.append("disableAutoSetImage") }
        if setPlaceholderUntilFailure { array.append("setPlaceholderUntilFailure") }
        if progressiveDownload { array.append("progressiveDownload") }
        if animatedImageProgressiveDownload { array.append("animatedImageProgressiveDownload") }
        if disableAutoRetryOnFailure { array.append("disableAutoRetryOnFailure") }
        if notDecodeForDisplay { array.append("notDecodeForDisplay") }
        if animation != .none { array.append("animation:\(animation)") }
        if notDownsample { array.append("notDownsample") }
        if downsampleSize != .zero {
            array.append(String(format: "downsampleSize:(%.0f,%.0f)", downsampleSize.width, downsampleSize.height))
        }
        if notVerifyData { array.append("notVerifyData") }
        if smartCorp { array.append("smartCorp") }
        if ignoreCDNDowngrade { array.append("ignoreCDNDowngrade") }
        if preloadAllFrames { array.append("preloadAllFrames") }
        if onlyLoadFirstFrame { array.append("onlyLoadFirstFrame") }
        if fuzzy { array.append("fuzzy") }
        if let downloaderIdentifier { array.append("downloaderIdentifier:\(downloaderIdentifier)") }
        if timeoutInterval != Constants.defaultTimeoutInterval { array.append("timeoutInterval:\(timeoutInterval)") }
        if let cacheIdentifier { array.append("cacheIdentifier:\(cacheIdentifier)") }
        if let transformer { array.append("transformer:\(transformer)") }
        if enableAnimatedDownsample {
            array.append("enableAnimatedDownsample")
        }

        return array.joined(separator: "|")
    }

    var debugDescription: String {
        description
    }
}

extension ImageRequestParams: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(priority)
        hasher.combine(ignoreCache)
        hasher.combine(onlyQueryCache)
        hasher.combine(notCache)
        hasher.combine(needCachePath)
        hasher.combine(ignoreImage)
        hasher.combine(disableAutoSetImage)
        hasher.combine(progressiveDownload)
        hasher.combine(animatedImageProgressiveDownload)
        hasher.combine(disableAutoRetryOnFailure)
        hasher.combine(notDecodeForDisplay)
        hasher.combine(animation)
        hasher.combine(notDownsample)
        hasher.combine(downsampleSize)
        hasher.combine(notVerifyData)
        hasher.combine(smartCorp)
        hasher.combine(ignoreCDNDowngrade)
        hasher.combine(preloadAllFrames)
        hasher.combine(onlyLoadFirstFrame)
        hasher.combine(fuzzy)
        hasher.combine(downloaderIdentifier)
        hasher.combine(timeoutInterval)
        hasher.combine(cacheIdentifier)
        hasher.combine(transformer?.description)
        hasher.combine(enableAnimatedDownsample)
    }
}

// MARK: - Definition

public typealias ImageRequestModifier = (URLRequest) -> URLRequest

extension ImageRequest {

    /// 请求优先级
    public enum TaskPriority {

        /// 优先级 - 标准
        case normal

        /// 优先级 - 低
        case low

        /// 优先级 - 高
        case high

        /// 操作队列优先级
        public var queuePriority: Operation.QueuePriority {
            switch self {
            case .normal: return .normal
            case .low:    return .low
            case .high:   return .high
            }
        }
    }

    /// 动效类型
    public enum AnimationType {

        /// 无
        case none

        /// 渐变
        case fade
    }
}
