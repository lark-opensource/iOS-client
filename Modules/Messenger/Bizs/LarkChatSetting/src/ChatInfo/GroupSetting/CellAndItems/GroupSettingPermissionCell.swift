//
//  GroupSettingPermissionCell.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/9/17.
//

import Foundation
import SnapKit
import LarkCore
import LarkUIKit

// MARK: - 群设置权限 - item
struct GroupSettingPermissionItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var detail: String
    var tapHandler: ChatInfoTapHandler
}
