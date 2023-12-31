//
//  CommentDataStore.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/31.
//  

import SKFoundation
import SKUIKit
import SpaceInterface
import SKCommon
import SKInfra

// 这里用协议是为了让以后 storage 方便替换
public protocol CommentStorageType {
    func setVaule(_ data: Data?, forKey key: String)
    func getValue(byKey key: String) -> Data?
    func removeValue(byKey key: String)
}

class CommentContentCache: CommentStorageType {
    public internal(set) static var shared: CommentContentCache = CommentContentCache()

    func setVaule(_ data: Data?, forKey key: String) {
        guard let data = data  else {
            return
        }
        CacheService.normalCache.set(object: data, forKey: key)
    }

    func getValue(byKey key: String) -> Data? {
        CacheService.normalCache.object(forKey: key)
    }

    func removeValue(byKey key: String) {
        CacheService.normalCache.removeObject(forKey: key)
    }

}

class CommentImageCache: SKImageCacheService, CommentImageCacheInterface {
    public internal(set) static var shared: CommentImageCache = CommentImageCache()
    private var newCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!

    func storeImage(_ data: NSCoding?, forKey key: String) {
        newCacheAPI.storeImage(data, token: nil, forKey: key, needSync: false)
    }

    func storeImage(_ data: NSCoding?, token: String?, forKey key: String, needSync: Bool) {
        // 暂时不支持token, needSync传参
        newCacheAPI.storeImage(data, token: nil, forKey: key, needSync: false)
    }

    func getImage(byKey key: String) -> NSCoding? {
        newCacheAPI.getImage(byKey: key, token: nil)
    }

    func getImage(byKey key: String, token: String?) -> NSCoding? {
        // 暂时不支持token, needSync传参
        newCacheAPI.getImage(byKey: key, token: nil)
    }

    func getImage(byKey key: String, token: String?, needSync: Bool) -> NSCoding? {
        // 暂时不支持token, needSync传参
        newCacheAPI.getImage(byKey: key, token: nil)
    }

    func mapTokenAndPicKey(token: String?, picKey: String, picType: Int, needSync: Bool, isDrivePic: Bool?) {
    }

    func hasImge(forKey key: String, token: String?) -> Bool {
        // 暂时不支持token, needSync传参
        newCacheAPI.hasImge(forKey: key, token: nil)
    }

    func hasImge(forKey key: String, token: String?, needSync: Bool) -> Bool {
        // 暂时不支持token, needSync传参
        newCacheAPI.hasImge(forKey: key, token: nil)
    }

    func removePic(forKey key: String, token: String?) {
        newCacheAPI.removePic(forKey: key, token: nil)
    }

    func updateAsset(_ asset: SKAssetInfo) {
        newCacheAPI.updateAsset(asset)
    }

    func getAssetWith(fileTokens: [String]) -> [SKAssetInfo] {
        return newCacheAPI.getAssetWith(fileTokens: fileTokens)
    }

}


class CommentSubScribeCache {
    
    private class func storeKey(_ encryptedObjToken: String) -> String {
        let tenantId = User.current.info?.tenantID ?? ""
        let userId = User.current.info?.userID ?? ""
        return "\(tenantId)_\(userId)_\(encryptedObjToken)"
    }

    class func setCommentSubScribe(_ isSubscribe: Bool, _ encryptedToken: String) {
        let key = storeKey(encryptedToken)
        let resultData: Data? = try? JSONEncoder().encode(["isSubscribe": isSubscribe].self)
        CommentContentCache.shared.setVaule(resultData, forKey: key)
    }
    
    class func getCommentSubScribe(_ encryptedToken: String) -> Bool {
        let key = storeKey(encryptedToken)
        guard let data = CommentContentCache.shared.getValue(byKey: key) else {
            return false
        }
        guard let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return false
        }
        return dict["isSubscribe"] ?? false
    }
}


class CommentSubScribeCacheInstance: CommentSubScribeCacheInterface {
    init() {}
    
    func getCommentSubScribe(encryptedToken: String) -> Bool {
        CommentSubScribeCache.getCommentSubScribe(encryptedToken)
    }
    
    func setCommentSubScribe(_ isSubscribe: Bool, _ encryptedToken: String) {
        CommentSubScribeCache.setCommentSubScribe(isSubscribe, encryptedToken)
    }
}

