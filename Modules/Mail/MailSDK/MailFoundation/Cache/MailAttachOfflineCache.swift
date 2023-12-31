//
//  MailAttachOfflineCache.swift
//  MailSDK
//
//  Created by ByteDance on 2023/8/22.
//

import Foundation
import LarkCache
import LarkStorage
import RxSwift

typealias SaveCompletion = (Result<IsoPath, MailAttachOfflineCache.CacheError>) -> Void
typealias FileResult = (path: IsoPath, fileName: String)
class MailAttachOfflineCache {
    enum CacheError: Error {
        case cacheNotFound
        case fileNotFound
        case copyFileFailed
        case saveInLarkCacheFailed
        case invalidURL
    }
    private var transientCacheMap = ThreadSafeDictionary<String, Cache>()
    private var persistentCacheMap = ThreadSafeDictionary<String, Cache>()
    private let disposeBag = DisposeBag()
    private let userID: String
    private let featureManager: UserFeatureManager
    private let cacheQueue: DispatchQueue
    
    init(userID: String, featureManager: UserFeatureManager) {
        self.userID = userID
        self.featureManager = featureManager
        self.cacheQueue = DispatchQueue(label: "mail.attach.offline.cache", qos: .default)
        cacheQueue.async {
            self.initialSetup()
        }
    }
    private func initialSetup() {
        let accountID = getCurrentAccountID()
        let persistentCache = constructCache(accountID: accountID, type: .persistent)
        persistentCacheMap[accountID] = persistentCache
        let transientCache = constructCache(accountID: accountID, type: .transient)
        transientCacheMap[accountID] = transientCache
        self.bindObserver()
    }
    
    private func bindObserver() {
        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SWITCH_ACCOUNT)
            .subscribe { [weak self] _ in
                guard let `self` = self else { return }
                //监听account切换, 修改cache实例的isoPath
                self.cacheQueue.async {
                    let accountID = self.getCurrentAccountID()
                    MailLogger.info("MailAttachOfflineCache: receive MAIL_SWITCH_ACCOUNT, rebuild cache property \(accountID)")
                    let persistentCache = self.constructCache(accountID: accountID, type: .persistent)
                    self.persistentCacheMap[accountID] = persistentCache
                    let transientCache = self.constructCache(accountID: accountID, type: .transient)
                    self.transientCacheMap[accountID] = transientCache
                }
            }.disposed(by: disposeBag)
    }
    
    private func getCurrentAccountID() -> String {
        var accountID = ""
        if let accID = Store.settingData.getCachedCurrentAccount()?.mailAccountID {
            accountID = accID
        } else {
            MailLogger.error("MailAttachOfflineCache: constructCache when current account id is nil, please check")
        }
        return accountID
    }
    
    private func constructCache(accountID: String, type: MailFileStorageType) -> Cache {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("Attachment")
        let rootPathType: RootPathType.Normal
        let cleanIdentifier: String
        if type == .persistent {
            rootPathType = .library
            cleanIdentifier = "library/mail/user_id/Attach_Persistent"
        } else {
            rootPathType = .cache
            cleanIdentifier = "library/Caches/mail/user_id/Attach"
        }
        let cachePath: IsoPath = .in(space: space, domain: domain).build(rootPathType) + accountID
        let tempCache = CacheManager.shared.cache(rootPath: cachePath, cleanIdentifier: cleanIdentifier)
        if featureManager.open(FeatureKey(fgKey: .encryptCache, openInMailClient: true)) {
            return tempCache.asCryptoCache()
        } else {
            return tempCache
        }
    }
    
    private func getCache(with type: MailFileStorageType, accountID: String) -> Cache {
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
}

extension MailAttachOfflineCache {
    func saveFile(key: String, filePath: String, fileName: String, type: MailFileStorageType, completion: SaveCompletion? = nil) {
        let accountID = getCurrentAccountID()
        saveFile(key: key, filePath: filePath, fileName: fileName, type: type, accountID: accountID, completion: completion)
    }
    
    func saveFile(key: String, filePath: String, fileName: String, type: MailFileStorageType, accountID: String, completion: SaveCompletion? = nil) {
        cacheQueue.async {
            let result = self.syncSave(key: key, filePath: filePath, fileName: fileName, type: type, accountID: accountID)
            DispatchQueue.main.async {
                completion?(result)
            }
        }
    }
    
    func getFile(key: String) -> FileResult? {
        let accountID = getCurrentAccountID()
        return getFile(key: key, accountID: accountID)
    }
    
    func getFile(key: String, accountID: String) -> FileResult? {
        return cacheQueue.sync {
            self.syncGetFile(key: key, accountID: accountID)
        }
    }
    
    func getFile(key: String, type: MailFileStorageType, accountID: String) -> FileResult? {
        return cacheQueue.sync {
            self.syncGetFile(key: key, type: type, accountID: accountID)
        }
    }
    
    func clear(key: String, type: MailFileStorageType, accountID: String) {
        cacheQueue.async {
            let cache = self.getCache(with: type, accountID: accountID)
            cache.removeFile(forKey: key)
        }
    }
        
    func clear(accountID: String) {
        cacheQueue.async {
            let persistentCache = self.getCache(with: .persistent, accountID: accountID)
            persistentCache.removeAllObjects()
            let transientCache = self.getCache(with: .transient, accountID: accountID)
            transientCache.removeAllObjects()
        }
    }
    
    func clear(type: MailFileStorageType, accountID: String) {
        cacheQueue.async {
            let cache = self.getCache(with: type, accountID: accountID)
            cache.removeAllObjects()
        }
    }

    private func syncGetFile(key: String, type: MailFileStorageType, accountID: String) -> FileResult? {
        let cache = getCache(with: type, accountID: accountID)
        guard let (path, extraData) = cache.iso.filePathAndExtendedData(forKey: key) else {
            MailLogger.info("MailAttachOfflineCache: cache not found in cacheType: \(type) ")
            return nil
        }
        if let fileNameData = extraData, let fileName = String(data: fileNameData, encoding: .utf8) {
            return (path, fileName)
        } else {
            return (path, path.lastPathComponent)
        }
    }
    
    private func syncGetFile(key: String, accountID: String) -> FileResult? {
        var result = self.syncGetFile(key: key, type: .transient, accountID: accountID)
        if result == nil {
            MailLogger.info("MailAttachOfflineCache: not found in transient cache")
            result = self.syncGetFile(key: key, type: .persistent, accountID: accountID)
            MailLogger.info("MailAttachOfflineCache: cache result in persistent cache \(result)")
        }
        return result
    }

    
    private func syncSave(key: String, filePath: String, fileName: String, type: MailFileStorageType, accountID: String) -> Result<IsoPath, CacheError> {
        let cache = getCache(with: type, accountID: accountID)
        guard FileOperator.isExist(at: filePath) else {
            MailLogger.error("MailAttachOfflineCache: file not exist \(filePath)")
            return .failure(CacheError.fileNotFound)
        }
        let uniqueName = key.md5() + "-" + fileName
        let cachePath = cache.iso.filePath(forKey: uniqueName)
        guard FileOperator.copyItem(at: filePath.asAbsPath(), to: cachePath) else {
            MailLogger.error("MailAttachOfflineCache: copy item to cache failed")
            return .failure(CacheError.copyFileFailed)
        }
        let extraData = fileName.data(using: .utf8)
        guard cache.saveFile(key: key, fileName: uniqueName, extendedData: extraData) != nil else {
            MailLogger.error("MailAttachOfflineCache: save to larkcache faile")
            return .failure(CacheError.saveInLarkCacheFailed)
        }
        return .success(cachePath)
    }
}
