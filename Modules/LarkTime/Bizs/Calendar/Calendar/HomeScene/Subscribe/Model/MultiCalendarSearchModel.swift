//
//  MultiCalendarSearchModel.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/18.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB

struct MultiCalendarSearchModel: SubscribePeopleCellModel, SubscribeCalendarCellModel, SubscribeAbleModel {
    var title: String
    var subNum: Int = 0
    var subTitle: String
    var avatarKey: String
    var isDismissed: Bool
    var subscribeStatus: SubscribeStatus
    var calendarID: String
    var chatterID: String?
    var chatter: RustPB.Basic_V1_Chatter?
    var isOwner: Bool
    var isExternal: Bool
    var identifier: String {
        return chatterID ?? ""
    }
}
