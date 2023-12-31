//
//  AutoTestSetting.swift
//  SpaceKit
//
//  Created by nine on 2019/2/26.
//

import Foundation
import LarkStorage
import SKInfra

private enum AutoTestType: String {
    case disableRenderAccelerate

    func openSetting() {
        switch self {
        case .disableRenderAccelerate:
            OpenAPI.docs.disableEditorResue = false
        }
    }

    static var allValues: [AutoTestType] {
        return [.disableRenderAccelerate]
    }
}

/// 自动化测试的配置类
public final class AutoTestSetting {
    public static let settingRootDirectory = "/private/var/mobile/Media/DEBUG_SWITCH_DIR_dWdjZGV0ZWN0aW9u/"

    /// 如果settingRootDirectory目录存在，则根据该目录下的配置文件是否存在来决定是否激活
    public static func configAutoTestSetting() {
        guard AbsPath(settingRootDirectory).exists else { return }
        for type in AutoTestType.allValues where AbsPath(settingRootDirectory + type.rawValue).exists {
            type.openSetting()
        }
    }
}
