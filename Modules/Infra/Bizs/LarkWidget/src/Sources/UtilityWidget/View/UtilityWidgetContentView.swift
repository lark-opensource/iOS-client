//
//  UtilityWidgetContentView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/4/7.
//

import Foundation
import UIKit
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct UtilityWidgetContentView: View {

    /// 用户登录 / MG信息
    var authInfo: WidgetAuthInfo

    /// 用户配置的工具列表
    var addedTools: [UtilityTool]

    public init(authInfo: WidgetAuthInfo, data: UtilityWidgetModel, addedTools: [UtilityTool]) {
        // 使用最新的数据，更新保存的 Tools，解决切换语言或者权限变化后，Widget 不变的问题。
        self.authInfo = authInfo
        let dictionary = data.toolDictionary
        self.addedTools = addedTools.compactMap { dictionary[$0.identifier] }
    }

    public var body: some View {
        VStack(alignment: .leading) {
            // “常用工具” 标题，在只有 1 行工具的情况下展示
            if addedTools.count <= itemsPerRow {
                HStack(spacing: 9) {
                    AppIconView()
                    Text(BundleI18n.LarkWidget.Lark_Widget_OftenUsedFunctions_Title)
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
            }

            Spacer(minLength: 0)

            LazyVGrid(columns: itemsLayout, spacing: 8) {
                ForEach(0..<numberOfTools) { index in
                    UtilityToolView(
                        tool: addedTools[index],
                        isCompact: useCompactLayout,
                        index: index
                    )
                }
                // 常用工具少于 4 个时，显示“长按自定义”
                if addedTools.count < itemsPerRow {
                    UtilityToolView.addNew(appLink: guideLink, toolsNumber: addedTools.count)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .widgetBackground(WidgetColor.background)
    }

    private var itemsPerRow: Int = 4

    private var itemsLayout: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: itemsPerRow)
    }

    private var useCompactLayout: Bool {
        addedTools.count > itemsPerRow
    }

    private var numberOfTools: Int {
        min(8, addedTools.count)
    }

    /// Widget 使用指南网页的 AppLink
    /// https://bytedance.feishu.cn/wiki/wikcniZkCyirWkomz4PTIof2EPd?sheet=w50AYz&table=tblLCOHnLsXmYGUY&view=vewNsC7jX5
    private var guideLink: String {
        WidgetLink.widgetHelpCenter(isFeishu: authInfo.isFeishuBrand)
    }
}

// MARK: - Item View

@available(iOS 14.0, *)
struct UtilityToolView: View {

    @Environment(\.widgetFamily) var family

    var title: String
    var iconKey: String
    var colors: [Color]
    var resourceKey: String
    var url: String
    var isCompact: Bool
    var isPlaceholder: Bool
    var index: Int
    var trackName: String

    init(title: String,
         iconKey: String,
         colors: [Color],
         resourceKey: String,
         url: String,
         isCompact: Bool = false,
         isPlaceholder: Bool = false,
         index: Int = 0,
         trackName: String = "") {
        self.title = title
        self.colors = colors
        self.iconKey = iconKey
        self.resourceKey = resourceKey
        self.url = url
        self.isCompact = isCompact
        self.isPlaceholder = isPlaceholder
        self.index = index
        self.trackName = trackName
    }

    init(title: String,
         iconKey: String,
         color: Color,
         resourceKey: String,
         url: String,
         isCompact: Bool = false,
         isPlaceholder: Bool = false,
         index: Int = 0,
         trackName: String = "") {
        self.init(
            title: title,
            iconKey: iconKey,
            colors: [color],
            resourceKey: resourceKey,
            url: url,
            isCompact: isCompact,
            isPlaceholder: isPlaceholder,
            index: index,
            trackName: trackName
        )
    }

    init(tool: UtilityTool,
         isCompact: Bool = false,
         index: Int = 0) {
        self.init(
            title: tool.name,
            iconKey: tool.iconKey,
            colors: tool.backgroundColors,
            resourceKey: tool.resourceKey,
            url: tool.appLink,
            isCompact: isCompact,
            index: index,
            trackName: tool.trackName
        )
    }

    var body: some View {
        if let url = linkURL {
            Link(destination: url) {
                contentView
            }
        } else {
            contentView
        }
    }

    var iconImage: UIImage {
        var image: UIImage?
        if !resourceKey.isEmpty {
            image = UIImage(named: resourceKey)
        } else if !iconKey.isEmpty {
            image = UIImage(named: "tool_\(iconKey)")
        }
        return image ?? UIImage(named: "default_utility_icon") ?? UIImage()
    }

    /// 加入了埋点信息的 AppLink，埋点在主 App 中解析处理
    var linkURL: URL? {
        return WidgetTrackingTool.createURL(url, trackParams: [
            "click": "tool_click",
            "target": "none",
            "tool_name": trackName,
            "tool_order": index + 1
        ])
    }

    var contentView: some View {
        VStack(spacing: 4) {
            if !isCompact {
                Spacer()
                    .frame(height: singleLineHeight)
            }
            // 图标
            ZStack {
                if isPlaceholder {
                    // 图标背景
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(Squircle())
                    // 图标边框
                    Squircle()
                        .fill(.clear, strokeBorder: WidgetColor.secondaryText, lineWidth: 0.2)
                        .frame(width: iconSize, height: iconSize)
                    // 图标 Icon
                    Image(iconKey)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(WidgetColor.placeholder)
                        .frame(width: imageSize, height: imageSize)
                } else {
                    // 图标（这里用 UIImage 转换，因为 SwiftUI Image 无法判断资源是否存在，因此无法用默认图标）
                    Image(uiImage: iconImage)
                        .resizable()
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(Squircle())
                }
            }
            // 文字
            Text(title)
                .udFont(12, lineHeight: singleLineHeight)
                .foregroundColor(WidgetColor.text)
                .lineLimit(numberOfLines)
                .multilineTextAlignment(.center)
                .frame(height: CGFloat(numberOfLines) * singleLineHeight, alignment: .top)
        }
    }

    private var singleLineHeight: CGFloat { 18 }

    private var numberOfLines: Int { isCompact ? 1 : 2 }

    private var iconSize: CGFloat { isCompact ? 36 : 40 }

    private var imageSize: CGFloat { isCompact ? 21 : 24 }

    static func addNew(appLink: String, toolsNumber: Int) -> UtilityToolView {
        UtilityToolView(
            title: BundleI18n.LarkWidget.Lark_Widget_iOS_LongPressToCustomize_Button,
            iconKey: "add_middle_outlined",
            color: Color(UIColor.secondarySystemBackground),
            resourceKey: "",
            url: appLink,
            isCompact: false,
            isPlaceholder: true,
            index: toolsNumber,
            trackName: "addnew"
        )
    }
}

// swiftlint:disable all
@available(iOS 14.0, *)
struct UtilityWidgetContentView_Previews: PreviewProvider {
    static var previews: some View {
        UtilityWidgetContentView(authInfo: .normalInfo(isFeishu: true), data: .defaultData, addedTools: [.search, .scan, .workplace])
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
// swiftlint:enable all
