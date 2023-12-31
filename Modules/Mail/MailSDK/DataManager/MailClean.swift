//
//  MailClean.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/7/19.
//

import Foundation
import LarkStorage
import LarkClean

extension CleanRegistry {
    @_silgen_name("Lark.LarkClean_CleanRegistry.Mail")
    public static func registerMail() {
        registerPaths(forGroup: "mail") { ctx in
            let users = ctx.userList
            var path: [CleanIndex.Path] = []
            path.append(contentsOf: MailCleanRegistry.cleanOldVersionCachePath())
            if let accountListIDs = Store.settingData.getCachedAccountList()?.map({ $0.mailAccountID }) {
                for user in users {
                    path.append(contentsOf: MailCleanRegistry.cleanPath(userID: user.userId, accountIDs: accountListIDs))
                    path.append(contentsOf: MailCleanRegistry.cleanAttachPath(userID: user.userId, accountIDs: accountListIDs))
                }
            }
            return path
        }
    }
  }
  
  class MailCleanRegistry {

    static func cleanOldVersionCachePath() -> [CleanIndex.Path] {
        var path: [CleanIndex.Path] = []
        path.append(CleanIndex.Path.abs(AbsPath.library.absoluteString.appendingPathComponent("MailSDK")))
        path.append(CleanIndex.Path.abs(AbsPath.cache.absoluteString.appendingPathComponent("attachment")))
        path.append(CleanIndex.Path.abs(AbsPath.cache.absoluteString.appendingPathComponent("readmail/image")))
        path.append(CleanIndex.Path.abs(AbsPath.cache.absoluteString.appendingPathComponent("MailPreview")))
        path.append(CleanIndex.Path.abs(AbsPath.cache.absoluteString.appendingPathComponent("mail")))
        return path
    }

    /// image
    static func cleanPath(userID: String, accountIDs: [String]) -> [CleanIndex.Path] {
        var path: [CleanIndex.Path] = []
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(cacheImagePath(userID: userID, accountID: $0).absoluteString) }))
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(cacheImageOldPath(userID: userID, accountID: $0).absoluteString) }))
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(cachePreloadImagePath(userID: userID, accountID: $0).absoluteString) }))
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(cachePreviewPath(userID: userID, accountID: $0).absoluteString) }))
        path.append(CleanIndex.Path.abs(cacheImagePath(userID: userID, accountID: "").absoluteString))
        path.append(CleanIndex.Path.abs(cacheImageOldPath(userID: userID, accountID: "").absoluteString))
        return path
    }

    static func cacheImagePath(userID: String, accountID: String) -> IsoPath {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("MailAccount_\(accountID)")
        let childDomain = domain.child("Image")
        let cachePath: IsoPath = .in(space: space, domain: childDomain).build(.cache)
        return cachePath
    }

    static func cacheImageOldPath(userID: String, accountID: String) -> IsoPath {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("Image")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.cache) + accountID
        return cachePath
    }

    // 预拉取图片缓存
    static func cachePreloadImagePath(userID: String, accountID: String) -> IsoPath {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("Image")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.library) + accountID
        return cachePath
    }

    static func cachePreviewPath(userID: String, accountID: String) -> IsoPath {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("MailAccount_\(accountID)")
        let childDomain = domain.child("MailPreview")
        let cachePath: IsoPath = .in(space: space, domain: childDomain).build(.cache)
        return cachePath
    }

    /// attachment
    static func cleanAttachPath(userID: String, accountIDs: [String]) -> [CleanIndex.Path] {
        var path: [CleanIndex.Path] = []
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(getAttachmentLibraryDir(userID: userID, accountID: $0).absoluteString) }))
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(getAttachmentCacheDir(userID: userID, accountID: $0).absoluteString) }))
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(getReadMailIamgeCacheDir(userID: userID, accountID: $0).absoluteString) }))
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(getNewAttachCacheDir(userID: userID, accountID: $0, isPersistent: true).absoluteString) }))
        path.append(contentsOf: accountIDs.map({ CleanIndex.Path.abs(getNewAttachCacheDir(userID: userID, accountID: $0, isPersistent: false).absoluteString) }))
        return path
    }

    static func getAttachmentLibraryDir(userID: String, accountID: String) -> IsoPath {
        let mspace = MSpace.account(id: accountID)
        let domain = Domains.Business.mail.child(mspace.isolationId).child(MailBiz.normal.isolationId)
        let rootPath: IsoPath = .in(space: .user(id: userID), domain: domain).build(.library)
        return rootPath + "MailSDK/Attachment"
    }

    static func getAttachmentCacheDir(userID: String, accountID: String) -> IsoPath {
        let mspace = MSpace.account(id: accountID)
        let domain = Domains.Business.mail.child(mspace.isolationId).child(MailBiz.normal.isolationId)
        let rootPath: IsoPath = .in(space: .user(id: userID), domain: domain).build(.cache)
        return rootPath + "attachment"
    }

    static func getReadMailIamgeCacheDir(userID: String, accountID: String) -> IsoPath {
        let mspace = MSpace.account(id: accountID)
        let domain = Domains.Business.mail.child(mspace.isolationId).child(MailBiz.normal.isolationId)
        let rootPath: IsoPath = .in(space: .user(id: userID), domain: domain).build(.cache)
        return rootPath + "readmail/image"
    }
      
    // 附件缓存(预拉取需求，附件需要业务自己管理新增缓存，同时把eml正常预览下载存储到临时缓存)
    // isPersistent:
    //    - true 预拉取需求，附件需要业务自己管理,不响应LarkCache自动清理逻辑
    //    - false: 附件正常下载存储的临时缓存
    static func getNewAttachCacheDir(userID: String, accountID: String, isPersistent: Bool) -> IsoPath {
        let space: Space = .user(id: userID)
        let domain = Domain.biz.mail.child("Attachment")
        let rootPathType: RootPathType.Normal
        if isPersistent {
            rootPathType = .library
        } else {
            rootPathType = .cache
        }
        let cachePath: IsoPath = .in(space: space, domain: domain).build(rootPathType) + accountID
        return cachePath
    }
}
