//
//  AtTracker.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/4/22.
//  

import Foundation
import SKFoundation
import SpaceInterface
import SKInfra

// https://bytedance.feishu.cn/space/doc/doccn9B8ahgKAQUWF3dATt#xpc8gu
public final class AtTracker {
    public enum Zone: String {
        /// 正文编辑区
        case defaultZone =  "default"
        /// 排版表格
        case table = "table"
        /// 局部评论
        case partComment = "part_comment"
        /// 全文评论
        case fullComment = "full_comment"
        /// sheet fx 栏
        case fxBar = "fx_bar"
        /// sheet 全屏单元格
        case fullToolbar = "full_screen_toolbar"
        /// checkdox 插入 reminder
        case checkbox = "checkbox"

        case unknown = "unknown"
        /// 正文模块触发
        case text
    }
    public enum Source: String {
        case keyboard
        case toolbar
        case unknown
    }
    public struct Context {
        /// only for confirm_mention
        let mentionType: String?
        /// only for confirm_mention
        let mentionSubType: String?

        let module: DocsType
        let fileType: DocsType
        let fileId: String
        let zone: Zone
        let source: Source

        public init(mentionType: String? = nil,
             mentionSubType: String? = nil,
             module: DocsType,
             fileType: DocsType,
             fileId: String,
             zone: Zone,
             source: Source) {
            self.mentionType = mentionType
            self.mentionSubType = mentionSubType
            self.module = module
            self.fileType = fileType
            self.fileId = fileId
            self.zone = zone
            self.source = source
        }
    }
    
    public static var commonParams: [String: Any] = [:]
}

extension AtTracker {
    public class func logConfirm(with context: Context) {
        var params: [String: Any] = [:]
        params["module"] = context.module.name
        params["file_type"] = context.fileType.name
        params["file_id"] = context.fileId

        guard let type = context.mentionType, let subType = context.mentionSubType else {
            spaceAssertionFailure("参数不能为空")
            return
        }
        params["mention_type"] = type
        params["mention_sub_type"] = subType
        params["zone"] = context.zone.rawValue
        params["source"] = context.source.rawValue
        DocsTracker.log(enumEvent: .confirmMention, parameters: params)
    }

    public class func logOpen(with context: Context) {
        var params: [String: Any] = [:]
        params["module"] = context.module.name
        params["file_type"] = context.fileType.name
        params["file_id"] = context.fileId
        params["zone"] = context.zone.rawValue
        params["source"] = context.source.rawValue
        DocsTracker.log(enumEvent: .openMention, parameters: params)
    }
    
    public class func expose(parameter: [String: Any], docsInfo: DocsInfo?) {
        var params = parameter
        if let info = docsInfo {
            params["file_id"] = DocsTracker.encrypt(id: info.objToken)
            params["file_type"] = info.type.name
        }
        if let info = docsInfo {
            params.merge(baseParametera(docsInfo: info)) { (old, _) in old }
        }
        DocsTracker.newLog(event: DocsTracker.EventType.mentionPanelView.rawValue, parameters: params)
    }
    
    /// mention行为埋点。 参数
    /// `mention_type`:  user，docs，file，chat，table,bitable, sheet，vote，jira,iframe
    /// `mention_obj_id`:  对应人id，文档id，群id等其他mention可以没有id。
    /// `isSendNotice`: 【是否发送通知】布尔值
    /// `domain`： 一级区域。part_comment：侧边评论模块触发，full_comment：全文评论模块触发，text：正文模块触发
    /// `extra`: 评论业务传的公参
    public class func mentionReport(
                              type: String,
                              mentionId: String,
                              isSendNotice: Bool,
                              domain: Zone,
                              docsInfo: DocsInfo?,
                              extra: [String: Any] = [:]) {
        var parameter: [String: Any] = [:]
        parameter["click"] = "mention_confirm"
        parameter["mention_type"] = type
        parameter["mention_obj_id"] = DocsTracker.encrypt(id: mentionId)
        parameter["is_send_notice_flag"] = "\(isSendNotice)"
        // 触发区域，移动端只有正文触发传text
        parameter["domain"] = domain.rawValue
        let isWiki = docsInfo?.isFromWiki == true
        parameter["is_wiki"] = isWiki
        if isWiki {
            if let wikiInfo = docsInfo?.wikiInfo {
                parameter["wiki_token"] = wikiInfo.wikiToken
            }
        }
        if let info = docsInfo {
            parameter["file_id"] = DocsTracker.encrypt(id: info.objToken)
            parameter["file_type"] = info.type.name
        }
        if let info = docsInfo {
            parameter.merge(baseParametera(docsInfo: info)) { (old, _) in old }
        }
        if !commonParams.isEmpty {
            parameter.merge(commonParams) { (_, new) in new }
        } else {
            parameter.merge(extra) { (_, new) in new }
        }
        parameter["target"] = "none"
        DocsTracker.newLog(event: DocsTracker.EventType.mentionPanelClick.rawValue, parameters: parameter)
    }
    
    static func baseParametera(docsInfo: DocsInfo) -> [String: Any] {
        let token = docsInfo.wikiInfo?.objToken ?? docsInfo.objToken
        let (userPerm, filePerm) = permission(token: token)
        let parameter: [String: Any] = ["app_form": docsInfo.getAppForm(),
                                        "module": docsInfo.type.name,
                                        "sub_module": "none",
                                        "page_token": DocsTracker.encrypt(id: token),
                                        "user_permission": userPerm,
                                        "file_permission": filePerm,
                                        "sub_file_type": docsInfo.fileType ?? ""]
        return parameter
    }
    
    private static func permission(token: String) -> (String, String) {
        let permissonMgr = DocsContainer.shared.resolve(PermissionManager.self)!
        let userPermission = permissonMgr.getUserPermissions(for: token)?.rawValue ?? 1
        let filePermission = permissonMgr.getPublicPermissionMeta(token: token)?.rawValue ?? "0"
        return ("\(userPermission)", filePermission)
    }
}
