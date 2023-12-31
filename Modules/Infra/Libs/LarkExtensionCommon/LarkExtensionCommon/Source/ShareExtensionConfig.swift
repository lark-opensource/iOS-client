//
//  ShareExtensionConfig.swift
//  LarkExtensionCommon
//
//  Created by K3 on 2018/6/28.
//  Copyright © 2018年 bytedance. All rights reserved.
//

import Foundation
import LarkStorageCore

public final class ShareExtensionConfig {
    /// “shareExtension” 打开 “container app” 的URL
    public let urlString = "\(Bundle.main.infoDictionary?["HOST_SCHEME"] as? String ?? "lark")://client/extension/share"

    public static let share = ShareExtensionConfig()

    fileprivate var _groupName: String?
    /// shareGroupName
    fileprivate lazy var groupName: String? = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String

    /// sharedStore, 用于“shareExtension” 打开 “container app” 共享 KV 数据
    public static let sharedStore = KVStores.udkv(
        space: .global,
        domain: Domain.biz.core.child("ShareExtension"),
        mode: .shared
    ).usingMigration(
        config: .from(userDefaults: .appGroup, items: [
            "share_extension_is_lark_login" ~> "isLarkLogin",
            "share_extension_is_mail_enabled" ~> "isLarkMailEnabled",
            "share_extension_share_data" ~> "shareData",
        ])
    )

    /// 共享的沙盒路径,用于“shareExtension” 打开 “container app”共享文件存储
    public lazy var shareRootDirURL: URL? = {
        guard let groupName = groupName else {
            assert(false, "reade 'groupName' error")
            return nil
        }
        var shareRootDirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)
        assert(shareRootDirURL != nil, "get 'shareRootDirURL' error")
        return shareRootDirURL
    }()

    public var shareCacheURL: URL? {
        guard let rootURL = shareRootDirURL else {
            assert(false, "reade 'shareRootDirURL' error")
            return nil
        }
        var shareCacheURL = rootURL.appendingPathComponent("ShareCache")
        let manager = FileManager.default
        if !manager.fileExists(atPath: shareCacheURL.path) {
            do {
                try manager.createDirectory(at: shareCacheURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            } catch _ {
                assert(false, "create 'shareCacheURL' error")
                return nil
            }
        }
        return shareCacheURL
    }

    /// lark 是否登录
    @KVConfig(key: "isLarkLogin", default: false, store: sharedStore)
    public var isLarkLogin: Bool

    /// larkMail 是否开启.
    @KVConfig(key: "isLarkMailEnabled", default: false, store: sharedStore)
    public var isLarkMailEnabled: Bool

    /// 分享的数据
    @KVConfig(key: "shareData", store: sharedStore)
    private var _shareData: Data?

    /// 保存分享的数据到 sharedStore
    ///
    /// - Parameter content: 数据
    /// - Returns: 是否保存成功
    @discardableResult
    public func save(_ content: ShareContent) -> Bool {
        guard let data = content.data() else {
            return false
        }
        self._shareData = data
        return true
    }

    /// 读取 sharedStore 中分享的数据
    ///
    /// - Returns: 分享的数据
    public func shareData() -> ShareContent? {
        guard let data = self._shareData else {
            return nil
        }
        return ShareContent(data)
    }

    /// 共享沙盒路径下的随机（UUID）文件URL
    ///
    /// - Returns: 文件URL
    public func randomFileURL() -> URL? {
        guard let url = shareCacheURL else {
            return nil
        }
        return url.appendingPathComponent(UUID().uuidString)
    }

    /// 清除“sharedStore”和“shareRootDirURL”下的临时数据、文件
    public func cleanShareCache() {
        self._shareData = nil

        let manager = FileManager.default
        guard let cacheURL = shareCacheURL,
            let enumerator = manager.enumerator(atPath: cacheURL.path) else {
                return
        }

        while let name = enumerator.nextObject() as? String {
            try? manager.removeItem(at: cacheURL.appendingPathComponent(name))
        }
    }

    public init() {}
}
