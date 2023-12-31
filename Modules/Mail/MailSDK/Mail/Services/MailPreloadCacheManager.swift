//
//  MailPreloadCacheManager.swift
//  MailSDK
//
//  Created by ByteDance on 2023/8/22.
//

import Foundation
import RxSwift
import LarkStorage

// 管理预拉取缓存
class MailPreloadCacheManager {
    let imageCache: MailImageCacheProtocol
    let attachCache: MailAttachOfflineCache
    let featureManager: UserFeatureManager
    private let bag = DisposeBag()
    
    deinit {
        MailLogger.info("MailPreloadCacheManager deinit")
    }
    
    init(imageCache: MailImageCacheProtocol, attachCache: MailAttachOfflineCache, featureManager: UserFeatureManager) {
        self.imageCache = imageCache
        self.attachCache = attachCache
        self.featureManager = featureManager
        addObserver()
    }
    
    private func addObserver() {
        MailLogger.info("MailPreloadCacheManager: addObserver")
        guard enableCacheImageAndAttach() else {
            MailLogger.info("MailPreloadCacheManager: preload image and attach disable")
            return
        }
        MailLogger.info("MailPreloadCacheManager: addObserver")
        MailCommonDataMananger.shared.downloadProgressChange.subscribe(onNext: {[weak self] change in
            guard let self = self else { return }
            guard change.needSaveInMail, let fileType = change.fileType, change.progressInfo.status == .success else { return }
            switch fileType {
            case .image:
                self.saveImage(for: change.progressInfo.fileToken, filePath: change.progressInfo.filePath, accountID: change.accountID)
            case .attach:
                self.saveFile(for: change.progressInfo.fileToken,
                              filePath: change.progressInfo.filePath,
                              fileName: change.progressInfo.fileName,
                              accountID: change.accountID)
            }
        }).disposed(by: bag)
        MailCommonDataMananger.shared.cleanCachePushChange.subscribe(onNext: {[weak self] change in
            guard let self = self else { return }
            switch change.cleanType {
            case .clientCleanAll:
                self.deleteAllFiles(accountID: change.accountID)
                self.deleteAllImages(accountID: change.accountID)
            case .clientCleanFile:
                self.deleteAllFiles(accountID: change.accountID)
            case .clientCleanImg:
                self.deleteAllImages(accountID: change.accountID)
            case .clientCleanByToken:
                self.clean(by: change.tokens, accountID: change.accountID)
            case .cleanUnspecified:
                MailLogger.error("MailPreloadCacheManager: clean unspecified")
            @unknown default:
                MailLogger.error("MailPreloadCacheManager: unknown case")
            }
        }).disposed(by: bag)
    }
    private func clean(by tokens: [String], accountID: String) {
        for token in tokens {
            self.deleteFile(for: token, accountID: accountID)
            self.deleteImage(for: token, accountID: accountID)
        }
    }
    // MARK: - Files
    private func saveFile(for key: String, filePath: String, fileName: String, accountID: String) {
        MailLogger.info("MailPreloadCacheManager: save file \(filePath)")
        guard !fileExist(for: key, accountID: accountID) else {
            MailLogger.info("MailPreloadCacheManager: file exist")
            return
        }
        attachCache.saveFile(key: key, filePath: filePath, fileName: fileName, type: .persistent, accountID: accountID) { result in
            MailLogger.info("MailPreloadCacheManager: save file result \(result)")
            if case .success = result {
                // 缓存成功后删除文件
                if let isoPath = try? IsoPath.parse(fromRust: filePath) {
                    try? isoPath.removeItem()
                }
            }
        }
    }
    
    private func fileExist(for key: String, accountID: String) -> Bool {
        guard let path = attachCache.getFile(key: key, type: .persistent, accountID: accountID)?.path else {
            return false
        }
        return path.exists
    }
    private func deleteFile(for key: String, accountID: String) {
        attachCache.clear(key: key, type: .persistent, accountID: accountID)
    }
    private func deleteAllFiles(accountID: String) {
        attachCache.clear(type: .persistent, accountID: accountID)
    }
    // MARK: - images
    private func saveImage(for key: String, filePath: String, accountID: String) {
        MailLogger.info("MailPreloadCacheManager: save image \(filePath)")
        guard let isoPath = try? IsoPath.parse(fromRust: filePath) else {
            MailLogger.error("MailPreloadCacheManager: invalid path")
            return
        }
        if let data =  imageCache.get(key: key, accountID: accountID) {
            MailLogger.info("MailPreloadCacheManager: cache exist")
            imageCache.set(key: key, image: data, type: .persistent, accountID: accountID, completion: {
                // 缓存成功后删除文件
                try? isoPath.removeItem()
            })
            return
        }
        guard let data = (try? Data.read(from: isoPath)) else {
            MailLogger.error("MailPreloadCacheManager: file not found")
            return
        }
        MailLogger.info("MailPreloadCacheManager: set cache \(filePath)")
        imageCache.set(key: key, image: data, type: .persistent, accountID: accountID, completion: {
            // 缓存成功后删除文件
            try? isoPath.removeItem()
        })
    }
    private func deleteImage(for key: String, accountID: String) {
        imageCache.clear(key: key, type: .persistent, accountID: accountID, completion: {})
    }
    private func deleteAllImages(accountID: String) {
        imageCache.clear(type: .persistent, accountID: accountID, completion: {})
    }
    
    private func enableCacheImageAndAttach() -> Bool {
        return featureManager.open(.offlineCache, openInMailClient: false)
        && featureManager.open(.offlineCacheImageAttach, openInMailClient: false)
    }
}

