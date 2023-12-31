//
//  CacheService.swift
//  MailSDK
//
//  Created by majx on 2019/6/18.
//

import Foundation
import YYCache
import LarkCache
import LarkStorage
import RustPB
import RxSwift

/// MailPreview模块，存放预览的图片cache
enum MailPreview: Biz {
    static var parent: Biz.Type?
    static var path: String = "MailPreview"
}

class MailCacheService {
    private let userID: String
    private var cache: Cache?
    /// 不加密的cache，图片预览场景使用，因为drive预览需要文件路径，加密文件不支持解密会导致无法预览
    private var normalCache: Cache?
    private let disposeBag = DisposeBag()
    private let featureManager: UserFeatureManager
    
    init(userID: String, featureManager: UserFeatureManager) {
        self.userID = userID
        self.featureManager = featureManager
        DispatchQueue.main.async {
            self.initialSetup()
        }
    }

    private func initialSetup() {
        self.cache = constructCache()
        self.normalCache = constructMailPreviewCache()
        self.bindObserver()
    }
    
    private func bindObserver() {
        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SWITCH_ACCOUNT)
            .subscribe { [weak self] _ in
                guard let `self` = self else { return }
                //监听account切换, 修改cache实例的isoPath
                MailLogger.info("[mail_storage] receive MAIL_SWITCH_ACCOUNT, rebuild cache property")
                self.cache = self.constructCache()
                self.normalCache = self.constructMailPreviewCache()
            }
            .disposed(by: disposeBag)
    }
    
    private func constructCache() -> Cache {
        let cache = CacheManager.shared.cache(rootPath: makeCachePath(childName: "Image"), cleanIdentifier: "library/Caches/mail/user_id/Image")
        if featureManager.open(FeatureKey(fgKey: .encryptCache, openInMailClient: true)) {
            return cache.asCryptoCache()
        } else {
            return cache
        }
    }

    private func constructMailPreviewCache() -> Cache {
        let cache = CacheManager.shared.cache(rootPath: makeCachePath(childName: "MailPreview"), cleanIdentifier: "library/Caches/mail/user_id/MailPreview")
        return cache
    }
    
    private func makeCachePath(childName: String) -> IsoPath {
        let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("MailAccount_\(accountID)")
        let childDomain = domain.child(childName)
        let cachePath: IsoPath = .in(space: space, domain: childDomain).build(.cache)
        return cachePath
    }
    
    private func getCache(isCrypto: Bool) -> Cache? {
        return isCrypto ? cache : normalCache
    }

    /// 设置/清除缓存里的值，缓存里形式是[key: object]
    ///
    /// - Parameters:
    ///   - object: 需要被设置的值
    ///   - key: 缓存里的key
    func set(object: NSCoding?, for key: String, crypto: Bool = true) {
        let c = getCache(isCrypto: crypto)
        if let object = object {
            c?.set(object: object, forKey: key)
        } else {
            c?.removeObject(forKey: key)
        }
    }

    /// get cache data 缓存里形式是[key: object]
    func object(forKey key: String, crypto: Bool = true) -> NSCoding? {
        return getCache(isCrypto: crypto)?.object(forKey: key)
    }
    
    /// 返回被缓存的文件路径
    func cachedFilePath(forKey key: String, crypto: Bool = true) -> String? {
        return getCache(isCrypto: crypto)?.filePath(forKey: key)
    }
}
