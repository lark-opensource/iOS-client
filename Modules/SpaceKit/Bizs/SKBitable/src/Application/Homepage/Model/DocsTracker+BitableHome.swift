//
//  DocsTracker+BitableHome.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/30.
//

import Foundation
import SKFoundation
import SKCommon
import SKInfra

extension BitableHomeScene {
    var tracker_tab_name: String {
        switch self {
        case .homepage:
            return "personal"
        case .recommend:
            return "recommend"
        default:
            return "unknown"
        }
    }
}

enum BitableHomeTrackerClickType: String {
    case personal
    case recommend
    case create_base
    case new_base_popup
    case create_base_lead
    case search
}

enum BitableHomeCreateBaseSource {
    // 底 tab 创建 base
    case create_base
    // 文件列表不为空时创建 base
    case new_base_popup
    // 文件列表为空
    case create_base_lead

    func trackerClickType() -> BitableHomeTrackerClickType {
        switch self {
        case .create_base:
            return .create_base
        case .new_base_popup:
            return .new_base_popup
        case .create_base_lead:
            return .create_base_lead
        }
    }
}

extension DocsTracker {
    private static func reportBitableHomePageEvent(enumEvent: EventType, parameters: [String: Any]?, bizParams: SpaceBizParameter) {
        var dic: [String: Any] = bizParams.params
        dic.merge(other: parameters)
        DocsTracker.newLog(enumEvent: enumEvent, parameters: dic)
    }

    static func reportBitableHomePageEvent(enumEvent: EventType, parameters: [String: Any]?, context: BaseHomeContext) {
        let bizParams = SpaceBizParameter(module: .baseHomePage(context: context))
        reportBitableHomePageEvent(enumEvent: enumEvent, parameters: parameters, bizParams: bizParams)
    }

    static func reportBitableHomePageView(context: BaseHomeContext, tab: BitableHomeScene) {
        reportBitableHomePageEvent(enumEvent: .baseHomepageLandingView, parameters: ["tab_name": tab.tracker_tab_name], context: context)
    }

    static func reportBitableHomePageClick(context: BaseHomeContext, click: BitableHomeTrackerClickType, extra: [String: Any]? = nil) {
        var params: [String: Any] = ["click": click.rawValue]
        params.merge(other: extra)
        reportBitableHomePageEvent(enumEvent: .baseHomepageLandingClick, parameters: params, context: context)
    }

    static func reportBitableHomePageRecommendView(context: BaseHomeContext) {
        reportBitableHomePageEvent(
            enumEvent: .baseHomepageNewAppear,
            parameters: ["tab_name": BitableHomeScene.recommend.tracker_tab_name],
            context: context
        )
    }
}
