//
//  FeatureGatingKey.swift
//  LarkChatSetting
//
//  用于管理仅在LarkChatSetting业务中使用的FeatureGatingKey
//
//  Created by 姜凯文 on 2020/5/6.
//

import Foundation
import SuiteAppConfig
import LarkFeatureGating

extension FeatureGatingKey {
    // 是否放开选择部门权限限制
    static let disableSelectDepartmentPermission = "im.chat.depart_group_permission"
    static let autoJoinDepartGroup = "im.chat.auto_join_depart_group"
}

enum FeatureKey: String {
    case groupShareHistory = "chat.groupShareHistory" //【群设置】是否显示群分享历史
    case enterLeaveGroupHistory = "chat.enterLeaveGroupHistory" //【群设置】是否显示群成员进退群历史入口
}

extension AppConfigManager {
    func feature(for key: FeatureKey) -> Feature {
        return feature(for: key.rawValue)
    }

}
