//
//  MediumDocsWidgetModel.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/15.
//

import Foundation

public struct MediumDocsWidgetModel: Codable, Equatable {

    public var listType: DocsListType
    public var docItems: [DocItem]

    public init(type: DocsListType,
                items: [DocItem]) {
        self.listType = type
        self.docItems = items
    }

    public var isEmpty: Bool {
        return docItems.isEmpty
    }
}

extension MediumDocsWidgetModel {

    public static var defaultData: MediumDocsWidgetModel {
        return MediumDocsWidgetModel(
            type: .pin,
            items: []
        )
    }

    public static var placeholderData: MediumDocsWidgetModel {
        return MediumDocsWidgetModel(
            type: .recent,
            items: [
                DocItem(token: "xxx", title: "XXXXXXXXXXXXXXX", type: 1, url: "xxx", activityTime: 0),
                DocItem(token: "xxx", title: "XXXXXXXXX", type: 1, url: "xxx", activityTime: 0),
                DocItem(token: "xxx", title: "XXXXXXXXXXXXXXXXXXXXXXX", type: 1, url: "xxx", activityTime: 0)
            ]
        )
    }
}

public enum DocsListType: Int, Codable {
    // “快速访问”文档列表
    case pin = 1
    // “收藏”文档列表
    case star = 2
    // “最近”文档列表
    case recent = 3

    var name: String {
        switch self {
        case .pin:      return BundleI18n.LarkWidget.Lark_DocsWidget_QuickAccess_Category
        case .star:     return BundleI18n.LarkWidget.Lark_DocsWidget_Favorites_Category
        case .recent:   return BundleI18n.LarkWidget.Lark_DocsWidget_Recents_Category
        }
    }
}
