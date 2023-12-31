//
//  WikiPickerConfig.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/9/16.
//

import Foundation
import SKCommon
import SpaceInterface
import SKWorkspace

struct WikiPickerConfig {
    // 需要在目录树中禁用的节点，如正在被移动的节点
    var disabledWikiToken: String?
    // 操作按钮文案
    var actionName: String
    // picker 埋点上下文信息
    var tracker: WorkspacePickerTracker
    // picker 事件回调
    var completion: (WikiPickerLocation, UIViewController) -> Void
}

extension WikiPickerConfig {
    init(config: WorkspacePickerConfig) {
        actionName = config.actionName
        disabledWikiToken = config.disabledWikiToken
        tracker = config.tracker
        completion = { location, picker in
            config.completion(.wikiNode(location: location), picker)
        }
    }
}

extension WorkspacePickerTracker {
    func reportFileLocationSelectView() {
        WikiStatistic.fileLocationSelectView(viewTitle: actionType,
                                             triggerLocation: triggerLocation)
    }
}
