//
//  DocsDetailInfoReport.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/22.
// swiftlint:disable cyclomatic_complexity


import UIKit
import SKFoundation


enum DocsDetailInfoReport {
    
    enum RecordViewStatus: String {
        ///正常展示，包括无阅读记录页面
        case normal = "normal"
        ///文档owner看到的无权限页面，浏览记录被隐藏
        case noOwner = "no_owner_permission"
        ///非文档owner看到的无权限页面，浏览记录被文档owner隐藏 ??
        case notOwner = "not_owner_permission"
        ///无权限页面，功能被后台管理者关闭
        case noAdmin = "no_admin_permission"
    }
    
    enum SettingViewClick: String {
        case readRecordOpen = "read_record_open"
        case readRecordClose = "read_record_close"
        case showVisitorAvatarOpen = "show_visitor_avatar_open"
        case showVisitorAvatarClose = "show_visitor_avatar_close"
        case more = "more_information"
        case record
        case basic
    }
    
    case detailView
    /// action: 0 record； 1 setting；
    case tabClick(action: Int)
    
    case recordView(status: RecordViewStatus)
    
    /// action: 0 返回； 1 下拉加载更多； 2 匿名设置
    case recordClick(action: Int)
    
    case settingView
    /// action: 0 开启； 1 关闭； 2 了解更多信息； 3: 返回阅读列表 4: 文档信息页
    case settingClick(action: SettingViewClick)
    
    var type: DocsTracker.EventType {
        switch self {
        case .detailView:
            return .spaceDocsDetailsView
        case .tabClick:
            return .docsDetailsClick
        case .recordView:
            return .docsDetailsRecordView
        case .recordClick:
            return .docsDetailsRecordClick
        case .settingView:
            return .docsDetailsSettingView
        case .settingClick:
            return .docsDetailsSettingClick
        }
    }
}

extension DocsDetailInfoReport {
    
    func report(docsInfo: DocsInfo) {
        var params: [String: Any] = [:]
        switch self {
        case .detailView:
            break
        case .tabClick(let action):
            switch action {
            case 0:
                params["click"] = "record"
                params["target"] = "ccm_space_docs_details_record_view"
            case 1:
                params["click"] = "setting"
                params["target"] = "ccm_space_docs_details_setting_view"
            case 2:
                params["click"] = " operation_records"
                params["target"] = "ccm_space_all_contents_view"
            default:
                break
            }
        case .recordView(let status):
            params["type"] = status.rawValue
        case .recordClick(let action):
            switch action {
            case 0:
                params["click"] = "basic"
                params["target"] = "ccm_space_docs_details_view"
            case 1:
                params["click"] = "more_information"
            case 2:
                params["click"] = "setting"
                params["target"] = "ccm_space_docs_details_setting_view"
            default:
                break
            }
        case .settingView:
            break
        case .settingClick(let action):
            params["click"] = action.rawValue
            if action == .record {
                params["target"] = "ccm_space_docs_details_record_view"
            } else if action == .basic {
                params["target"] = "ccm_space_docs_details_view"
            }
        }
        _report(params: params, docsInfo: docsInfo)
    }
    
    func _report(params: [String: Any], docsInfo: DocsInfo) {
        guard let module = docsInfo.type.module else { return }
        var parameters = params
        let bizParam = SpaceBizParameter(module: module,
                                         fileID: DocsTracker.encrypt(id: docsInfo.objToken),
                                         fileType: docsInfo.type,
                                         driveType: docsInfo.fileType ?? "")
        parameters.merge(other: bizParam.params)
        if Thread.isMainThread {
            DocsTracker.newLog(event: type.rawValue, parameters: parameters)
        } else {
            DispatchQueue.main.sync {
                DocsTracker.newLog(event: type.rawValue, parameters: parameters)
            }
        }
    }
}
