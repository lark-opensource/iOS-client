//
//  BlockTypeUtils.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/9/17.
//

import Foundation

struct BlockTypeUtil {
    static let FALLBACK = "FALLBACK" // 兜底block占位
    static let CHART = "CHART" // 图表Block
    static let DASHBOARD = "DASHBOARD" // 仪表盘Block
    static let BITABLE_TABLE = "BITABLE_TABLE" // 多维表格 Table Block
    static let PIVOT_TABLE = "PIVOT_TABLE" // 透视表 Block
    static let LINKED_DOCX = "LINKED_DOCX"
}

struct ViewTypeUtil {
    static let GRID = "grid"
    static let KANBAN = "kanban"
    static let GANTT = "gantt"
    static let GALLERY = "gallery"
    static let FORM = "form"
    static let CUSTOMIZED_VIEW = "customized_view"

    static func showCatalogDivider(viewType: String?) -> Bool {
        switch viewType {
        case KANBAN, GALLERY, FORM, GANTT:
            return true
        default:
            return false
        }
    }

    static func getDefaultViewType() -> String {
        return GRID
    }

    static func isForm(viewType: String?) -> Bool {
        return viewType == FORM
    }

    static func isKanban(viewType: String?) -> Bool {
        return viewType == KANBAN
    }

    static func isCustomizedView(viewType: String?) -> Bool {
        return viewType == CUSTOMIZED_VIEW
    }
}
