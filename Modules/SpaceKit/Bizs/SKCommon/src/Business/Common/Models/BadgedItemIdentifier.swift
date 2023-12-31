//
// Created by duanxiaochen.7 on 2020/11/27.
// Affiliated with SKCommon.
//
// Description:

import Foundation

public enum BadgedItemIdentifier: String, CaseIterable {
    case none = "none"
    // sheet toolkit
    case toolkit = "oppanel"
    case toolkitOperation = "toolkitOperation"
    case toolkitStyle = "toolkitStyle"
    case freeze = "freeze"
    case filter = "filter"
    case filterColor = "filterColor"
    case filterValue = "filterValue"
    case filterCondition = "filterCondition"
    case fontColor = "fontColor"
    case backgroundColor = "bgColor"
    case borderLine = "borderLine"
    case uploadImage = "uploadImage"
    // sheet toolkit
    case sheetToolbar = "toolbar"

    // other panel
    case sharePanel = "share_panel"
    case morePanel = "more_panel"

    public func allowsDraggingUp() -> Bool {
        switch self {
        case .uploadImage:
            return false
        default:
            return true
        }
    }
}
