//
//  SubscribeMeetingCellModel.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/17.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation

protocol SubscribeMeetingCellModel {
    var id: String { get }
    var floorName: String { get }
    var name: String { get }
    var buildingName: String { get }
    var isAvailable: Bool { get }
    var subscribeStatus: SubscribeStatus { get }
    var capacity: Int32 { get }
    var isDisabled: Bool { get }
    var needApproval: Bool { get }
}
