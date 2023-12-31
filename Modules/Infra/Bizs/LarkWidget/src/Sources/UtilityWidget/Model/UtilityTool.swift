//
//  UtilityTool.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/4/7.
//

import Foundation
import SwiftUI

public struct UtilityTool: Codable, Equatable {

    public var key: String?
    public var name: String
    public var iconKey: String
    public var colorKey: String
    public var resourceKey: String
    public var appLink: String

    public init(name: String,
                iconKey: String,
                colorKey: String,
                resourceKey: String,
                appLink: String,
                key: String? = nil) {
        self.name = name
        self.iconKey = iconKey
        self.colorKey = colorKey
        self.resourceKey = resourceKey
        self.appLink = appLink
        self.key = key
    }

    /// 判断该数据是否合法
    public var isValid: Bool {
        // 姓名不能为空
        guard !name.isEmpty else { return false }
        // AppLink 不能为空
        guard !appLink.isEmpty else { return false }
        // iconKey + colorKey 和 resourceKey 必存在其一
        // guard (!iconKey.isEmpty && !colorKey.isEmpty) || !resourceKey.isEmpty else { return false }
        return true
    }

    public var identifier: String {
        key ?? appLink
    }

    @available(iOS 13.0, *)
    var backgroundColors: [Color] {
        switch colorKey {
        case "widget_token_orange_100": return [WidgetColor.Icon.orange]
        case "widget_token_yellow": return [WidgetColor.Icon.yellow]
        case "widget_token_green": return [WidgetColor.Icon.green]
        case "widget_token_blue_400": return [WidgetColor.Icon.turquoise]
        case "widget_token_blue_100": return [WidgetColor.Icon.wathet]
        case "widget_token_blue_200": return [WidgetColor.Icon.blue]
        case "widget_token_blue_300": return [WidgetColor.Icon.blue]
        case "widget_token_purple_100": return [WidgetColor.Icon.purple]
        case "widget_token_pink": return [WidgetColor.Icon.carmine]
        default:
            let colors = WidgetColor.Icon.allColors
            var index = colorKey.hash % colors.count
            if index < 0 {
                index = (index + colors.count) % colors.count
            }
            return [colors[index]]
        }
    }

    public var trackName: String {
        key ?? name
    }
}

extension UtilityTool {

    public static var search: UtilityTool {
        UtilityTool(
            name: BundleI18n.LarkWidget.Lark_Widget_Search,
            iconKey: "search_outlined",
            colorKey: "widget_token_green",
            resourceKey: "",
            appLink: "lark://\(WidgetLink.applinkHost)/client/search/open",
            key: "search"
        )
    }

    public static var scan: UtilityTool {
        UtilityTool(
            name: BundleI18n.LarkWidget.Lark_Widget_ScanCode,
            iconKey: "scan_outlined",
            colorKey: "widget_token_blue_100",
            resourceKey: "",
            appLink: "lark://\(WidgetLink.applinkHost)/client/qrcode/main",
            key: "scan"
        )
    }

    public static var workplace = UtilityTool(
        name: BundleI18n.LarkWidget.Lark_Legacy_AppCenter,
        iconKey: "tab_app_filled",
        colorKey: "widget_token_blue_400",
        resourceKey: "",
        appLink: "lark://\(WidgetLink.applinkHost)/client/workplace/open",
        key: "workspace"
    )
}
