//
//  ImageCache+Cacheable.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/9/21.
//

import Foundation

// MARK: - Get
extension ImageCache {

    public struct ProcessType: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let none: ProcessType = []
        public static let transform = ProcessType(rawValue: 1 << 0)
        public static let crop = ProcessType(rawValue: 1 << 1)

        static func compare(_ lhs: ImageProcessConfig, _ rhs: ImageProcessConfig) -> ProcessType {
            var type = ProcessType.none
            if lhs.transformID != rhs.transformID {
                type = type.union(.transform)
            }
            if lhs.crop != rhs.crop {
                type = type.union(.crop)
            }
            return type
        }
    }

    public enum CacheImage {
        /// 普通图片，无需处理
        case normal(UIImage)
        /// 待加工图片，可能需要缩放、形变等处理
        case crude(UIImage, ProcessType)

        init(_ image: UIImage, _ lhs: ProcessKey, _ rhs: ProcessKey) {
            let type = ProcessType.compare(lhs.config, rhs.config)
            if type == .none {
                self = .normal(image)
            } else {
                self = .crude(image, type)
            }
        }
    }

    /// 获取图片缓存
    /// - Parameters:
    ///   - key: 键
    ///   - options: 查询位置
    ///   - fuzzy: 模糊查询
    ///   - requestOptions: 请求选项
    ///   - size: 降采样大小(px)
    /// - Returns: 图片缓存
    public func image(forKey key: Key, options: ImageCacheOptions = .all, fuzzy: Bool = false, requestOptions: ImageRequestOptions = [], size: CGSize = .zero) -> (CacheImage?, ImageCacheOptions) {
        image(forKey: key, options: options, fuzzy: fuzzy, requestOptions: requestOptions.parse(), size: size)
    }

    internal func image(forKey key: Key, options: ImageCacheOptions = .all, fuzzy: Bool = false, requestOptions: ImageRequestParams = [], size: CGSize = .zero) -> (CacheImage?, ImageCacheOptions) {
        var image: CacheImage?
        let targetKey = targetImageCacheKey(with: key, options: requestOptions, size: size)
        let processKey = processKey(targetKey)

        if options.contains(.memory) {
            let memoryKeyList = memoryKeyList(processKey, fuzzy: fuzzy)
            let memoryImage = memoryKeyList.lazy.compactMap { key -> CacheImage? in
                guard let image = self.memoryCache.object(forKey: key) else {
                    return nil
                }
                return CacheImage(image, processKey, self.processKey(key))
            }.first { _ in true }

            if case .normal = memoryImage {
                return (memoryImage, .memory)
            }
            image = memoryImage
        }
        if options.contains(.disk) {
            let diskKeyList = diskKeyList(processKey, fuzzy: (fuzzy && image == nil))
            let diskImage = diskKeyList.lazy.compactMap { key -> CacheImage? in
                guard let data = self.diskCache.data(for: key),
                      let image = self.image(from: data, options: requestOptions, downsample: size) else {
                    return nil
                }
                image.bt.webURL = URL(string: key)
                return CacheImage(image, processKey, self.processKey(key))
            }.first { _ in true }

            if diskImage != nil {
                return (diskImage, .disk)
            }
        }
        if image != nil {
            return (image, .memory)
        }
        return (nil, .none)
    }

    /// 同步获取缓存
    public func image(for key: String,
                      cacheOptions: ImageCacheOptions = .all,
                      requestOptions: ImageRequestOptions = [],
                      size: CGSize = .zero) -> UIImage? {
        image(for: key, cacheOptions: cacheOptions, requestOptions: requestOptions.parse(), size: size)
    }

    internal func image(for key: String,
                        cacheOptions: ImageCacheOptions,
                        requestOptions: ImageRequestParams,
                        size: CGSize) -> UIImage? {
        var image: UIImage?
        let targetKey = self.targetImageCacheKey(with: key, options: requestOptions, size: size)
        if cacheOptions.contains(.memory) {
            image = self.memoryCache.object(forKey: targetKey)
            if image != nil { return image }
        }
        if cacheOptions.contains(.disk) {
            guard let data = self.diskCache.data(for: key) else { return nil }
            image = self.image(from: data, options: requestOptions, downsample: size)
            image?.bt.webURL = URL(string: key)
            if let image = image, !self.memoryCache.contains(targetKey) {
                self.memoryCache.setObject(image, forKey: targetKey, cost: UInt(image.bt.cost))
                self.memoryKey.setObject(forKey: self.processKey(key))
            }
            return image
        }
        return nil
    }

    /// 异步获取缓存， 在主线程回调
    public func image(for key: String,
                      cacheOptions: ImageCacheOptions = .all,
                      requestOptions: ImageRequestOptions = [],
                      size: CGSize = .zero,
                      callBack: @escaping ((UIImage?, String) -> Void)) {
        DispatchImageQueue.async {
            let image = self.image(for: key,
                                   cacheOptions: cacheOptions,
                                   requestOptions: requestOptions,
                                   size: size)
            DispatchQueue.main.async {
                callBack(image, key)
            }
        }
    }

    /// 同步获取磁盘缓存
    public func imageData(for key: String) -> Data? {
        return self.diskCache.data(for: key)
    }

    /// 异步获取磁盘缓存
    public func imageData(for key: String, callback: @escaping (String, Data?) -> Void) {
        self.diskCache.data(for: key, with: callback)
    }
}

// MARK: - Set

public typealias ImageCacheCallback = ImageCache.SetCompletion

extension ImageCache {

    // 回调Image和存储路径
    public typealias SetCompletion = (UIImage?, String?) -> Void

    /// 将图片存储到缓存中
    /// - Parameters:
    ///   - image: 图片
    ///   - data: 图片数据
    ///   - key: 键
    ///   - options: 存储位置
    ///   - completion: 磁盘缓存后回调
    public func set(_ image: UIImage?, data: Data? = nil, forKey key: Key, options: ImageCacheOptions = .all, completion: SetCompletion? = nil) {
        if options.contains(.memory) {
            if let image = image {
                memoryCache.setObject(image, forKey: key, cost: UInt(image.bt.cost))
                memoryKey.setObject(forKey: processKey(key))
            } else if let data = data, let image = self.image(from: data) {
                // TODO: 这里应当考虑 Transformer 的影响
                image.bt.webURL = URL(string: key)
                memoryCache.setObject(image, forKey: key, cost: UInt(image.bt.cost))
                memoryKey.setObject(forKey: processKey(key))
            }
        }
        if options.contains(.disk) {
            saveImageToDisk(image, data: data, forKey: key, completion: completion)
        }
    }

    /// 将图片存储到磁盘缓存
    /// 有回调异步，无回调同步
    /// - Parameters:
    ///   - image: 图片
    ///   - data: 图片数据
    ///   - key: 键
    ///   - completion: 回调
    public func saveImageToDisk(_ image: UIImage?, data: Data? = nil, forKey key: String, completion: SetCompletion? = nil) {
        let save = {
            let cachePath = self.diskCachePath(forKey: key)
            guard let data = data ?? image?.bt.originData else {
                completion?(nil, cachePath)
                return
            }
            self.diskCache.set(data, for: key)
            completion?(image, cachePath)
        }
        if completion == nil {
            save()
        } else {
            DispatchImageQueue.async(execute: save)
        }
    }

    /// 获取磁盘缓存路径
    public func diskCachePath(forKey key: Key) -> String? {
        diskCache.cachePath(for: key)
    }
}

// MARK: - Remove
extension ImageCache {

    /// 移除缓存
    /// - Parameters:
    ///   - key: 键
    ///   - options: 检测范围(内存/磁盘)
    ///   - completion: 完成回调
    public func removeObject(forKey key: Key, options: ImageCacheOptions = .all, fuzzy: Bool = false, completion: ((Key) -> Void)? = nil) {
        DispatchImageQueue.async {
            if options.contains(.memory) {
                self.memoryCache.removeObject(forKey: key)
                self.memoryKey.removeObject(forKey: self.processKey(key), fuzzy: false)
            }
            if options.contains(.disk) {
                self.diskCache.remove(for: key)
            }
            completion?(key)
        }
    }

    /// 移除全部缓存
    public func clearAll() {
        clearMemory()
        clearDisk()
    }

    /// 移除内存缓存
    public func clearMemory() {
        memoryCache.removeAllObjects()
        memoryKey.removeAllObjects()
    }

    /// 移除磁盘缓存
    /// - Parameter completion: 完成回调
    public func clearDisk(completion: @escaping () -> Void = {}) {
        DispatchImageQueue.async { [weak self] in
            self?.diskCache.removeAll(with: completion)
        }
    }

    /// 移除过期磁盘缓存
    public func removeExpiredObjectsInDisk() {
        diskCache.removeExpiredData()
    }
}

// MARK: - Contains
extension ImageCache {

    // MARK: All

    /// 检测缓存是否存在
    ///
    /// 可以在主线程上执行，不频繁的磁盘查询耗时可以接受，不至于卡顿
    /// - Parameters:
    ///   - key: 键
    ///   - options: 检测范围(内存/磁盘)
    ///   - fuzzy: 模糊查询
    /// - Returns: 缓存位置
    public func contains(_ key: Key, options: ImageCacheOptions = .all, fuzzy: Bool = false) -> ImageCacheOptions {
        let processKey = processKey(key)
        let memoryKeyList = memoryKeyList(processKey, fuzzy: fuzzy)
        if options.contains(.memory), containsInMemory(memoryKeyList) {
            return .memory
        }
        let diskKeyList = diskKeyList(processKey, fuzzy: fuzzy)
        if options.contains(.disk), containsInDisk(diskKeyList) {
            return .disk
        }
        return .none
    }

    // MARK: Memory

    /// 检测内存缓存是否存在
    private func containsInMemory(_ list: [Key]) -> Bool {
        list.contains { memoryCache.contains($0) }
    }

    /// 检测内存缓存是否存在
    public func containsInMemory(_ key: Key, fuzzy: Bool = false) -> Bool {
        containsInMemory([key])
    }

    // MARK: Disk

    /// 检测磁盘缓存是否存在
    private func containsInDisk(_ list: [Key]) -> Bool {
        list.contains { diskCache.contains($0) }
    }

    /// 检测磁盘缓存是否存在
    public func containsInDisk(_ key: Key) -> Bool {
        containsInDisk([key])
    }
}

// MARK: - Utils
extension ImageCache {

    /// 预处理键
    func processKey(_ key: Key) -> ProcessKey {
        guard let (base, config) = key.bt.parse() else {
            return .origin(key)
        }
        return .process(key, base, config)
    }

    private func memoryKeyList(_ key: ProcessKey, fuzzy: Bool) -> [Key] {
        memoryKey.objects(forKey: key, fuzzy: fuzzy)
    }

    private func diskKeyList(_ key: ProcessKey, fuzzy: Bool) -> [Key] {
        switch key {
        case .origin(let origin):
            return [origin]
        case let .process(origin, base, _):
            return [origin, base]
        }
    }

    /// 获取图片处理过后的targetKey
    /// - Parameters:
    ///   - size: 单位：px
    public func targetImageCacheKey(with key: String, options: ImageRequestOptions, size: CGSize = .zero) -> String {
        targetImageCacheKey(with: key, options: options.parse(), size: size)
    }

    private func targetImageCacheKey(with key: String, options: ImageRequestParams, size: CGSize = .zero) -> String {
        guard key.count > 1 else { return key }
        let originKey = ImageRequestKey(key)
        originKey.setSmartCrop(options.smartCorp)
        if !size.equalTo(.zero) {
            originKey.setDownsampleSize(size)
        }
        return originKey.targetCacheKey()
    }

    /// 获取缓存图片
    /// 磁盘缓存会解码
    private func image(from data: Data, options: ImageRequestParams = [], downsample: CGSize = .zero, crop: CGRect = .zero, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let decode = !options.notDecodeForDisplay
        let notDownsample = options.notDownsample
        let needCrop = options.smartCorp
        let image = try? ByteImage(data, scale: scale, decodeForDisplay: decode, downsampleSize: notDownsample ? .notDownsample : downsample, cropRect: needCrop ? crop : .zero, enableAnimatedDownsample: options.enableAnimatedDownsample)
        return image
    }
}
