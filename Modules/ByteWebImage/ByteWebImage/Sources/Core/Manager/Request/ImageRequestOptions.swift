//
//  ImageRequestOptions.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/10/12.
//

import Foundation

// MARK: - Option

/// 图片请求选项
///
/// ## Topics
///
/// ### 下载相关选项
///
/// - ``priority(_:)``
/// - ``progressiveDownload``
/// - ``animatedImageProgressiveDownload``
/// - ``notVerifyData``
/// - ``ignoreCDNDowngrade``
/// - ``timeout(_:)``
/// - ``downloader(_:)``
///
/// ### 缓存相关选项
///
/// - ``ignoreCache(_:)``
/// - ``onlyQueryCache``
/// - ``notCache(_:)``
/// - ``needCachePath``
/// - ``fuzzy``
/// - ``cache(_:)``
///
/// ### 解码相关选项
///
/// - ``ignoreImage``
/// - ``notDecodeForDisplay``
/// - ``notDownsample``
/// - ``downsampleSize(_:)``
/// - ``enableAnimatedDownsample``
/// - ``smartCorp``
///
/// ### 转换器相关选项
///
/// - ``transformer(_:)``
///
/// ### 设置图片相关选项
///
/// - ``disableAutoSetImage``
/// - ``setPlaceholderUntilFailure``
/// - ``disableAutoRetryOnFailure``
/// - ``animation(_:)``
public enum ImageRequestOption: Hashable {

    // MARK: 下载相关选项

    /// 任务优先级(默认: 标准)
    ///
    /// 在下载等待队列中的任务，会以优先级排序
    case priority(ImageRequest.TaskPriority)

    /// 使用渐进式下载
    case progressiveDownload

    /// 动图使用渐进式下载
    case animatedImageProgressiveDownload

    /// 下载后不校验Data长度、格式
    case notVerifyData

    /// 忽略图片服务降级策略
    case ignoreCDNDowngrade

    /// 超时时长
    case timeout(_ interval: TimeInterval)

    /// 下载器标识
    case downloader(_ identifier: String?)

    // MARK: 缓存相关选项

    /// 忽略查询缓存(内存/磁盘)
    case ignoreCache(ImageCacheOptions)
    
    /// 仅查询缓存，不请求网络
    case onlyQueryCache
    
    /// 下载后不进行缓存(内存/磁盘)
    case notCache(ImageCacheOptions)

    /// 获取磁盘缓存路径
    case needCachePath

    /// 模糊查询
    /// 允许使用较高质量的图片替代使用
    case fuzzy

    /// 缓存标识
    case cache(_ identifier: String?)

    // MARK: 解码相关选项

    /// 忽略图片，不解码并且不返回图片
    case ignoreImage

    /// 关闭预解码
    case notDecodeForDisplay

    /// 关闭降采样
    case notDownsample

    /// 降采样大小(单位pt)
    case downsampleSize(CGSize)

    /// 启用动图降采样
    /// - Experiment: 实验中，还在调研稳定性和性能
    case enableAnimatedDownsample

    /// 使用智能裁剪
    /// 需要服务端支持，在的 header 中返回智能裁剪的区域
    case smartCorp

    // MARK: 转换器相关选项

    /// 转换器
    case transformer(ProcessableWrapper?)

    // MARK: 设置图片相关选项

    /// 下载完成后不自动设置图片
    case disableAutoSetImage

    /// 失败时才设置占位图
    case setPlaceholderUntilFailure

    /// 禁用下载失败自动重试
    case disableAutoRetryOnFailure

    /// 图片设置动效
    case animation(ImageRequest.AnimationType)

    // MARK: - Deprecated

    /// 对动图提前解码并缓存所有帧，支持 UIImageView 播放动图
    @available(*, deprecated, message: "not supported anymore")
    case preloadAllFrames

    /// 使用非ByteImageView加载动图默认会preload所有帧，onlyLoadFirstFrame会覆盖preloadAllFrames
    /// 对于ByteWebImage一直是懒加载后续帧，设置非自动播放就够了
    @available(*, deprecated, message: "not supported anymore")
    case onlyLoadFirstFrame
}

// MARK: - Options

public struct ImageRequestOptions: ExpressibleByArrayLiteral {

    public typealias Element = ImageRequestOption

    public static var `default`: Self { [] }

    var elements: [Element]

    public init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
}

extension ImageRequestOptions {

    public mutating func append(_ options: Self) {
        append(options.elements)
    }

    public mutating func append(_ options: Element...) {
        append(options)
    }

    public mutating func append(_ options: [Element]) {
        elements.append(contentsOf: options)
    }

    public func appending(_ options: Self) -> Self {
        appending(options.elements)
    }

    public func appending(_ options: Element...) -> Self {
        appending(options)
    }

    public func appending(_ options: [Element]) -> Self {
        var obj = self
        obj.append(options)
        return obj
    }

    func parse() -> ImageRequestParams {
        ImageRequestParams(self.elements)
    }
}
