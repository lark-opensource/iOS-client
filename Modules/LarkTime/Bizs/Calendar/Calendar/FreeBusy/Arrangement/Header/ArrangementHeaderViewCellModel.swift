//
//  ArrangementHeaderViewCellModel.swift
//  Calendar
//
//  Created by harry zou on 2019/3/19.
//

import Foundation
import CalendarFoundation

protocol ArrangementHeaderCellProtocol {
    var calendarId: String { get }
    var avatar: Avatar { get }
    var nameString: String { get }
    var showBusyIcon: Bool { get }
    var showNotWorkingIcon: Bool { get }
    var timeString: String? { get }
    var weekString: String? { get }
    var hasNoPermission: Bool { get }
    var timeInfoHidden: Bool { get }
    var atLight: Bool { get }
}

struct ArrangementHeaderViewCellModel: ArrangementHeaderCellProtocol {
    let nameString: String
    let calendarId: String
    let avatar: Avatar
    var timeString: String?
    var weekString: String?
    var showBusyIcon: Bool
    var showNotWorkingIcon: Bool
    var hasNoPermission: Bool
    var timeInfoHidden: Bool
    var atLight: Bool
}
