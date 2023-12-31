//
//  DocsTracker+BitableHome.swift
//  SKSpace
//
//  Created by 刘焱龙 on 2023/11/30.
//

import Foundation
import SKFoundation
import SKCommon

enum BitableHomeTrackerFileListSubViewType: String {
    case quick_access
    case recent
    case favorites

    static func type(index: Int) -> BitableHomeTrackerFileListSubViewType? {
        switch index {
        case 0:
            return .recent
        case 1:
            return .quick_access
        case 2:
            return .favorites
        default:
            return nil
        }
    }
}

extension DocsTracker {
    static func reportBitableHomePageFileListView(context: BaseHomeContext, type: BitableHomeTrackerFileListSubViewType, isFullScreen: Bool) {
        reportBitableHomePageEvent(
            enumEvent: .baseHomepageFilelistView,
            parameters: ["current_sub_view": type.rawValue, "is_full_screen": isFullScreen ? "true" : "false"],
            context: context)
    }

    static func reportBitableHomePageFileListClick(context: BaseHomeContext, fromIndex: Int, toIndex: Int) {
        let params: [String : Any] = [
            "current_sub_view": BitableHomeTrackerFileListSubViewType.type(index: fromIndex)?.rawValue ?? "",
            "click": BitableHomeTrackerFileListSubViewType.type(index: toIndex)?.rawValue ?? "",
            "target": ""
        ]
        reportBitableHomePageEvent(
            enumEvent: .baseHomepageFilelistClick,
            parameters: params,
            context: context)
    }
}
