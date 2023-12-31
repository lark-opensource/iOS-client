//
//  GroupCardItem.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/10/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel

enum GroupCardCellItem {
    case title(chatName: String)
    case count(membersCount: Int?)
    case description(description: String)
    case owner(LarkModel.Chatter, chatId: String)
    case joinOrganizationTips(tips: String)
}
