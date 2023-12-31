//
//  RustImageService.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/13.
//

import Foundation
import EEAtomic
import LKCommonsLogging

private let kOriginCacheName = "com.lark.cache.origin"
private let kThumbCacheName = "com.lark.cache.thumb"

public typealias RequestModifier = (URLRequest) -> URLRequest

public final class LarkImageService: NSObject {
    public static let shared = LarkImageService()

    static let logger = Logger.log(LarkImageService.self, category: "ByteWebImage.LarkImageService")

    public var avatarConfig: AvatarImageConfig { dependency.avatarConfig }

    public var imageSetting: ImageSetting { dependency.imageSetting }
    public var imageDisplaySetting: ImageDisplayStrategySetting { dependency.imageDisplayStrategySetting }
    public var imageUploadSetting: ImageUploadComponentConfig { dependency.imageUploadComponentConfig }
    public var imageExportConfig: ImageExportConfig { dependency.imageExportConfig }
    public var imagePreloadConfig: ImagePreloadConfig { dependency.imagePreloadConfig }

    public var avatarDownloadHeic: Bool { dependency.avatarDownloadHeic }
    public var imageUploadWebP: Bool { dependency.imageUploadWebP }

    public private(set) var originCache: ImageCache // 原图缓存
    public private(set) var thumbCache: ImageCache // 缩略图缓存（Avatar小图专用）
    public var avatarPath: String {
        thumbCache.diskCache.path
    }

    /// - Note: internal only for debug, otherwise consider it to private(set)
    var dependency: LarkImageServiceDependency

    public var stickerSetDownloadPath: String { dependency.stickerSetDownloadPath }

    override init() {
        self.dependency = DefaultImageServiceDependencyIMP()

        do { // 原图缓存
            var memoryConfig = ImageMemoryCacheConfig.default
            memoryConfig.maxSize = UInt(dependency.imageSetting.cache.original)
            let memoryCache = DefaultImageMemoryCache(memoryConfig)

            var diskConfig = ImageDiskCacheConfig.default
            diskConfig.maxSize = UInt(dependency.imageSetting.cache.original)
            let diskCache = LarkDiskCache(with: kOriginCacheName, crypto: true, accountID: dependency.currentAccountID)
            diskCache.config = diskConfig

            originCache = ImageCache(kOriginCacheName, memoryCache: memoryCache, diskCache: diskCache)
        }
        do { // 缩略图缓存
            var memoryConfig = ImageMemoryCacheConfig.default
            memoryConfig.clearCacheWhenEnterBackground = false
            memoryConfig.maxSize = UInt(dependency.imageSetting.cache.thumb)
            let memoryCache = DefaultImageMemoryCache(memoryConfig)

            var diskConfig = ImageDiskCacheConfig.default
            diskConfig.maxSize = UInt(dependency.imageSetting.cache.thumb)
            let diskCache = LarkDiskCache(with: kThumbCacheName) // 非原图不需要加密，所以不用 uid 区分
            diskCache.config = diskConfig

            thumbCache = ImageCache(kThumbCacheName, memoryCache: memoryCache, diskCache: diskCache)
        }

        ImageManager.default.registerCache(thumbCache, forKey: kThumbCacheName)
        ImageManager.default.registerCache(originCache, forKey: kOriginCacheName)
        let rustDownlaoder = RustDownloader()
        ImageManager.default.registerRustDownloader(rustDownlaoder)
        super.init()
        resetConfig()
        let plugin = LarkImagePerformancePlugin()
        PerformanceMonitor.shared.registerPlugin(plugin)
        #if ByteWebImage_Include_Lark_Debug
        DebugUtils.register()
        #endif
        self.dependency.accountChangeBlock = { [weak self] in
            self?.accountChange()
        }
    }

    func accountChange() {
        self.resetCache()
        let originDiskCache = LarkDiskCache(with: kOriginCacheName, crypto: true, accountID: self.dependency.currentAccountID)
        self.originCache.resetDiskCache(originDiskCache)
        self.resetConfig()
    }

    // MARK: - Public Func

    /// 将图片存入缓存
    public func cacheImage(image: UIImage,
                           data: Data? = nil,
                           resource: LarkImageResource,
                           cacheOptions: ImageCacheOptions = .all,
                           callback: ImageCacheCallback? = nil) {
        let cacheKey = resource.cacheKey
        guard !cacheKey.isEmpty else {
            callback?(nil, nil)
            return
        }
        if case let .avatar(_, _, params) = resource, params.sizeType == .thumb {
            self.thumbCache.set(image, data: data, forKey: cacheKey, options: cacheOptions, completion: callback)
        } else {
            originCache.set(image, data: data, forKey: cacheKey, options: cacheOptions, completion: callback)
        }
    }

    /// 判断是否已经在缓存里
    public func isCached(resource: LarkImageResource, options: ImageCacheOptions = .all) -> Bool {
        let cacheKey = resource.cacheKey
        guard !cacheKey.isEmpty else { return false }
        if case let .avatar(_, _, params) = resource, params.sizeType == .thumb {
            return self.thumbCache.contains(cacheKey, options: options) != .none
        } else {
            return originCache.contains(cacheKey, options: options) != .none
        }
    }

    /// 获取缓存的Image(未解码)
    public func image(with resource: LarkImageResource,
                      cacheOptions: ImageCacheOptions = .all) -> UIImage? {
        let cacheKey = resource.cacheKey
        guard !cacheKey.isEmpty else { return nil }
        if case let .avatar(_, _, params) = resource, params.sizeType == .thumb {
            return self.thumbCache.image(for: cacheKey,
                                         cacheOptions: cacheOptions,
                                         requestOptions: [.notDecodeForDisplay])
        } else {
            return originCache.image(for: cacheKey,
                                     cacheOptions: cacheOptions,
                                     requestOptions: [.notDecodeForDisplay])
        }
    }

    // 异步获取缓存的image
    public func image(with resource: LarkImageResource,
                      cacheOptions: ImageCacheOptions = .all,
                      completion: @escaping (UIImage?, String) -> Void) {
        let cacheKey = resource.cacheKey
        guard !cacheKey.isEmpty else {
            return
        }
        if case let .avatar(_, _, params) = resource, params.sizeType == .thumb {
            return self.thumbCache.image(for: cacheKey,
                                         cacheOptions: cacheOptions,
                                         callBack: completion)
        } else {
            return originCache.image(for: cacheKey,
                                     cacheOptions: cacheOptions,
                                     callBack: completion)
        }
    }

    /// 移除缓存
    public func removeCache(resource: LarkImageResource, options: ImageCacheOptions = .all) {
        let cacheKey = resource.cacheKey
        guard !cacheKey.isEmpty else { return }
        if case let .avatar(_, _, params) = resource, params.sizeType == .thumb {
            self.thumbCache.removeObject(forKey: cacheKey, options: options)
        } else {
            originCache.removeObject(forKey: cacheKey, options: options)
        }
    }

    /// 根据Resource 获取缓存
    public func cache(for resource: LarkImageResource) -> ImageCache {
        if case let .avatar(_, _, params) = resource, params.sizeType == .thumb {
            return self.thumbCache
        } else {
            return originCache
        }
    }

    /// 获取默认缓存, origin缓存
    public func cache() -> ImageCache {
        return originCache
    }

    /// 清除全部缓存
    public func clearAllCache() {
        originCache.clearAll()
        thumbCache.clearAll()
    }

    /// 获取图片
    /// - Parameters:
    ///   - resource: Lark 图片资源 LarkImageResource，支持填入 Rust image key / http(s) / file / base64 / 头像 / 表情
    ///   - passThrough: 透传 RustPB 的 Basic\_V1\_ImageSetPassThrough 字段，一般不用传
    ///   - options: 请求选项，一般不用传
    ///   - config: 请求配置
    ///   - category: 请求分类标识符，在埋点中可以分类查询
    ///   - modifier: RequestModifier, 可以在 URLRequest 发起请求之前修改，一般不用传
    ///   - file: 调用此方法的文件信息，**禁止覆盖默认值**
    ///   - function: 调用此方法的方法信息，**禁止覆盖默认值**
    ///   - line: 调用此方法的行号信息，**禁止覆盖默认值**
    ///   - progress: 下载进度更新回调
    ///   - decrypt: 下载完成后解密回调
    ///   - completion: 图片加载完成回调，可以在此获取到最终图片
    /// - Returns: 图片请求 LarkImageRequest
    @discardableResult
    public func setImage(with resource: LarkImageResource,
                         passThrough: ImagePassThrough? = nil,
                         options: ImageRequestOptions? = nil,
                         category: String? = nil,
                         modifier: RequestModifier? = nil,
                         file: String = #fileID,
                         function: String = #function,
                         line: Int = #line,
                         progress: ImageRequestProgress? = nil,
                         decrypt: ImageRequestDecrypt? = nil,
                         completion: ImageRequestCompletion? = nil) -> LarkImageRequest? {
        do {
            let request = try LarkImageRequest(resource: resource, category: category)
            request.passThrough = passThrough
            request.sourceFileInfo = FileInfo(file: file, function: function, line: line)
            if let modifier = modifier, let defaultModifier = dependency.modifier {
                request.modifier = { urlRequest in
                    modifier(defaultModifier(urlRequest))
                }
            } else {
                request.modifier = modifier ?? dependency.modifier
            }
            if let options = options {
                request.params = options.parse()
            }
            if request.params.cacheIdentifier == nil {
                switch resource {
                case let .avatar(_, _, params):
                    // 头像的缩略图会走特别的缓存
                    if params.sizeType == .thumb {
                        request.params.update(.cache(thumbCache.name))
                    } else {
                        request.params.update(.cache(originCache.name))
                    }
                default:
                    request.params.update(.cache(originCache.name))
                }
            }
            request.completionCallback = completion
            request.progressCallback = progress
            request.decryptCallback = decrypt
            ImageManager.default.requestImage(request)
            return request
        } catch {
            let byteError = error as? ByteWebImageError ?? ImageError(ByteWebImageErrorBadImageUrl, userInfo: [NSLocalizedDescriptionKey: "can not analysis key"])
            completion?(Result.failure(byteError))
        }
        return nil
    }
}

extension LarkImageService {
    /// 重置配置
    func resetConfig() {
        // 重置降采样数据
        ImageManager.default.defaultDownsampleSize = imageSetting.downsample.normalImage.pxSize
        HugeImageView.defaultConfig.tileThresholdPixels = imageSetting.downsample.image.pxValue
        HugeImageView.defaultConfig.tilePreviewPixels = imageSetting.downsample.tilePreviewImage.pxValue
        let scale = UIScreen.main.scale
        ImageManager.default.gifLimitSize = imageSetting.downsample.gif * Int(scale * scale)
        ImageManager.default.skipDecodeGIFMemoryFactor = imageSetting.downsample.skipDecodeGIFMemoryFactor
        ImageManager.default.skipDecodeIMGMemoryFactor = imageSetting.downsample.skipDecodeIMGMemoryFactor
        ImageConfiguration.animatedDelayMinimum = imageSetting.decode.animatedDelayMinimum
        ImageConfiguration.enableTile = imageSetting.downsample.enableTile
        Log.level = Log.Level(rawValue: imageSetting.logLevel) ?? .info
    }

    // 重置缓存
    func resetCache() {
        let thumConfig = thumbCache.config
        thumConfig.memorySizeLimit = UInt(imageSetting.cache.thumb)
        thumbCache.config = thumConfig
        // 对于原图缓存需要替换成加密缓存
        let originConfig = originCache.config
        // 缓存统一后，缓存容量统一
        originConfig.memorySizeLimit = UInt(imageSetting.cache.original)
        originCache.config = originConfig
    }

    // message根据imageItemSet生成
    func generateImageMessageKey(imageSet: ImageItemSet, forceOrigin: Bool) -> String {
        var key = ""
        if let originKey = imageSet.origin?.key {
            let isCached = originCache.contains(originKey) != .none
            key = (isCached || forceOrigin) ? originKey : getThumbKey(imageItemSet: imageSet)
        }
        return key
    }

    func generatePostMessageKey(imageSet: ImageItemSet, forceOrigin: Bool) -> String {
        var key = imageSet.origin?.key ?? ""
        if let token = imageSet.token, !token.isEmpty {
            if let originKey = imageSet.origin?.key {
                let isCached = originCache.contains(originKey) != .none
                key = (isCached || forceOrigin) ? originKey : getThumbKey(imageItemSet: imageSet)
            }
        }
        return key
    }

    func generateVideoMessageKey(imageSet: ImageItemSet, forceOrigin: Bool) -> String {
        var finalKey = ""
        if let originKey = imageSet.origin?.key {
            let isCached = originCache.contains(originKey) != .none
            finalKey = (isCached || forceOrigin) ? originKey : getThumbKey(imageItemSet: imageSet)
        }
        return finalKey
    }

    func getThumbKey(imageItemSet: ImageItemSet) -> String {
        let thumbImgItem = imageItemSet.thumbnail
        let middleImgItem = imageItemSet.middle

        if UIScreen.main.bounds.width * UIScreen.main.scale > CGFloat(
            LarkImageService.shared.imageDisplaySetting.messageImageLoad.remote.remoteAutoThumbScreenWidthMax) {
            if let midKey = middleImgItem?.key, !midKey.isEmpty {
                return midKey
            } else {
                return thumbImgItem?.key ?? ""
            }
        } else {
            return thumbImgItem?.key ?? ""
        }
    }

    func isOriginKey(key: String, imageItemSet: ImageItemSet) -> Bool {
        let originKey = imageItemSet.origin?.key
        return key == originKey
    }
}

public extension LarkImageService {
    /// 暂停所有的图片请求
    ///
    /// 因为登录成功后不一定能马上开始请求图片，需要等 makeUserOnline 之后才能请求图片
    /// 所以需要提供这个接口，供业务方在登录成功后 makeUserOnline 开始时暂停所有图片请求，makeUserOnline 成功后恢复图片请求
    func pauseImageRequest() {
        ImageManager.default.rustDownloader?.operationQueue.isSuspended = true
        Self.logger.info("LarkImageService pauseImageRequest")
    }
    /// 恢复所有的图片请求
    func resumeImageRequest() { // 没有 FG 也恢复请求，避免切租户切到没有 FG 的租户恢复不了队列
        ImageManager.default.rustDownloader?.operationQueue.isSuspended = false
        Self.logger.info("LarkImageService resumeImageRequest")
    }
}
