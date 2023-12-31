//
//  Statistics.swift
//  SpaceKit
//
//  Created by weidong fu on 22/3/2018.
//

import SKFoundation
import SpaceInterface

extension DocsTracker {
    public class func createFile(with parent: String?, typeName: String, isSuccess: Bool, timeline: DocsTimeline) {
        DocsTracker.log(enumEvent: .clickCreateItem,
                        parameters: ["file_type": typeName,
                                     "status": isSuccess ? "success" : "fail",
                                     "cost_time": timeline.totalDuration() * 1000])
    }
    
    public static func shortcutDuplicateCheckView(stages: CreateShortcutStages) {
        var params: [String: Any] = [:]
        switch stages {
        case .hasEntity:
            params["duplicate_reason"] = "origin"
        case .hasShortcut:
            params["duplicate_reason"] = "shortcut"
        case .normal:
            spaceAssertionFailure("shortcut duplicate check report view event's reason should not normal")
            return
        }
        DocsTracker.newLog(enumEvent: .addShortcutDuplicateCheckView, parameters: params)
    }
    
    public static func shortcutDuplicateCheckClick(stages: CreateShortcutStages,
                                                   click: String,
                                                   fileId: String? = nil,
                                                   fileTypeName: String? = nil) {
        var params: [String: Any] = ["click": click, "target": "none"]
        if let fileId {
            params["children_file_id"] = DocsTracker.encrypt(id: fileId)
        }
        if let fileTypeName {
            params["children_file_type"] = fileTypeName
        }
        switch stages {
        case .hasEntity:
            params["duplicate_reason"] = "origin"
        case .hasShortcut:
            params["duplicate_reason"] = "shortcut"
        case .normal:
            spaceAssertionFailure("shortcut duplicate check report click event's reason should not normal")
        }
        DocsTracker.newLog(enumEvent: .addShortcutDuplicateCheckClick, parameters: params)
    }
}
