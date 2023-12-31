//
//  GroupChatInfoHeaderView.swift
//  LarkChatSetting
//
//  Created by zc09v on 2020/5/28.
//

import UIKit
import LarkModel
import LarkTag
import LarkBizAvatar

struct GroupChatHeaderInfo {
    let basicInfo: ChatBasicInfo
    var editAvatar: (() -> Void)?
}
