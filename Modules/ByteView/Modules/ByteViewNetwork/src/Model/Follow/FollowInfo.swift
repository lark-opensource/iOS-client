//
//  FollowInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_FollowInfo
public struct FollowInfo: Equatable {
    public init(userID: String,
                userType: ParticipantType,
                deviceID: String,
                thumbnail: ThumbnailDetail,
                url: String,
                rawURL: String,
                options: Options?,
                lifeTime: LifeTime,
                shareID: String,
                shareType: FollowShareType,
                shareSubtype: FollowShareSubType,
                docToken: String,
                docType: VcDocType,
                docTitle: String,
                strategies: [FollowStrategy],
                version: Int32,
                initSource: InitSource,
                extraInfo: ExtraInfo) {
        self.user = ByteviewUser(id: userID, type: userType, deviceId: deviceID)
        self.thumbnail = thumbnail
        self.url = url
        self.rawURL = rawURL
        self.options = options
        self.lifeTime = lifeTime
        self.shareID = shareID
        self.shareType = shareType
        self.shareSubtype = shareSubtype
        self.docToken = docToken
        self.docType = docType
        self.docTitle = docTitle
        self.strategies = strategies
        self.version = version
        self.initSource = initSource
        self.extraInfo = extraInfo
    }

    /// 分享者
    public var user: ByteviewUser

    /// 分享路径
    public var url: String

    /// follow相关配置信息（是否默认打开跟随）
    public var options: Options?

    /// 共享的文档的生命周期，是永久共享权限还是临时共享权限
    public var lifeTime: LifeTime

    /// 共享id，转移共享人时不变
    public var shareID: String

    /// 缩略图信息
    public var thumbnail: ThumbnailDetail

    /// 正在共享的文档token
    public var docToken: String

    /// 废弃，改用share_subtype
    public var docType: VcDocType

    /// 正在共享的文档标题
    public var docTitle: String

    /// 这次共享所使用的策略
    public var strategies: [FollowStrategy]

    /// 用于管理 user_id+device_id, 以及后续需要保序的属性
    public var version: Int32

    public var shareType: FollowShareType

    public var shareSubtype: FollowShareSubType

    public var initSource: InitSource

    /// 不带参数的url，供用户复制使用
    public var rawURL: String

    /// 后续一些和主逻辑无关的参数统一放这里面
    public var extraInfo: ExtraInfo

    public enum LifeTime: Int, Hashable {
        case unknown // = 0
        case ephemeral // = 1
        case permanent // = 2
    }

    /// 进入follow的来源
    public enum InitSource: Int, Hashable {
        case unknown // = 0
        case initDirectly // = 1
        case initFromLink // = 2
        case initReactivated // = 3
    }

    public struct Options: Equatable {
        public init(defaultFollow: Bool, forceFollow: Bool) {
            self.defaultFollow = defaultFollow
            self.forceFollow = forceFollow
        }

        /// 发起共享时，是否默认跟随
        public var defaultFollow: Bool

        /// 分享中切换是否强制跟随
        public var forceFollow: Bool
    }

    public struct ExtraInfo: Equatable {
        public init(sharerTenantWatermarkOpen: Bool, docTenantWatermarkOpen: Bool, actionUniqueID: String, docTenantID: String) {
            self.sharerTenantWatermarkOpen = sharerTenantWatermarkOpen
            self.docTenantWatermarkOpen = docTenantWatermarkOpen
            self.actionUniqueID = actionUniqueID
            self.docTenantID = docTenantID
        }
        /// 主共享人租户是否开启水印
        public var sharerTenantWatermarkOpen: Bool
        /// 被共享的文档所属租户是否开启水印
        public var docTenantWatermarkOpen: Bool
        /// 一次Action对应的ID
        public var actionUniqueID: String
        /// 文档所有者的tenant_id
        public var docTenantID: String
    }
}

extension FollowInfo {
    /// Videoconference_V1_ThumbnailDetail
    public struct ThumbnailDetail: Equatable {
        public init(thumbnailURL: String, decryptKey: String, cipherType: CipherType, nonce: String) {
            self.thumbnailURL = thumbnailURL
            self.decryptKey = decryptKey
            self.cipherType = cipherType
            self.nonce = nonce
        }

        ///缩略图url
        public var thumbnailURL: String

        ///解密密钥
        public var decryptKey: String

        ///加密方式 0 = 未加密，1 = AES_256_GCM，2 = AES-CBC
        public var cipherType: CipherType

        /// 解密nonce,供aes gcm加密方式使用
        public var nonce: String

        public enum CipherType: Int, Hashable {
            case unencrypted // = 0
            case aes256Gcm // = 1
            case aesCbc // = 2
            case sm4128 // = 3
        }
    }
}

extension FollowInfo: CustomStringConvertible {

    public var description: String {
        String(indent: "FollowInfo",
               "url: \(url.hash)",
               "user: \(user)",
               "shareId: \(shareID)",
               "shareType: \(shareType)",
               "shareSubType: \(shareSubtype)",
               "lifeTime: \(lifeTime)",
               "thumbnail: \(thumbnail)",
               "strategies: \(strategies)",
               "version: \(version)",
               "options: \(options)",
               "initSource: \(initSource)",
               "rawURL: \(rawURL.hash)",
               "docTenantWatermarkOpen: \(extraInfo.docTenantWatermarkOpen)",
               "docTenantID: \(extraInfo.docTenantID)"
        )
    }
}

extension FollowInfo.ThumbnailDetail: CustomStringConvertible {

    public var description: String {
        String(indent: "ThumbnailDetail",
               "thumbnailURL: \(thumbnailURL.hash)"
        )
    }
}
