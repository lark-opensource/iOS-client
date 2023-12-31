//
//  AssociateAppTracker.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/12/6.
//

import Foundation
import SKFoundation
import SpaceInterface
import LarkDocsIcon

public enum AssociateAppShowType: String {
    case addDocs = "add_docs"
    case viewDocs = "view_docs"
}

public enum AssociateAppPluginClickType: String {
    // 点击新建关联文档入口
    case clickCreateDocsEntrance = "click_create_docs_entrance"
    // 点击关联已有文档入口
    case clickRelationDocsEntrance = "click_relation_docs_entrance"
    // 点击查看文档入口
    case clickViewDocsEntrance = "click_view_docs_entrance"
    // 点击解除关联文档入口
    case clickUnbindDocsEntrance = "click_unbind_docs_entrance" //1
    // 成功新建关联文档
    case successCreateDocs = "success_create_docs"
    // 成功关联已有文档
    case successRelationDocs = "success_relation_docs"
    // 成功解除关联文档
    case successUnbindDocs = "success_unbind_docs"
}

public class AssociateAppTracker {
    //    应用关联文档插件曝光
    //    plugin_type 插件类型 docs：文档插件
    //    show_type 展示的状态类型 "add_docs：添加文档 view_docs：查看文档"
    //    url_id 一事一档中「事」的唯一 id，对应 url_meta表中的 id
    //    biz_type 页面所属业务 网页和网页应用:取'${domain}${firstlevelpath}'
    //    obj_file_id 关联的file_id（即加密云文档 token）
    //    obj_file_type 关联的file_type docx:docx文档
    //    obj_file_permission_type "仅在show_type = view_docs（查看文档）时上报 have_permission：有权限 no_permission：无权限"
    
    public static func reportShowTypeTrackerEvent(showType: AssociateAppShowType,
                                                  referenceModel: AssociateAppModel.ReferencesModel?,
                                                  webUrl: URL?,
                                                  urlId: Int?) {
        var params: [String: Any] = ["plugin_type": "docs",
                                     "show_type": showType.rawValue]
        
        if let url = referenceModel?.url, let docsUrl = URL(string: url) {
            let docInfo = DocsUrlUtil.getFileInfoNewFrom(docsUrl)
            if let docsToken = docInfo.token {
                params["obj_file_id"] = DocsTracker.encrypt(id: docsToken)
            }
            if let docsType = docInfo.type {
                params["obj_file_type"] = docsType.fileTypeForSta
            }
            
        }
        
        if let webUrl, let bizType = self.getBizType(webUrl) {
            params["biz_type"] = bizType
        }
        if let urlId {
            params["url_id"] = "\(urlId)"
        }
        DocsTracker.newLog(enumEvent: .applicationDocsPluginView, parameters: params)
    }
    
    //    应用关联文档插件点击
    //    target    string    跳转目标页面
    //    plugin_type    string    插件类型
    //    show_type    string    展示的状态类型
    //    url_id    string    一事一档中「事」的唯一 id，对应 url_meta表中的 id
    //    biz_type    string    页面所属业务
    //    obj_file_id    string    关联的file_id（即加密云文档 token）
    //    obj_file_type    string    "关联的file_type docx：docx 文档"
    public static func reportPluginClickTrackerEvent(clickType: AssociateAppPluginClickType,
                                                     showType: AssociateAppShowType,
                                                     referenceModel: AssociateAppModel.ReferencesModel?,
                                                     webUrl: URL?,
                                                     urlId: Int?) {
        var docInfo: (token: String?, type: CCMDocsType?)?
        if let url = referenceModel?.url, let docsUrl = URL(string: url) {
            docInfo = DocsUrlUtil.getFileInfoNewFrom(docsUrl)
        }
        
        self.reportPluginClickTrackerEvent(clickType: clickType,
                                           showType: showType,
                                           docsToken: docInfo?.token,
                                           docsType: docInfo?.type,
                                           webUrl: webUrl,
                                           urlId: urlId)
        
    }
    
    public static func reportPluginClickTrackerEvent(clickType: AssociateAppPluginClickType,
                                                     showType: AssociateAppShowType,
                                                     docsToken: String?,
                                                     docsType: DocsType?,
                                                     webUrl: URL?,
                                                     urlId: Int?) {
        
        var params: [String: Any] = ["plugin_type": "docs",
                                     "show_type": showType.rawValue,
                                     "click": clickType.rawValue]
        
        if clickType == .clickCreateDocsEntrance || clickType == .clickViewDocsEntrance {
            params["target"] = "ccm_docs_page_view"
        } else {
            params["target"] = "none"
        }
        
        if let docsToken {
            params["obj_file_id"] = DocsTracker.encrypt(id: docsToken)
        }
        if let docsType {
            params["obj_file_type"] = docsType.fileTypeForSta
        }
        
        if let webUrl, let bizType = self.getBizType(webUrl) {
            params["biz_type"] = bizType
        }
        if let urlId {
            params["url_id"] = "\(urlId)"
        }
        DocsTracker.newLog(enumEvent: .applicationDocsPluginClick, parameters: params)
    }
    
    //    docContentPageClick 点击文档关联事项
    //    target    string    跳转目标页面 click_docs_relation_application
    public static func reportDocContentClickTrackerEvent(webUrl: URL?, urlId: Int?) {
        var params: [String: Any] = ["click": "click_docs_relation_application", "target": "none"]
        if let webUrl, let bizType = self.getBizType(webUrl) {
            params["biz_type"] = bizType
        }
        if let urlId {
            params["url_id"] = "\(urlId)"
        }
        DocsTracker.newLog(enumEvent: .docContentPageClick, parameters: params)
    }
    
    private static func getBizType(_ url: URL) -> String? {
        if let host = url.host, let hostURL = URL(string: host) {
            var bizTypeURL = hostURL
            let pathComponents = url.pathComponents.prefix(2)
            pathComponents.forEach { bizTypeURL = bizTypeURL.appendingPathComponent($0) }
            let bizTypeStr = bizTypeURL.absoluteString
            return bizTypeStr
        }
        return nil
    }
    
}
