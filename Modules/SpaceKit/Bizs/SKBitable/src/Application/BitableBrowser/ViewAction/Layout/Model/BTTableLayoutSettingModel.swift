//
//  BTGridLayoutSettingModel.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/10.
//

import Foundation

// MARK: - data model

struct BTTableLayoutSettingContext: Codable {
    let baseId: String
    let tableId: String
    let viewId: String
    let action: String
    let callback: String
}

extension BTTableLayoutSettingContext {
    func isSameViewContext(with another: BTTableLayoutSettingContext) -> Bool {
        baseId == another.baseId && tableId == another.tableId && viewId == another.viewId
    }
}

struct BTTableLayoutSettings: Codable {
    enum ViewType: Int, Codable {
        /// 传统表格样式
        case classic = 1
        /// 卡片样式
        case card = 2
    }
    
    enum ColumnType: Int, Codable {
        /// 每行 1 列
        case one = 1
        /// 每行 2 列
        case two = 2
        /// 每行 3 列
        case three = 3
    }
    
    /// 视图样式类型
    var gridViewLayoutType: ViewType
    
    /// 卡片视图配置：每行展示列数
    var columnCount: Int?
    /// 卡片视图配置：是否展示封面（一期不支持）
    // var showCover: Bool?
    /// 卡片视图配置：展示字段 ID 列表
    var visibleFieldIds: [String]?
    /// 卡片视图配置：封面字段 ID
    var coverFieldId: String?
    /// 卡片视图配置：标题字段 ID
    var titleFieldId: String?
    /// 卡片视图配置：副标题字段 ID
    var subtitleFieldId: String?
    /// 默认空白的settings
    static var emptySetting: BTTableLayoutSettings {
        return BTTableLayoutSettings(gridViewLayoutType: .classic,
                                     columnCount: nil,
                                     visibleFieldIds: nil,
                                     coverFieldId: nil,
                                     titleFieldId: nil,
                                     subtitleFieldId: nil)
    }
}

