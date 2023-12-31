//
//  ImageManager.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/22.
//

import Foundation
import ThreadSafeDataStructure
import EEAtomic

public final class ImageManager {

    private init() {
        self.defaultCache = .default
    }

    /// 根据指定的业务类型初始化实例
    /// 与默认实例隔离
    /// - Parameter category: 业务类型；传空仍返回新实例，但与默认实例共享缓存
    public init(category: String) {
        if category.isEmpty {
            defaultCache = .default
        } else {
            defaultCache = ImageCache("com.bt.image.cache.\(category)")
        }
        Log.trace("Create manager with identifier \(defaultCache.identifier)")
    }

    /// 默认实例
    public static let `default` = ImageManager()

    // MARK: Cache

    /// 默认缓存
    let defaultCache: ImageCache

    /// 缓存列表
    var cacheMap: SafeDictionary<String, ImageCache> = [:] + .readWriteLock

    // MARK: Downloader

    /// 默认下载器
    @SafeLazy
    var defaultDownloader: any Downloader = { URLSessionDownloader() }()

    /// rust下载器
    var rustDownloader: (any Downloader)?

    /// 下载器列表
    var downloaderMap: SafeDictionary<String, any Downloader> = [:] + .readWriteLock

    // MARK: Request

    /// 所有请求
    /// Todo: 该内容应当考虑放到Request相关位置，而不是Manager
    var requestMap: SafeDictionary<String, SafeArray<ImageRequest>> = [:] + .readWriteLock

    /// 任务进展线程
    let progressTaskQueue = DispatchQueue(label: "com.bt.image.progress.decode")

    /// 默认降采样大小(单位px)
    /// 如果生效不会影响缓存的Key
    public var defaultDownsampleSize: CGSize = .zero

    // MARK: Parameters

    var enableMultiThreadHeicDecoder: Bool = false // heic非系统解码，暂时用不到
    public var downloaderDefaultHttpHeaders: [String: String] = [:] // 下载的请求头，针对URLSession场景生效
//    var timoutForResouce: TimeInterval = 30.0 // 默认超时时间，针对渐进式下载生效
    public var enableMemoryCache: Bool = true // 是否开启内存缓存
    var checkMimeType: Bool = true // 是否检查Mime
    var checkDataLength: Bool = true // 是否校验长度
    var maxConcurrentTaskCount: Int = 9 // 最大并发数默认设置为9
    var isPrefetchLowPriority: Bool = true // 预加载任务低优先级
    var isPrefetchIgoreDecode: Bool = true // 预加载跳过解码
    var enableImageLoadNotification: Bool = false // 图片加载同时开关，(发起请求通知1，下载成功通知2)
    var enableAllImageDownsample: Bool = false // 开启全局图片降采样
    var isConcurrentCallback: Bool = false // ttnet用的，暂时用不到
    var forceDecode: Bool = false // 下载完是否强制解码
    var isCDNdowngrade: Bool = true // 支持CDN降级
    var gifLimitSize: Int = 0 // 超过limit大小gif不解码
    var fuzzyCache: Bool = true // 缓存模糊查找
    /// 不解码 GIF 阈值的内存系数
    ///
    /// 内存系数：可用内存大小是否  小于 图片解码后预计占用的大小（根据宽高估算） \* 内存系数，是则解码，为 0 则忽略
    public var skipDecodeGIFMemoryFactor: Double = 0
    /// 不解码 其他格式图片 阈值的内存系数
    ///
    /// 内存系数：可用内存大小是否  小于 图片解码后预计占用的大小（根据宽高估算） \* 内存系数，是则解码，为 0 则忽略
    public var skipDecodeIMGMemoryFactor: Double = 0
}
