//
//  NCImageCacheManager.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/12/22.
//

import SKFoundation
import SpaceInterface
import SKInfra

final class NCImageCacheManager {

    var clientVarSql: ClientVarSqlTableManager?

    init() {
    }

    func isOfflineToken(_ token: String?) -> Bool {
        guard let token = token else {
            return false
        }
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return false
        }
        let manuOfflineTokens = dataCenterAPI.manualOfflineTokens
        let isOfflined = manuOfflineTokens.contain(objToken: token)
        return isOfflined
    }

}

protocol NCImageCacheProtocol {
    func setObject(_ data: NSCoding?, forKey key: String, token: String?, needSync: Bool)
    func object(forKey key: String, token: String?, needSync: Bool?) -> NSCoding?
    func containsObject(forKey key: String, token: String?, needSync: Bool?) -> Bool
    func removePic(forKey key: String, token: String?)
}

extension NCImageCacheManager: NCImageCacheProtocol {

    func setObject(_ data: NSCoding?, forKey key: String, token: String?, needSync: Bool) {
        guard let data = data else {
            return
        }
        let isOfflined = isOfflineToken(token)
        let cache = (needSync == true || isOfflined) ? CacheService.docsImageStore : CacheService.docsImageCache
        cache.set(object: data, forKey: key)
    }
    func object(forKey key: String, token: String?, needSync: Bool?) -> NSCoding? {
        var reuslt: NSCoding? = CacheService.docsImageCache.object(forKey: key)
        if reuslt == nil {
            reuslt = CacheService.docsImageStore.object(forKey: key)
        }
        return reuslt
    }
    func containsObject(forKey key: String, token: String?, needSync: Bool?) -> Bool {
        var reuslt: Bool = CacheService.docsImageCache.containsObject(forKey: key)
        if reuslt == false {
            reuslt = CacheService.docsImageStore.containsObject(forKey: key)
        }
        return reuslt
    }
    func removePic(forKey key: String, token: String?) {
        CacheService.docsImageCache.removeObject(forKey: key)
        CacheService.docsImageStore.removeObject(forKey: key)
    }

    func migrateImageFromStoreToCache(key: String) {
        let reuslt: NSCoding? = CacheService.docsImageStore.object(forKey: key)
        if let reuslt = reuslt {
            CacheService.docsImageCache.set(object: reuslt, forKey: key)
            CacheService.docsImageStore.removeObject(forKey: key)
        }
    }
}
