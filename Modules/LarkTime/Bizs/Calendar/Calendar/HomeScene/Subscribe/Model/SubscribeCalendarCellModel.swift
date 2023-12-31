//
//  SubscribeCalendarCellModel.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/17.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB

protocol SubscribeCalendarCellModel {
    var avatarKey: String { get set }
    var title: String { get set }
    var subNum: Int { get set }
    var subTitle: String { get set }
    var subscribeStatus: SubscribeStatus { get set }
    var isDismissed: Bool { get set }
}
