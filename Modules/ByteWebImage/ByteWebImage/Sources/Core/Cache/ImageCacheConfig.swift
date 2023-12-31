//
//  ImageCacheConfig.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/31.
//

import Foundation

public final class ImageCacheConfig {

    // MARK: - Memory
    // 内存缓存，会在写入新的内存对象时，检查是否过期并进行清理操作，因此这里配置指的是清理全部内存缓存的策略
    var memory: ImageMemoryCacheConfig = .default

    public var clearMemoryOnMemoryWarning: Bool {
        get { memory.clearCacheWhenReceiveMemoryWarning }
        set { memory.clearCacheWhenReceiveMemoryWarning = newValue }
    }
    public var clearMemoryWhenEnteringBackgroud: Bool {
        get { memory.clearCacheWhenEnterBackground }
        set { memory.clearCacheWhenEnterBackground = newValue }
    }
    public var shouldUseWeakMemoryCache: Bool {
        get { memory.useWeakReferenceCache }
        set { memory.useWeakReferenceCache = newValue }
    }
    public var memoryLimitCount: UInt {
        get { memory.maxCount }
        set { memory.maxCount = newValue }
    }
    public var memorySizeLimit: UInt {
        get { memory.maxSize }
        set { memory.maxSize = newValue }
    }
    public var memoryAgeLimit: UInt {
        get { memory.expireTime }
        set { memory.expireTime = newValue }
    }

    // MARK: - Disk
    // 磁盘缓存，一般只有手动调用方法才会检查超过大小限制或过期缓存，并进行清理操作，因此这里配置指的是清理超限或者过期缓存的策略
    var disk: ImageDiskCacheConfig = .default

    public var trimDiskWhenEnteringBackground: Bool {
        get { disk.clearCacheWhenEnterBackground }
        set { disk.clearCacheWhenEnterBackground = newValue }
    }
    public var diskCountLimit: UInt {
        get { disk.maxCount }
        set { disk.maxCount = newValue }
    }
    public var diskSizeLimit: UInt {
        get { disk.maxSize }
        set { disk.maxSize = newValue }
    }
    public var diskAgeLimit: UInt {
        get { disk.expireTime }
        set { disk.expireTime = newValue }
    }

    public init(memory: ImageMemoryCacheConfig = .default, disk: ImageDiskCacheConfig = .default) {
        self.memory = memory
        self.disk = disk
    }
}

extension ImageCacheConfig: NSCopying {

    public func copy(with zone: NSZone? = nil) -> Any {
        let copyConfig = ImageCacheConfig()
        copyConfig.memory = memory
        copyConfig.disk = disk
        return copyConfig
    }
}
