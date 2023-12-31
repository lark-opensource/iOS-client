//
//  MailImageCache.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/3/3.
//

import Foundation
import LarkCache
import LarkStorage
import RxSwift

enum MailFileStorageType {
    case transient
    case persistent
}

protocol MailImageCacheProtocol {
    /// Set both memory and disk cache
    func set(key: String, image: Data, type: MailFileStorageType, accountID: String, completion: @escaping () -> Void)
    func get(key: String, type: MailFileStorageType, accountID: String) -> Data?
    func get(key: String, accountID: String) -> Data?
    func clear(key: String, type: MailFileStorageType, accountID: String, completion: @escaping () -> Void)
    func clear(type: MailFileStorageType, accountID: String, completion: @escaping () -> Void)
    /// 区分不同分辨率的同一张图片 cache
    func cacheKey(token: String, size: CGSize?) -> String
}

// current account cache
extension MailImageCacheProtocol {
    func set(key: String, image: Data, type: MailFileStorageType, completion: @escaping () -> Void) {
        let accID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        set(key: key, image: image, type: type, accountID: accID, completion: completion)
    }
    func get(key: String, type: MailFileStorageType) -> Data? {
        let accID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        return get(key: key, type: type, accountID: accID)
    }
    func get(key: String) -> Data? {
        let accID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        return get(key: key, accountID: accID)
    }
    func clear(key: String, type: MailFileStorageType, completion: @escaping () -> Void) {
        let accID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        clear(key: key, type: type, accountID: accID, completion: completion)
    }
    func clear(type: MailFileStorageType, completion: @escaping () -> Void) {
        let accID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        clear(type: type, accountID: accID, completion: completion)
    }
}

class MailImageCache {
    private let cacheQueue: DispatchQueue = DispatchQueue(label: "mail.image.cache", qos: .default)
    private var transientCacheMap = ThreadSafeDictionary<String, Cache>()
    private var persistentCacheMap = ThreadSafeDictionary<String, Cache>()
    private var transientCache: Cache?
    private var persistentCache: Cache?

    private let disposeBag = DisposeBag()
    private let userID: String
    private let featureManager: UserFeatureManager
    
    init(userID: String, featureManager: UserFeatureManager) {
        self.userID = userID
        self.featureManager = featureManager
        self.cacheQueue.async { [weak self] in
            guard let self = self else { return }
            self.initialSetup()
        }
    }
    private func initialSetup() {
        let accountID = getCurrentAccountID()
        self.transientCache = constructCache(accountID: accountID, type: .transient)
        transientCacheMap[accountID] = transientCache
        if enableCacheImageAndAttach() {
            self.persistentCache = constructCache(accountID: accountID, type: .persistent)
            persistentCacheMap[accountID] = persistentCache
        }
        
        self.bindObserver()
    }
    
    private func bindObserver() {
        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SWITCH_ACCOUNT)
            .subscribe { [weak self] _ in
                guard let `self` = self else { return }
                self.cacheQueue.async { [weak self] in
                    guard let self = self else { return }
                    //监听account切换, 修改cache实例的isoPath
                    let accountID = self.getCurrentAccountID()
                    MailLogger.info("[mail_storage] receive MAIL_SWITCH_ACCOUNT, rebuild cache property \(accountID)")
                    self.transientCache = self.constructCache(accountID: accountID, type: .transient)
                    self.transientCacheMap[accountID] = self.transientCache
                    if self.enableCacheImageAndAttach() {
                        self.persistentCache = self.constructCache(accountID: accountID, type: .persistent)
                        self.persistentCacheMap[accountID] = self.persistentCache
                    }
                }
            }.disposed(by: disposeBag)
    }
    
    private func getCurrentAccountID() -> String {
        var accountID = ""
        if let accID = Store.settingData.getCachedCurrentAccount()?.mailAccountID {
            accountID = accID
        } else {
            MailLogger.error("[mail_storage] constructCache when current account id is nil, please check")
        }
        return accountID
    }
    
    private func constructCache(accountID: String, type: MailFileStorageType) -> Cache {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("Image")
        let rootPathType: RootPathType.Normal
        let cleanIdentifier: String
        if type == .persistent {
            rootPathType = .library
            cleanIdentifier = "library/mail/user_id/Image_Persistent"
        } else {
            rootPathType = .cache
            cleanIdentifier = "library/Caches/mail/user_id/Image"
        }
        let cachePath: IsoPath = .in(space: space, domain: domain).build(rootPathType) + accountID
        let tempCache = CacheManager.shared.cache(rootPath: cachePath, cleanIdentifier: cleanIdentifier)
        MailLogger.info("[mail_storage] constructCache type \(type), cachePath: \(cachePath)")
        if featureManager.open(FeatureKey(fgKey: .encryptCache, openInMailClient: true)) {
            return tempCache.asCryptoCache()
        } else {
            return tempCache
        }
    }
    
    private func getCache(for type: MailFileStorageType, accountID: String) -> Cache? {
        guard enableCacheImageAndAttach() else { // fg 未开启
            MailLogger.info("[mail_storage] offlineCacheImageAttach disable")
            return transientCache
        }
        switch type {
        case .persistent:
            if let cache = persistentCacheMap[accountID] {
                return cache
            } else {
                let cache = constructCache(accountID: accountID, type: type)
                persistentCacheMap[accountID] = cache
                return cache
            }
        case .transient:
            if let cache = transientCacheMap[accountID] {
                return cache
            } else {
                let cache = constructCache(accountID: accountID, type: type)
                transientCacheMap[accountID] = cache
                return cache
            }
        }
    }
    
    private func enableCacheImageAndAttach() -> Bool {
        return featureManager.open(.offlineCache, openInMailClient: false)
        && featureManager.open(.offlineCacheImageAttach, openInMailClient: false)
    }
    
    private func syncClear(key: String, type: MailFileStorageType, accountID: String) {
        guard let cache = getCache(for: type, accountID: accountID) else {
            MailLogger.info("[mail_storage] no cache")
            return
        }
        cache.removeObject(forKey: key)
    }
    
    private func syncClear(type: MailFileStorageType, accountID: String) {
        guard let cache = getCache(for: type, accountID: accountID) else {
            MailLogger.info("[mail_storage] no cache")
            return
        }
        cache.removeAllObjects()
    }
    
    private func syncSet(key: String, image: Data, type: MailFileStorageType, accountID: String) {
        guard let cache = getCache(for: type, accountID: accountID) else {
            MailLogger.info("[mail_storage] no cache")
            return
        }
        cache.set(object: image, forKey: key)
    }
    
    private func syncGet(key: String, type: MailFileStorageType, accountID: String) -> Data? {
        guard let cache = getCache(for: type, accountID: accountID) else {
            MailLogger.info("[mail_storage] no cache")
            return nil
        }
        return cache.object(forKey: key)
    }
}

extension MailImageCache: MailImageCacheProtocol {
    func clear(key: String, type: MailFileStorageType, accountID: String, completion: @escaping () -> Void) {
        self.cacheQueue.async { [weak self] in
            guard let self = self else { return }
            self.syncClear(key: key, type: type, accountID: accountID)
            completion()
        }
    }
    
    func clear(type: MailFileStorageType, accountID: String, completion: @escaping () -> Void) {
        self.cacheQueue.async { [weak self] in
            guard let self = self else { return }
            self.syncClear(type: type, accountID: accountID)
            completion()
        }
    }
    
    func set(key: String, image: Data, type: MailFileStorageType, accountID: String, completion: @escaping () -> Void) {
        self.cacheQueue.async { [weak self] in
            guard let self = self else { return }
            self.syncSet(key: key, image: image, type: type, accountID: accountID)
            completion()
        }
    }
    
    func get(key: String, type: MailFileStorageType, accountID: String) -> Data? {
        return self.cacheQueue.sync { [weak self] in
            guard let self = self else { return nil }
            return self.syncGet(key: key, type: type, accountID: accountID)
        }
    }
    
    func get(key: String, accountID: String) -> Data? {
        var data: Data? = get(key: key, type: .transient, accountID: accountID)
        if data == nil {
            data = get(key: key, type: .persistent, accountID: accountID)
        }
        return data
    }

    func cacheKey(token: String, size: CGSize?) -> String {
        guard let size = size else { return token }
        return "\(token)-\(size.width)*\(size.height)"
    }
}
