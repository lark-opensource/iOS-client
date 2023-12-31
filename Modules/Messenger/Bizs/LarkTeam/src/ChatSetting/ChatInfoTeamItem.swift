//
//  ChatInfoTeamItem.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2022/9/15.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkModel
import LarkBizAvatar
import LarkOpenChat
import LarkMessengerInterface

struct ChatInfoTeamHeaderCellModel: ChatSettingCellVMProtocol {
    var type: ChatSettingCellType
    var cellIdentifier: String
    var style: ChatSettingSeparaterStyle
    var title: String
}

struct ChatInfoTeamItemsCellModel: ChatSettingCellVMProtocol {
    var type: ChatSettingCellType
    var cellIdentifier: String
    var style: LarkOpenChat.ChatSettingSeparaterStyle
    var teamCells: [ChatInfoTeamItem]
}

struct ChatInfoTeamItem {
    var type: ChatSettingCellType
    var title: String
    var subTitle: String
    var entityIdForAvatar: String
    var avatarKey: String
    var showSubTitle: Bool
    var showMore: Bool
    var chatId: String
    var unbindHandler: (_ model: ChatInfoTeamItem) -> Void
    var tapHandler: (_ model: ChatInfoTeamItem, _ cell: UIView) -> Void
}
