//
//  MinutesAddParticipantCellItem.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import MinutesFoundation
import MinutesNetwork

enum ParticipantSelectType {
    case unselected //用户未选择
    case selected //用户被选择
    //case hasSelected //用户之前已经被选择，这里又搜出来了
    case disable //用户不能邀请
}

struct MinutesAddParticipantCellItem {
    var userId: String
    var selectType: ParticipantSelectType
    var imageURL: URL?
    var imageKey: String?
    let title: String
    var detail: String?
    var isExternal: Bool?
    var isInParticipants: Bool?
    var tenantName: String?
    var departmentName: String?
    var displayTag: DisplayTag?
}
