//
//  TodayWidgetAction.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/7.
//

import Foundation

/// Widget Action 的数据model
public struct TodayWidgetAction: Codable, Hashable, Equatable {
    public var name: String
    public var appLink: String
    public var iconUrl: String

    public init(name: String,
                appLink: String,
                iconUrl: String) {
        self.name = name
        self.appLink = appLink
        self.iconUrl = iconUrl
    }
}

extension TodayWidgetAction {

    /// 搜索
    public static var searchAction: TodayWidgetAction {
        TodayWidgetAction(name: BundleI18n.LarkWidget.Lark_Legacy_Search,
                          appLink: WidgetLink.searchMain,
                          iconUrl: "widget_search")
    }
    /// 扫一扫
    public static var scanAction: TodayWidgetAction {
        TodayWidgetAction(name: BundleI18n.LarkWidget.Lark_ASL_SmartWidgetScan,
                          appLink: WidgetLink.qrcodeMain,
                          iconUrl: "widget_scan")
    }
    /// 工作台
    public static var workplaceMainAction: TodayWidgetAction {
        TodayWidgetAction(name: BundleI18n.LarkWidget.Lark_Legacy_AppCenter,
                          appLink: WidgetLink.workplaceMain,
                          iconUrl: "widget_appcenter")
    }
    /// 创建文档
    public static var createDocAction: TodayWidgetAction {
        TodayWidgetAction(name: BundleI18n.LarkWidget.Lark_ASL_SamrtWidgetCreateDocs,
                          appLink: WidgetLink.createDoc,
                          iconUrl: "widget_create_doc")
    }

    public static var defaultActions: [TodayWidgetAction] {
        [.searchAction, .scanAction, .workplaceMainAction]
    }
}
