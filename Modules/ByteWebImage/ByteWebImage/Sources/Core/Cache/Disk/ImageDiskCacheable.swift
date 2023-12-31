//
//  ImageDiskCacheable.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/31.
//

import Foundation
import CommonCrypto

/// 图像磁盘缓存配置
public struct ImageDiskCacheConfig {

    /// 进入后台时清理缓存(默认: 开启)
    public var clearCacheWhenEnterBackground: Bool = true

    /// [未使用]最大缓存数量(默认: UInt.max)
    public var maxCount: UInt = .max

    /// 最大缓存大小(单位: B)(默认: 256 MB)
    public var maxSize: UInt = 256 * 1024 * 1024

    /// 缓存过期时间(单位: 秒)(默认: 7d)
    public var expireTime: UInt = 7 * 24 * 60 * 60

    /// 默认配置
    public static var `default`: ImageDiskCacheConfig {
        ImageDiskCacheConfig()
    }
}

public typealias TrimDiskCallback = (String) -> Void

/// 图像磁盘缓存协议
public protocol ImageDiskCacheable: AnyObject {

    typealias Key = String

    typealias Value = UIImage

    /// 缓存配置
    var config: ImageDiskCacheConfig { get set }

    var totalCount: UInt { get } // 所有缓存的数量
    var totalSize: UInt { get } // 所有缓存所占大小
    var trimDiskInBackground: Bool { get }  // 退到后台是否清除缓存
    var path: String { get }    // 缓存路径
    var trimCallback: TrimDiskCallback? { get set }

    /// < 同步阻塞判断指定的 key 是否保存在缓存中
    func contains(_ key: Key) -> Bool
    /// < 异步判断指定的 key 是否保存在缓存中
    func contains(_ key: Key, with callback: @escaping (String, Bool) -> Void)
    /// < 同步读缓存
    func data(for key: Key) -> Data?
    /// < 异步读缓存
    func data(for key: Key, with callback: @escaping (String, Data?) -> Void)
    /// < 同步写入磁盘缓存
    func set(_ data: Data?, for key: Key)
    /// < 异步写入磁盘缓存
    func set(_ data: Data?, for key: Key, with callback: @escaping () -> Void)
    /// < 将已存在的文件记录到缓存
    func setExistFile(for key: Key, with path: String)
    /// < 同步删除磁盘缓存
    func remove(for key: Key)
    /// < 异步删除磁盘缓存
    func remove(for key: Key, with callback: @escaping () -> Void)
    /// < 同步删除所有缓存
    func removeAll()
    /// < 异步删除所有缓存
    func removeAll(with callback: @escaping () -> Void)
    /// < 删除过期缓存
    func removeExpiredData()
    /// < 获取Key对应的缓存路径，不一定有数据，只是缓存文件最终对应的path
    func cachePath(for key: Key) -> String
}
