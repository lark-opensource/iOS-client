//
//  BTFieldLayoutStorage.swift
//  SKBitable
//
//  Created by X-MAN on 2023/3/2.
//

import Foundation
import LarkSetting
import SKFoundation

final class BTFieldLayoutCacheManager {
    static let shared = BTFieldLayoutCacheManager()
    private var caches: [String: BTFieldLayoutCache] = [:]
    
    init() { }
    
    /// 已BTController为维度的隔离，获取Cache 实例
    func cache(with key: String) -> BTFieldLayoutCache {
        if let store = caches[key] {
            return store
        }
        let cache = BTFieldLayoutCache()
        caches[key] = cache
        return cache
    }
    /// 移除对应的CacheStore实例
    func removeCache(with key: String) {
        caches.removeValue(forKey: key)
    }
}

final class BTFieldLayoutCache {
    
    private var cache: NSCache<NSString, BTFieldLayoutItem>
    
    init() {
        let countLimit: Int
        cache = NSCache<NSString, BTFieldLayoutItem>()
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let config = settings["card_cache_config"] as? [String: Int],
                let limit = config["layoutLimit"] {
                countLimit = limit
            } else {
                countLimit = 200
            }
        } catch {
            DocsLogger.btError("[BTFieldLayoutCacheManager] cetch setting faild: \(error)")
            countLimit = 200
        }
        cache.countLimit = countLimit
    }
    
    /// 获取对应的layoutItem key 为recordId, 如果没有会新创建
    func item(with key: String) -> BTFieldLayoutItem {
        if let item = cache.object(forKey: key as NSString) {
            return item
        }
        let item = BTFieldLayoutItem()
        cache.setObject(item, forKey: key as NSString)
        return item
    }
    
    // 清理所有缓存
    func clear() {
        cache.removeAllObjects()
    }
}

final class BTFieldLayoutItem {
    
    init() {
        // 缓存容量待定
        layoutAttributes = [String: UICollectionViewLayoutAttributes]()
        descriptionHeights = [String: CGFloat]()
    }
    var layoutAttributes: [String: UICollectionViewLayoutAttributes]
    var descriptionHeights: [String: CGFloat]
    
    func clear() {
        layoutAttributes = [:]
        descriptionHeights = [:]
    }
}
