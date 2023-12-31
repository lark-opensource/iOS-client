//
//  ImageMemoryCacheable.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/31.
//

import Foundation

/// 图像内存缓存配置
public struct ImageMemoryCacheConfig {

    /// 内存警告时清理缓存(默认: 开启)
    public var clearCacheWhenReceiveMemoryWarning: Bool = true

    /// 进入后台时清理缓存(默认: 开启)
    public var clearCacheWhenEnterBackground: Bool = true

    /// [未使用]使用弱引用缓存(默认: 开启)
    public var useWeakReferenceCache: Bool = true

    /// 最大缓存数量(默认: UInt.max)
    public var maxCount: UInt = .max

    /// 最大缓存大小(默认: 256 MB)
    public var maxSize: UInt = 256 * 1024 * 1024

    /// [未使用]缓存过期时间(单位: 秒)(默认: 12h)
    public var expireTime: UInt = 12 * 60 * 60

    /// 默认配置
    public static var `default`: ImageMemoryCacheConfig {
        ImageMemoryCacheConfig()
    }
}

/// 图像内存缓存协议
public protocol ImageMemoryCacheable: AnyObject {

    typealias Key = String

    typealias Object = UIImage

    /// 缓存配置
    var config: ImageMemoryCacheConfig { get set }

    /// 移除缓存处理
    var removeObjectHandler: ((Key?) -> Void)? { get set }

    /// 获取缓存
    func object(forKey key: Key) -> Object?

    /// 设置缓存
    func setObject(_ obj: Object, forKey key: Key)
    /// 设置缓存(指定占用)
    func setObject(_ obj: Object, forKey key: Key, cost: UInt)

    /// 移除缓存
    func removeObject(forKey key: Key)
    /// 移除所有缓存
    func removeAllObjects()

    /// 是否存在指定缓存
    func contains(_ key: Key) -> Bool

    /// 当前缓存占用大小
    var totalCost: UInt { get }

    /// 当前缓存数量
    var totalCount: UInt { get }
}
