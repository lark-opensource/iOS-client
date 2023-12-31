//
//  SKCreateTracker.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/24.
//  

import Foundation
import LarkLocalizations
import SKFoundation
import SpaceInterface

public final class SKCreateTracker {
    public static let sourceKey = "source"
    public enum TemplateCenterSource: String {
        case templatecenterBanner = "templatecenter_banner" // 从 banner 合辑创建
        case templatecenterSearchresult = "templatecenter_searchresult" // 从搜索结果创建
        case templatecenterNormalcreate = "templatecenter_normalcreate" // 进入就直接点击创建了
        case fromSet = "from_set" // 场景化模版
    }
    /// 文档创建统计(create_new_objs)
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - token: 文档id
    ///   - moduleInfo: 创建时候所在的模块信息
    ///   - templateInfos: 模板创建文档时额外添加的参数，目前用来传加密token，为了不让离线创建模块感知，加个dict
    ///   - extra: 目前用来给模板中心创建的时候，传入分类的id和分类名称
    public static func reportCreateNewObj(type: DocsType,
                                          token: String,
                                          source: FromSource? = nil,
                                          parentToken: String? = nil,
                                          templateCenterSource: TemplateCenterSource? = nil,
                                          error: Error? = nil,
                                          moduleInfo: [String: Any]? = nil,
                                          templateInfos: [String: Any]? = nil,
                                          extra: [String: Any]? = nil) {
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyyMMdd"
        let createDate = formatter.string(from: date)
        var params: [String: Any] = [String: Any]()
        params["file_type"] = type.name
        params["is_owner"] = "true"
        params["create_time"] = Int(date.timeIntervalSince1970)
        params["create_date"] = createDate
        params["from_create_date"] = 0
        params["network_status"] = DocsNetStateMonitor.shared.isReachable ? "online" : "offline"
        params[Self.sourceKey] = source?.rawValue ?? ""
        params["create_file_type"] = type.name
        if let userId = User.current.info?.userID {
            params["create_uid"] = DocsTracker.encrypt(id: userId)
        }
        params["create_source"] = "click_btn"
        params["file_id"] = DocsTracker.encrypt(id: token)
        params["status_name"] = (error == nil) ? "success" : "fail"
        params["product"] = DocsSDK.isInLarkDocsApp ? "spur" : "suite"
        
        if let infos = moduleInfo {
            for (key, value) in infos {
                params.updateValue(value, forKey: key)
            }
        }
        if let source = source, source == .templateCenter {
            if let centerSource = templateCenterSource {
                params["templatecenter_source"] = centerSource.rawValue
            } else {
                // https://bytedance.feishu.cn/docs/doccnCyojrP8qh4yiBpqT8pLjPg#
                spaceAssert(false, "这个source要传，如果新增了业务场景，让PM补上")
            }
        }

        if let templateDict = templateInfos, !templateDict.isEmpty {
            for (key, value) in templateDict {
                params.updateValue(value, forKey: key)
            }
        }
        
        if let extraInfo = extra {
            extraInfo.forEach { (key, value) in
                params[key] = value
            }
        }

        params["module"] = SKCreateTracker.moduleString
        if let id = parentToken {
            params["src_obj_id"] = id
        } else if let id = SKCreateTracker.srcFolderID {
            params["src_obj_id"] = id
        }

        DocsTracker.log(enumEvent: .createNewObject, parameters: params)
    }

    /// 点击模板，一级分类
    public static func reportClickTemplatePrimaryTab(type: String) {
        var params: [String: Any] = [String: Any]()
        params["type"] = type
        params["lang"] = LanguageManager.currentLanguage.languageCode
        DocsTracker.log(enumEvent: .clickTemplatePrimaryTab, parameters: params)
    }

    /// 点击模板，二级分类过滤
    public static func reportClickTemplateSecondaryFilter(primaryType: String, categoryId: String) {
        var params: [String: Any] = [String: Any]()
        params["primary"] = primaryType
        params["type"] = categoryId
        params["lang"] = LanguageManager.currentLanguage.languageCode
        DocsTracker.log(enumEvent: .clickTemplateSecondaryFilter, parameters: params)
    }
}

extension SKCreateTracker {
    public static var moduleString: String = "recent"
    public static var srcModuleString: String = "home"
    public static var subModuleString: String = ""
    public static var srcFolderID: String?
}
