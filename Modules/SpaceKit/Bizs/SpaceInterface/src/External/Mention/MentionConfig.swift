//
//  MentionConfig.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/26.
//  

import UIKit

public struct MentionInfo {

    public let token: String
    public let icon: URL?
    public let name: String
    public let detail: String
    // 预留的扩展字段
    public var extra: [AnyHashable: Any]?

    public init(token: String,
                icon: URL?,
                name: String,
                detail: String,
                extra: [AnyHashable: Any]? = nil) {
        self.token = token
        self.icon = icon
        self.name = name
        self.detail = detail
        self.extra = extra
    }
}

public typealias MentionInfoCallback = ([MentionInfo]) -> Void
public struct MentionCard {

    // 对应类型下面的小 icon
    public let image: UIImage?
    // 点击态，为空时等于 image 属性
    public let selectedImage: UIImage?
    // 面板顶部的提示语
    public var headerTips: String = "你可能想提及的"
    // 没有搜索结果的提示语
    public var emptyTips: String = "没有搜索结果"
    // 搜索的类型
    public var searchType: [String] = []

    // ⬆️ 可选
    // ⬇️ 必传

    // 展示这个列表的网络请求。请求完成后包装成 Mention 的 model list
    public let onSearch: (String, [String], @escaping MentionInfoCallback) -> Void

    public init(image: UIImage? = nil,
                selectedImage: UIImage? = nil,
                headerTips: String = "你可能想提及的",
                emptyTips: String = "没有搜索结果",
                searchType: [String] = [],
                onSearch: @escaping (String, [String], @escaping MentionInfoCallback) -> Void) {
        self.image = image
        self.selectedImage = selectedImage
        self.headerTips = headerTips
        self.emptyTips = emptyTips
        self.searchType = searchType
        self.onSearch = onSearch
    }

}
// 业务方配置一个 config，注入到 MentionPanel 中
// 一个 MentionPanel 可以包含多个 Page
// 一个 Page 内包含一种 Mention 列表，Page 可以左右滑动。用于分类 Mention 类型
// 一个 Mention 列表对应一个 MentionListHandler
public final class MentionConfig {
    /// 业务方传多种列表的类型。相当于 @人/文档/群组
    public let cards: [MentionCard]

    public init(cards: [MentionCard]) {
        self.cards = cards
    }
}
