//
//  MeetingRoomModel.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/28.
//  Copyright © 2017年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB

struct MeetingRoomBuilding {
    var id: String
    var name: String
    var description: String
    var hasAvailableMeetingRoom: Bool
    var weight: Int32
}
