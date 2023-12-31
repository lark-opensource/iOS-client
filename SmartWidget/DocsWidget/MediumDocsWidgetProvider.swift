//
//  MediumDocsWidgetProvider.swift
//  Lark
//
//  Created by Hayden Wang on 2022/8/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import Intents
import LarkHTTP
import WidgetKit
import LarkWidget
import LarkLocalizations
import LarkExtensionServices

struct MediumDocsWidgetProvider: IntentTimelineProvider {

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .normalInfo(isFeishu: true))
    private var authInfo: WidgetAuthInfo

    @UserDefaultEncoded(key: WidgetDataKeys.docsWidgetConfig, default: .default)
    private var docsWidgetConfig: DocsWidgetConfig

    func placeholder(in context: Context) -> MediumDocsEntry {
        return MediumDocsEntry(date: Date(),
                               configuration: MediumDocsConfigurationIntent(),
                               authInfo: .normalInfo(isFeishu: true),
                               data: .placeholderData)
    }

    func getSnapshot(for configuration: MediumDocsConfigurationIntent, in context: Context, completion: @escaping (MediumDocsEntry) -> Void) {
        let type = DocsListType.pin
        DocsWidgetNetworking.requestDocsList(ofType: type, nums: 3) { docItems, _ in
            let entry = MediumDocsEntry(date: Date(),
                                        configuration: configuration,
                                        authInfo: authInfo,
                                        data: MediumDocsWidgetModel(type: type, items: docItems ?? []))
            completion(entry)
        }
    }

    func getTimeline(for configuration: MediumDocsConfigurationIntent, in context: Context, completion: @escaping (Timeline<MediumDocsEntry>) -> Void) {

        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)

        let authInfo = authInfo
        let type = configuration.listType.toDocsListType

        guard authInfo.isLogin, !authInfo.isMinimumMode else {
            let entry = MediumDocsEntry(date: Date(),
                                        configuration: configuration,
                                        authInfo: authInfo,
                                        data: MediumDocsWidgetModel(type: type, items: []))
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }

        // 请求文档列表
        DocsWidgetNetworking.requestDocsList(ofType: type, nums: 3) { docItems, _ in
            // 请求成功显示文档，请求失败显示空列表
            let entry = MediumDocsEntry(date: Date(),
                                        configuration: configuration,
                                        authInfo: authInfo,
                                        data: MediumDocsWidgetModel(type: type, items: docItems ?? []))
            let timeline = Timeline(entries: [entry], policy: .after(nextRefreshTime))
            completion(timeline)
        }

        // 飞书文档 Widget 展示埋点
        let params: [String: Any] = [
            "product_line": "doc",
            "size": context.family.trackName
        ]
        ExtensionTracker.shared.trackTeaEvent(key: "public_widget_view", params: params)
    }

    private var nextRefreshTime: Date {
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 9, currentHour <= 21 {
            // 如果是 9-21 点，每小时刷新一次
            return Date().addingTimeInterval(60 * 60)
        } else {
            // 其他时间 4 小时刷新一次
            return Date().addingTimeInterval(4 * 60 * 60)
        }
    }
}

struct MediumDocsEntry: TimelineEntry {
    let date: Date
    let configuration: MediumDocsConfigurationIntent
    let authInfo: WidgetAuthInfo
    let data: MediumDocsWidgetModel
}

extension INDocsListType {

    var toDocsListType: DocsListType {
        switch self.rawValue {
        case 1:     return .pin
        case 2:     return .star
        case 3:     return .recent
        default:    return .recent
        }
    }
}
