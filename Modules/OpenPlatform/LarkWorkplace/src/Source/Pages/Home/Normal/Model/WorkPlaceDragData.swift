//
//  WorkPlaceDragData.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2021/3/8.
//

import Foundation
import LarkUIKit
import LarkSceneManager

enum WorkPlaceScene {
    /// sceneKey
    static let sceneKey: String = "workplace.app"
    /// webWaySceneKey
    static let webWaySceneKey: String = "Web"
    /// itemKey
    static let itemKey: String = "workplace.item.model"
    // https://bytedance.feishu.cn/sheets/shtcn6wwfuGNzK40A4erVjr4df2?sheet=PSMGuf
    enum CreateWay: String {
        case drag
    }
    enum WindowType: String {
        // swiftlint:disable identifier_name
        case web_app
        // swiftlint:enable identifier_name
    }
    /// supportMutilScene
    static func supportMutilScene() -> Bool {
        guard Display.pad else {
            return false
        }
        guard #available(iOS 13.4, *) else {
            return false
        }
        return SceneManager.shared.supportsMultipleScenes
    }
}
