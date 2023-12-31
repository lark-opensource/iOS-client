//
//  SubscribePeopleCellContent.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/10.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB

protocol SubscribePeopleCellModel {
    var title: String { get set }
    var subTitle: String { get set }
    var avatarKey: String { get set }
    var calendarID: String { get set }
    var identifier: String { get }
    var isExternal: Bool { get set }
    var subscribeStatus: SubscribeStatus { get set }
}
