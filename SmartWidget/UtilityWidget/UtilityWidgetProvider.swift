//
//  UtilityWidgetProvider.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/4/7.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import LarkWidget
import LarkLocalizations
import LarkExtensionServices

struct UtilityWidgetProvider: IntentTimelineProvider {

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .normalInfo(isFeishu: true))
    private var authInfo: WidgetAuthInfo

    @UserDefaultEncoded(key: WidgetDataKeys.utilityData, default: .defaultData)
    private var utilityWidgetData: UtilityWidgetModel

    func placeholder(in context: Context) -> UtilityEntry {
        return UtilityEntry(date: Date(),
                            configuration: LarkUtilityConfigurationIntent(),
                            authInfo: .normalInfo(isFeishu: true),
                            data: .defaultData)
    }

    func getSnapshot(for configuration: LarkUtilityConfigurationIntent, in context: Context, completion: @escaping (UtilityEntry) -> Void) {
        let entry = UtilityEntry(date: Date(),
                                 configuration: configuration,
                                 authInfo: .normalInfo(isFeishu: true),
                                 data: .defaultData)
        completion(entry)
    }

    func getTimeline(for configuration: LarkUtilityConfigurationIntent, in context: Context, completion: @escaping (Timeline<UtilityEntry>) -> Void) {

        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)

        let entry = UtilityEntry(date: Date(),
                                 configuration: configuration,
                                 authInfo: authInfo,
                                 data: utilityWidgetData)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
        // 常用工具 Widget 展示埋点
        let addedTools = entry.addedTools
        let params: [String: Any] = [
            "product_line": "tools",
            "size": context.family.trackName,
            "tools_cnt": addedTools.count,
            "tool_name": addedTools.compactMap({ $0.trackName }).joined(separator: ",")
        ]
        ExtensionTracker.shared.trackTeaEvent(key: "public_widget_view", params: params)
    }
}

struct UtilityEntry: TimelineEntry {
    let date: Date
    let configuration: LarkUtilityConfigurationIntent
    let authInfo: WidgetAuthInfo
    let data: UtilityWidgetModel

    var addedTools: [UtilityTool] {
        return configuration.availableTools?.compactMap {
            $0.toUtilityTool()
        } ?? []
    }
}

// MARK: - Model Convertion

public extension INUtilityTool {
    func toUtilityTool() -> UtilityTool? {
        guard let name = name, let appLink = appLink else {
            return nil
        }
        return UtilityTool(name: name,
                           iconKey: iconKey ?? "",
                           colorKey: colorKey ?? "",
                           resourceKey: resourceKey ?? "",
                           appLink: appLink,
                           key: key)
    }
}
