//
//  MagicShareDocument.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/8/1.
//

import Foundation
import ByteViewNetwork

struct MagicShareDocument: Equatable, CustomStringConvertible {
    /// 共享类型，现在只有 ccm 在使用
    let shareType: FollowShareType
    /// 文档类型
    let shareSubType: FollowShareSubType
    /// 发起时传给CCM的url，后端会在链接中拼一些参数
    let urlString: String
    /// 发起人
    let user: ByteviewUser
    /// 发起人名字
    let userName: String
    /// 发起文档时注入的JS信息
    let strategies: [FollowStrategy]
    /// 发起方式
    let initSource: FollowInfo.InitSource
    /// 文档标题
    var docTitle: String
    /// 复制时获取的url链接
    let rawUrl: String
    // MARK: - 下面参数远端推送才会有值
    /// 标识共享的ID（但转移共享人不变）
    let shareID: String?
    /// 进一步细化的共享的ID（转移共享人也会变），参考 https://bytedance.feishu.cn/docx/doxcn4eH0x6i7DVTmqTp9wHgMtc
    let actionUniqueID: String?
    /// 文档token
    let token: String?
    /// 默认是否共享+【已废弃】共享人要求强制跟随
    let options: FollowInfo.Options?
    /// 缩略图数据
    let thumbnail: FollowInfo.ThumbnailDetail?
    /// 是否是投屏转妙享
    var isSSToMS: Bool = false
    /// 被共享的文档所属租户是否开启水印
    let docTenantWatermarkOpen: Bool
    /// 文档所有者的tenant_id
    let docTenantID: String

    /// 用于比较文档是否相同
    var ccmToken: String? {
        if shareType == .ccm {
            return token ?? urlString.vc.removeParams().components(separatedBy: "/").last
        }
        return nil
    }

    /// 是否需要显示水印
    func showWatermark(selfTenantID: String) -> Bool {
        selfTenantID != docTenantID && docTenantWatermarkOpen
    }

    var description: String {
        // 为避免optional类型在"\()"中引起偶现crash，先解包再返回数据
        let unwrappedShareID: String = shareID ?? "nil"
        let unwrappedActionUniqueID: String = actionUniqueID ?? "nil"
        let unwrappedOptions: String = "defaultFollow: \(options?.defaultFollow.description ?? "nil") + forceFollow:\(options?.forceFollow.description ?? "nil")"
        let isThumbnailEmpty: Bool = (thumbnail == nil)
        return """
        shareType: \(shareType),
        shareSubType: \(shareSubType),
        urlString: \(urlString.hashValue),
        rawUrl: \(rawUrl.hashValue)
        user: \(user)
        strategies: \(strategies)
        initSource: \(initSource),
        docTitle: \(docTitle.hashValue),
        shareID: \(unwrappedShareID),
        actionUniqueID: \(unwrappedActionUniqueID),
        options: \(unwrappedOptions),
        docTenantWatermarkOpen: \(docTenantWatermarkOpen),
        docTenantID: \(docTenantID),
        isThumbnailEmpty: \(isThumbnailEmpty)
        """
    }

    /// 妙享，通过FollowInfo创建MagicShareDocument
    /// - Parameters:
    ///   - followInfo: 文档信息
    /// - Returns: 文档实例
    static func from(followInfo: FollowInfo, userName: String) -> MagicShareDocument {
        return MagicShareDocument(
            shareType: followInfo.shareType,
            shareSubType: followInfo.shareSubtype,
            urlString: followInfo.url,
            userID: followInfo.user.id,
            userType: followInfo.user.type,
            userName: userName,
            deviceID: followInfo.user.deviceId,
            strategies: followInfo.strategies,
            initSource: followInfo.initSource,
            docTitle: followInfo.docTitle,
            rawUrl: followInfo.rawURL,
            shareID: followInfo.shareID.isEmpty ? nil : followInfo.shareID,
            actionUniqueID: followInfo.extraInfo.actionUniqueID.isEmpty ? nil : followInfo.extraInfo.actionUniqueID,
            token: followInfo.docToken.isEmpty ? nil : followInfo.docToken,
            options: followInfo.options,
            thumbnail: followInfo.thumbnail,
            docTenantWatermarkOpen: followInfo.extraInfo.docTenantWatermarkOpen,
            docTenantID: followInfo.extraInfo.docTenantID)
    }

    /// 投屏转妙享，通过CCMInfo创建MagicShareDocument
    /// - Parameters:
    ///   - ccmInfo: ScreenSharedData中推送的，识别出的文档信息
    /// - Returns: 文档实例
    static func from(ccmInfo: CCMInfo,
                     shareID: String,
                     userID: String,
                     userName: String,
                     userType: ParticipantType,
                     deviceID: String) -> MagicShareDocument {
        return MagicShareDocument(
            shareType: .ccm, // useless
            shareSubType: ccmInfo.type,
            urlString: ccmInfo.url,
            userID: userID,
            userType: userType,
            userName: userName,
            deviceID: deviceID,
            strategies: ccmInfo.strategies,
            initSource: .initDirectly, // useless
            docTitle: ccmInfo.title,
            rawUrl: ccmInfo.rawURL,
            shareID: shareID,
            actionUniqueID: ccmInfo.memberID, // useless
            token: ccmInfo.token,
            options: FollowInfo.Options(defaultFollow: false, forceFollow: false), // useless
            thumbnail: ccmInfo.thumbnail,
            isSSToMS: true,
            docTenantWatermarkOpen: ccmInfo.extraInfo.docTenantWatermarkOpen,
            docTenantID: ccmInfo.extraInfo.docTenantID)
    }

    init(shareType: FollowShareType,
         shareSubType: FollowShareSubType,
         urlString: String,
         userID: String,
         userType: ParticipantType,
         userName: String,
         deviceID: String,
         strategies: [FollowStrategy],
         initSource: FollowInfo.InitSource,
         docTitle: String,
         rawUrl: String,
         shareID: String? = nil,
         actionUniqueID: String? = nil,
         token: String? = nil,
         options: FollowInfo.Options? = nil,
         showWatermark: Bool = false,
         thumbnail: FollowInfo.ThumbnailDetail? = nil,
         isSSToMS: Bool = false,
         docTenantWatermarkOpen: Bool,
         docTenantID: String
    ) {
        self.shareType = shareType
        self.shareSubType = shareSubType
        self.urlString = urlString
        self.user = ByteviewUser(id: userID, type: userType, deviceId: deviceID)
        self.userName = userName
        self.strategies = strategies
        self.initSource = initSource
        self.docTitle = docTitle
        self.rawUrl = rawUrl
        self.shareID = shareID
        self.actionUniqueID = actionUniqueID
        self.token = token
        self.options = options
        self.thumbnail = thumbnail
        self.isSSToMS = isSSToMS
        self.docTenantWatermarkOpen = docTenantWatermarkOpen
        self.docTenantID = docTenantID
    }

    func hasEqualContentTo(_ document: MagicShareDocument) -> Bool {
        guard self.shareType == document.shareType,
              self.shareSubType == document.shareSubType,
              self.isSSToMS == document.isSSToMS else {
            return false
        }
        if self.shareType == .ccm {
            // ccm文档，比较ccmToken
            if let currentToken = ccmToken,
               let otherToken = document.ccmToken {
                return currentToken == otherToken
            } else {
                return false
            }
        } else {
            // 其他类型，比较去除参数的url
            let currentURLString = urlString.vc.removeParams()
            let otherURLString = document.urlString.vc.removeParams()
            return currentURLString == otherURLString
        }
    }

    func hasEqualContentTo(_ followInfo: FollowInfo) -> Bool {
        guard self.shareType == followInfo.shareType
                && self.shareSubType == followInfo.shareSubtype else {
            return false
        }
        if self.shareType == .ccm {
            if let currentToken = ccmToken {
                return currentToken == followInfo.docToken
            } else {
                return false
            }
        } else {
            let currentURLString = urlString.vc.removeParams()
            let otherURLString = followInfo.url.vc.removeParams()
            return currentURLString == otherURLString
        }
    }

    func hasEqualContentTo(_ vcDocs: VcDocs) -> Bool {
        if ccmToken != nil {
            return ccmToken == vcDocs.docToken
        } else {
            let currentURLString = urlString.vc.removeParams()
            let otherURLString = vcDocs.docURL.vc.removeParams()
            return currentURLString == otherURLString
        }
    }

    /// 检查共享文档的用户是不是特定用户
    /// - Parameter specifiedUser: 待比较的特定用户
    func checkIsUserSharing(with specifiedUser: ByteviewUser) -> Bool {
        return self.user == specifiedUser
    }

    /// 比较当前文档和ccmInfo是否是同一篇文档
    /// - Parameter ccmInfo: 投屏转妙享场景，ScreenSharedData中p侧识别到的文档信息
    /// - Returns: 是否是同一篇
    func hasEqualContentToCCMInfo(_ ccmInfo: CCMInfo) -> Bool {
        if let currentToken = ccmToken {
            return currentToken == ccmInfo.token
        } else {
            let currentURLString = urlString.vc.removeParams()
            let otherURLString = ccmInfo.url.vc.removeParams()
            return currentURLString == otherURLString
        }
    }

    /// 根据本地记录文档数组，更新当前文档的标题
    /// - Parameter documents: 本地记录的文档数组
    mutating func updateTitleWithLocalDocuments(_ documents: [MagicShareDocument]) {
        for document in documents where document.hasEqualContentTo(self) {
            self.docTitle = document.docTitle
        }
    }

    /// 兜底显示的非空标题
    var nonEmptyDocTitle: String {
        if docTitle.isEmpty {
            switch self.shareSubType {
            case .googleDoc, .googleWord, .ccmDoc, .ccmDocx, .ccmWord, .ccmWikiDoc, .ccmWikiDocX:
                return I18n.View_VM_UntitledDocument
            case .googleSheet, .googleExcel, .ccmSheet, .ccmExcel, .ccmWikiSheet:
                return I18n.View_VM_UntitledSheet
            case .ccmMindnote, .ccmWikiMindnote:
                return I18n.View_VM_UntitledMindnote
            case .googlePdf, .ccmPdf:
                return I18n.View_VM_UntitledFile
            case .googleSlide, .googlePpt, .ccmPpt, .ccmDemonstration:
                return I18n.View_VM_UntitledSlide
            case .ccmBitable:
                return I18n.View_VM_UntitledBase
            default:
                return I18n.View_VM_UntitledDocument
            }
        } else {
            return docTitle
        }
    }

    /// 发起MS的初始输入Url，拼接了actionUniqueID
    var initUrl: String {
        guard let auID = actionUniqueID else {
            return urlString
        }
        if !urlString.isEmpty, urlString.contains("?") {
            return urlString.appending("&action_unique_id=\(auID)")
        } else {
            return urlString.appending("?&action_unique_id=\(auID)")
        }
    }
}

extension MagicShareDocument {

    static func create(urlString: String, meeting: InMeetMeeting) -> Self {
        MagicShareDocument(
            shareType: .ccm,
            shareSubType: .ccmDocx,
            urlString: urlString,
            userID: meeting.userId,
            userType: meeting.account.type,
            userName: meeting.accountInfo.userName,
            deviceID: meeting.account.deviceId,
            strategies: [],
            initSource: .initDirectly,
            docTitle: "",
            rawUrl: urlString,
            shareID: nil,
            actionUniqueID: nil,
            token: nil,
            options: nil,
            thumbnail: nil,
            isSSToMS: false,
            docTenantWatermarkOpen: false,
            docTenantID: ""
        )
    }

}

enum MagicShareDocumentStatus: String, Equatable, CustomStringConvertible {
    /// 发起共享
    case sharing
    /// 跟随共享人
    case following
    /// 自由浏览
    case free
    /// 投屏转妙享跟随
    case sstomsFollowing
    /// 投屏转妙享自由浏览
    case sstomsFree

    var description: String {
        return self.rawValue
    }
}
