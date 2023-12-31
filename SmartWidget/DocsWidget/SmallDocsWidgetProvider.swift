//
//  SmallDocsWidgetProvider.swift
//  SmartWidgetExtension
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

struct SmallDocsWidgetProvider: IntentTimelineProvider {

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .normalInfo(isFeishu: true))
    private var authInfo: WidgetAuthInfo

    @UserDefaultEncoded(key: WidgetDataKeys.docsWidgetConfig, default: .default)
    private var docsWidgetConfig: DocsWidgetConfig

    func placeholder(in context: Context) -> SmallDocsEntry {
        let placeholderDocItem = DocItem(token: "XX", title: "XXXXXXXXXXXXXXXX", type: 2, url: "XX")
        return SmallDocsEntry(date: Date(),
                              configuration: SmallDocsConfigurationIntent(),
                              authInfo: .normalInfo(isFeishu: true),
                              selectedDoc: placeholderDocItem,
                              image: nil)
    }

    func getSnapshot(for configuration: SmallDocsConfigurationIntent, in context: Context, completion: @escaping (SmallDocsEntry) -> Void) {
        let entry = SmallDocsEntry(date: Date(),
                                   configuration: configuration,
                                   authInfo: .normalInfo(isFeishu: true),
                                   selectedDoc: nil,
                                   image: nil)
        completion(entry)
    }

    func getTimeline(for configuration: SmallDocsConfigurationIntent, in context: Context, completion: @escaping (Timeline<SmallDocsEntry>) -> Void) {

        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)

        let authInfo = authInfo

        if let selectedDoc = configuration.selectedDocItem?.toDocItem() {
            // 有选中文档，先尝试更新文档信息
            DocsWidgetNetworking.updateDocInfo(selectedDoc) { updatedDoc, _ in
                let doc = updatedDoc ?? selectedDoc
                // 尝试下载文档背景图（如有）
                DocsWidgetNetworking.downloadCoverImage(for: doc) { image, _ in
                    let entry = SmallDocsEntry(date: Date(),
                                               configuration: configuration,
                                               authInfo: authInfo,
                                               selectedDoc: updatedDoc,
                                               image: image)
                    let timeline = Timeline(entries: [entry], policy: .after(nextRefreshTime))
                    completion(timeline)
                }
            }
        } else {
            // 未选中文档
            let entry = SmallDocsEntry(date: Date(),
                                       configuration: configuration,
                                       authInfo: authInfo,
                                       selectedDoc: nil, image: nil)
            let timeline = Timeline(entries: [entry], policy: .never)
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
            // 如果是 9-21 点，每 2 小时刷新一次
            return Date().addingTimeInterval(2 * 60 * 60)
        } else {
            // 其他时间 6 小时刷新一次
            return Date().addingTimeInterval(6 * 60 * 60)
        }
    }
}

struct SmallDocsEntry: TimelineEntry {
    let date: Date
    let configuration: SmallDocsConfigurationIntent
    let authInfo: WidgetAuthInfo
    let selectedDoc: DocItem?
    let image: UIImage?
}

extension INDocItem {
    func toDocItem() -> DocItem? {
        guard let token = token, let type = type, let url = url else {
            return nil
        }
        var item = DocItem(
            token: token,
            title: title ?? "",
            type: Int(truncating: type),
            url: url
        )
        if let subType = subType {
            item.extra = DocItemExtra(subType: Int(truncating: subType))
        }
        return item
    }
}
