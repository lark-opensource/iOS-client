//
//  TriBizDataModel.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/12.
//

import Foundation
import SwiftyJSON

/// 新闻组件列表-单条业务数据
struct FeedSingleItem: Codable {
    /// 图片Url
    let imageUrl: String?
    /// 点击跳转的链接
    let url: String?
    /// 标题
    let title: String?
    /// 描述
    let description: String?
    /// 日期
    let date: String?
}

/// 新闻列表组件 - 业务请求返回
struct FeedBizModel: Codable {
    let feeds: [FeedSingleItem]
}

/// 新闻列表组件 - 多Tab数据结构
struct FeedMultiTabBizModel: Codable {
    let feeds: [FeedTabModel]
}

/// 新闻列表组件-单个Tab的数据
struct FeedTabModel: Codable {
    let id: String
    let tabName: JSON
    let list: [FeedSingleItem]
}

/// Tab模型
struct TabModel: Codable {
    let id: String
    let name: String
}
