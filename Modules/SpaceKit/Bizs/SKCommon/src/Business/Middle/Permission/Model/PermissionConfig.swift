//
//  ISVApplicationConfig.swift
//  SKCommon
//
//  Created by guoqp on 2020/7/26.
//

import SKFoundation
import SwiftyJSON
import SKInfra

// MARK: - form share

///form meta
public final class FormShareMeta {
    public private(set) var token: String
    public private(set) var tableId: String
    public private(set) var viewId: String
    public private(set) var shareType: Int

    public private(set) var flag: Bool = false
    public private(set) var shareToken: String = ""
    
    public private(set) var hasCover: Bool
    
    public private(set) var shareHost: String?

    //可以被分享
    var canShare: Bool {
        return flag && !shareToken.isEmpty
    }
    
    var shareUrl: String? {
        guard !shareToken.isEmpty else {
            return nil
        }
        if UserScopeNoChangeFG.ZYS.disableBitableShareHostFix {
            return "https://" + DomainConfig.userDomain + "/share/base/" + shareToken
        }
        guard let host = shareHost, !host.isEmpty else {
            spaceAssertionFailure("share host has not been set!!")
            DocsLogger.error("share host has not been set!!")
            return nil
        }
        // 表单分享也迁移到新的分享链接
        return "https://\(host)/share/base/\(BitableShareSubType.form.shareTag)/\(shareToken)"
    }

    public init(token: String, tableId: String, viewId: String, shareType: Int, hasCover: Bool = false) {
        self.token = token
        self.tableId = tableId
        self.viewId = viewId
        self.shareType = shareType
        self.hasCover = hasCover
    }

    public func updateFlag(_ flag: Bool) {
        self.flag = flag
    }

    public func updateShareToken(_ shareToken: String) {
        self.shareToken = shareToken
    }
    
    public func updateShareHost(_ host: String?) {
        shareHost = host
    }
}

// MARK: - common share

private extension BitableShareSubType {
    var shareTag: String {
        switch self {
        case .form:
            return "form"
        case .view:
            spaceAssertionFailure("view has not beed imp, check tag value!!")
            DocsLogger.error("view has not beed imp, check tag value!!")
            return "view"
        case .record:
            return "record"
        case .addRecord:
            return "add_record"
        case .dashboard, .dashboard_redirect:
            return "dashboard"
        }
    }
}

public final class BitableShareEntity {
    private(set) var param: BitableShareParam
    private(set) var meta: BitableShareMeta?
    private let shareHost: String?
    
    public var isShareReady: Bool {
        meta?.isShareReady ?? false
    }
    
    public var isShareOn: Bool {
        meta?.isShareOn ?? false
    }
    
    public var isRecordShareV2: Bool {
        param.isRecordShareV2
    }
    
    public var isAddRecordShare: Bool {
        param.isAddRecordShare
    }
    
    public var shareUrl: String? {
        guard let meta = meta else {
            spaceAssertionFailure("meta has not been set!!")
            DocsLogger.error("meta has not been set!!")
            return nil
        }
        if UserScopeNoChangeFG.ZYS.disableBitableShareHostFix {
            return "https://\(DomainConfig.userDomain)/share/base/\(meta.shareType.shareTag)/\(meta.shareToken)"
        }
        guard let host = shareHost, !host.isEmpty else {
            spaceAssertionFailure("share host has not been set!!")
            DocsLogger.error("share host has not been set!!")
            return nil
        }
        if isRecordShareV2 {
            return "https://\(host)/record/\(meta.shareToken)"
        } else if isAddRecordShare {
            return "https://\(host)/base/add/\(meta.shareToken)"
        }
        return "https://\(host)/share/base/\(meta.shareType.shareTag)/\(meta.shareToken)"
    }
    
    ///
    public init(param: BitableShareParam, docUrl: URL?, meta: BitableShareMeta? = nil) {
        self.param = param
        if let url = docUrl, let host = DocsUrlUtil.getDocsCurrentUrlInfo(url).srcHost {
            self.shareHost = host
        } else {
            assertionFailure("cannot parse share host from docsUrl!")
            DocsLogger.error("cannot parse share host: \(String(describing: docUrl).md5())")
            self.shareHost = nil
        }
        self.meta = meta
    }
    
    public func updateMeta(_ meta: BitableShareMeta?) {
        self.meta = meta
    }
}

///// Bitable 通用分享数据结构
public struct BitableShareParam: Codable {
    public let baseToken: String
    public let title: String?   // 用于微信分享弹窗标题等场景
    public let shareType: BitableShareSubType
    public let tableId: String
    public let viewId: String?
    public let recordId: String?
    public let preShareToken: String? // 预生成的 shareToken，不需要再请求了，直接使用
    
    public init(
        baseToken: String,
        shareType: BitableShareSubType,
        tableId: String,
        title: String? = nil,
        viewId: String? = nil,
        recordId: String?,
        preShareToken: String? = nil
    ) {
        self.baseToken = baseToken
        self.title = title
        self.shareType = shareType
        self.tableId = tableId
        self.viewId = viewId
        self.recordId = recordId
        self.preShareToken = preShareToken
    }
}

extension BitableShareParam {
    public var isRecordShareV2: Bool {
        return shareType == .record
    }
    
    public var isAddRecordShare: Bool {
        return shareType == .addRecord
    }
}

public struct BitableShareMeta: Codable {
    public enum ShareFlag: Int, Codable {
        case undefine = -1
        case close = 0
        case open = 1
    }
    public let flag: ShareFlag
    public let objType: Int?
    public let shareToken: String
    public let shareType: BitableShareSubType
    // 当前用户是否禁止对互联网分享，false:未禁止  true：禁止
    public let constraintExternal: Bool?
}

extension BitableShareMeta {
    /// Compatible with the situation where the public permission of the old version is not set
    public var isPublicPermissionToBeSet: Bool {
        guard shareType == .dashboard_redirect else {
            return false
        }
        return flag == .open
    }
    
    public var isShareOn: Bool {
        flag == .open
    }
    
    public var isShareReady: Bool {
        if isPublicPermissionToBeSet {
            return false
        }
        return flag == .open && !shareToken.isEmpty
    }
}
