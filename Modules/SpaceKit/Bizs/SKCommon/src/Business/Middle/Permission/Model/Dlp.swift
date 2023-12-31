//
//  Dlp.swift
//  SKCommon
//
//  Created by guoqp on 2022/7/5.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import Compression
import SpaceInterface

public enum DlpErrorCode: Int {
    case dlpSameTenatDetcting = 900099001 // 内部租户DLP检测中
    case dlpExternalDetcting = 900099002  // 外部租户DLP拦截
    case dlpSameTenatSensitive = 900099003 //内部租户DLP拦截
    case dlpExternalSensitive = 900099004 //外部租户dlp拦截


    public static func errorMsg(with code: Int) -> String {
        guard let dlpErrorCode = DlpErrorCode(rawValue: code) else {
            return ""
        }
        let checkTime = DlpManager.dlpMaxCheckTime()
        switch dlpErrorCode {
        case .dlpSameTenatDetcting, .dlpExternalDetcting:
            return BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(checkTime)
        case .dlpSameTenatSensitive:
            return BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed
        case .dlpExternalSensitive:
            return BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed
        }
    }

    public static func errorMsg(with codeString: String) -> String {
        guard let code = Int(codeString) else {
            return ""
        }
        return errorMsg(with: code)
    }

    public static func isDlpError(with code: Int) -> Bool {
        return DlpErrorCode(rawValue: code) != nil
    }
}

/// dlp检测状态
public enum DlpCheckStatus: String {
    case Safe = "safe" ///安全
    case Detcting = "DLP_CONTENT_DETECTING" ///检测中
    case Sensitive = "DLP_CONTENT_SENSITIVE" ///敏感内容
    case Block = "FILE_BLOCK_COMMON" /// TT策略拦截
    case Unknow = "Unknow" /// 未知新增类型
    public func text(action: DlpCheckAction, tenantID: String?) -> String {
        var isSameTenant = true
        if let tenantID1 = tenantID, let tenantID2 = User.current.basicInfo?.tenantID {
            isSameTenant = tenantID1 == tenantID2
        }
        return text(action: action, isSameTenant: isSameTenant)
    }
    ///提示文案，收敛到这里，避免到处写
    public func text(action: DlpCheckAction, isSameTenant: Bool) -> String {
        let checkTime = DlpManager.dlpMaxCheckTime()
        if self == .Safe { return "" }
        switch self {
        case .Safe:
            return ""
        case .Detcting:
            return BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(checkTime)
        case .Block where action == .COPY:
            return BundleI18n.SKResource.LarkCCM_Docs_DLP_CopyFailed_Toast
        default:
            return isSameTenant ?
            BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed :
            BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed
        }
    }
}

/// dlp检测操作
public enum DlpCheckAction: String {
    case COPY = "CCM_CONTENT_COPY" /// CCM内容复制
    case PRINT = "CCM_PRINT" /// CCM文档打印
    case EXPORT = "CCM_EXPORT" /// CCM文档导出
    case SHARE = "CCM_SHARE" /// CCM文档对外分享
    case ATTACHMENTDOWNLOAD = "CCM_ATTACHMENT_DOWNLOAD" /// CCM文档内附件下载
    case CREATECOPY = "CCM_CREATE_COPY" /// CCM创建副本
    case OPENEXTERNALACCESS = "CCM_OPEN_EXTERNAL_ACCESS" /// CCM开启对外分享
    case OPENEXTERNALACCESSASYNC = "CCM_OPEN_EXTERNAL_ACCESS_ASYNC" /// CCM开启对外分享异步
    case OPENLINKSHARECHANGE = "CCM_LINK_SHARE_CHANGE" /// CCM开启对外链接分享
    case ADDCOLLABORATOR = "CCM_ADD_COLLABORATOR" /// CCM添加协作者
    case ADDCOLLABORATORASYNC = "CCM_ADD_COLLABORATOR_ASYNC" /// CCM添加协作者异步
    case MARKINGLABLE = "CCM_MARKING_LABLE" /// CCM打标签
    case OPEN = "CCM_OPEN" /// CCM打开文档操作

    static func operateList() -> [String] {
        var list: [String] = []
        list.append(Self.COPY.rawValue)
        list.append(Self.PRINT.rawValue)
        list.append(Self.EXPORT.rawValue)
        list.append(Self.SHARE.rawValue)
        list.append(Self.ATTACHMENTDOWNLOAD.rawValue)
        list.append(Self.CREATECOPY.rawValue)
        list.append(Self.OPENEXTERNALACCESS.rawValue)
        return list
    }
}

///dlp策略
class DlpPolicy: NSObject, NSCoding {
    var hasOpen: Bool = false
    var timeout: TimeInterval = 0
    var createTime: TimeInterval = 0
    var dlpMaxCheckTime: TimeInterval = 0
    ///过期
    var expired: Bool {
        (Date().timeIntervalSince1970 - createTime) > timeout
    }

    init(with hasOpen: Bool, timeout: TimeInterval, createTime: TimeInterval) {
        self.hasOpen = hasOpen
        self.timeout = timeout
        self.createTime = createTime
    }

    /**
     {
                 "res": false,
                 "setting": {
                     "DLPCheckTime": 900
                 },
                 "timeout": 36000
             }
     */
    init(with json: JSON) {
        super.init()
        json["res"].bool.map { self.hasOpen = $0 }
        json["setting"]["DLPCheckTime"].double.map { self.dlpMaxCheckTime = $0 }
        json["timeout"].double.map { self.timeout = $0 }
        self.createTime = Date().timeIntervalSince1970
    }

    public func encode(with coder: NSCoder) {
        coder.encode(hasOpen, forKey: "hasOpen")
        coder.encode(timeout, forKey: "timeout")
        coder.encode(createTime, forKey: "createTime")
        coder.encode(dlpMaxCheckTime, forKey: "dlpMaxCheckTime")
    }

    required public init?(coder: NSCoder) {
        hasOpen = coder.decodeBool(forKey: "hasOpen")
        timeout = coder.decodeDouble(forKey: "timeout")
        createTime = coder.decodeDouble(forKey: "createTime")
        dlpMaxCheckTime = coder.decodeDouble(forKey: "dlpMaxCheckTime")
    }
}

class DlpCheckResult: NSObject, NSCoding {
    let action: DlpCheckAction
    let isAllow: Bool
    let status: DlpCheckStatus

    init(action: DlpCheckAction, isAllow: Bool, status: DlpCheckStatus) {
        self.action = action
        self.isAllow = isAllow
        self.status = status
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(action.rawValue, forKey: "action")
        coder.encode(isAllow, forKey: "isAllow")
        coder.encode(status.rawValue, forKey: "status")
    }
    required public init?(coder: NSCoder) {
        let actionValue = coder.decodeObject(forKey: "action") as? String ?? ""
        action = DlpCheckAction(rawValue: actionValue) ?? .CREATECOPY
        isAllow = coder.decodeBool(forKey: "isAllow")
        let value = coder.decodeObject(forKey: "status") as? String ?? ""
        status = DlpCheckStatus(rawValue: value) ?? .Unknow
    }
}

///dlp检测文档风险
class DlpScs: NSObject, NSCoding {
    var results: [DlpCheckResult] = []
    var timeout: TimeInterval = 0
    var updateTime: TimeInterval = 0

    ///过期
    var expired: Bool {
        Date().timeIntervalSince1970 - updateTime > timeout
    }
    /**
     "resultMap": {
                 "CCM_ATTACHMENT_DOWNLOAD": {
                     "isAllow": true
                 },
                 "CCM_CONTENT_COPY": {
                     "isAllow": true
                 },
                 "CCM_CREATE_COPY": {
                     "isAllow": true
                 },
                 "CCM_EXPORT": {
                     "isAllow": true,
                     "bizAction": "DLP_CONTENT_DETECTING"
                 },
                 "CCM_PRINT": {
                     "isAllow": true,
                     "bizAction": "DLP_CONTENT_SENSITIVE"
                 },
                 "CCM_SHARE": {
                     "isAllow": true
                 }
             },
             "timeout": 3600
     */
    init(with json: JSON) {
        super.init()
        json["timeout"].double.map { self.timeout = $0 }
        self.updateTime = Date().timeIntervalSince1970

        var tempResults: [DlpCheckResult] = []
        json["resultMap"].dictionaryValue.forEach { (key, value) in
            guard let action = DlpCheckAction(rawValue: key),
                  let isAllow = value["isAllow"].bool
            else { return }
            let status: DlpCheckStatus
            if let bizAction = value["bizAction"].string {
                status = DlpCheckStatus(rawValue: bizAction) ?? .Unknow
            } else {
                status = .Safe
            }
            let result = DlpCheckResult(action: action, isAllow: isAllow, status: status)
            tempResults.append(result)
        }
        self.results = tempResults
    }

    func status(with action: DlpCheckAction) -> DlpCheckStatus? {
        results.first {
            $0.action == action
        }?.status
    }

    public func encode(with coder: NSCoder) {
        coder.encode(results, forKey: "results")
        coder.encode(timeout, forKey: "timeout")
        coder.encode(updateTime, forKey: "updateTime")

    }
    required public init?(coder: NSCoder) {
        results = coder.decodeObject(forKey: "results") as? [DlpCheckResult] ?? []
        timeout = coder.decodeDouble(forKey: "timeout")
        updateTime = coder.decodeDouble(forKey: "updateTime")
    }
}

extension DocsType {
    var dlpType: String {
        var temp = ""
        switch self {
        case .doc:
            temp = "DOC"
        case .sheet:
            temp = "SHEET"
        case .bitable:
            temp = "BITABLE"
        case .mindnote:
            temp = "MINDNOTE"
        case .file:
            temp = "FILE"
        case .docX:
            temp = "DOCX"
        case .slides:
            temp = "SLIDES"
        default:
            temp = ""
        }
        return temp
    }
}

extension DocsNetworkError {
    /// dlp错误码
    public static func isDlpError(_ err: Error?) -> Bool {
        guard let realError = err as? DocsNetworkError else {
            return false
        }
        return DlpErrorCode.isDlpError(with: realError.code.rawValue)
    }
    /// dlp错误描述
    public static func dlpErrorMsg(_ err: Error?) -> String {
        guard let realError = err as? DocsNetworkError else {
            return ""
        }
        return DlpErrorCode.errorMsg(with: realError.code.rawValue)
    }
}
