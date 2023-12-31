//
//  DetailLegacy.swift
//  Calendar
//
//  Created by Rico on 2022/3/7.
//

import Foundation
import CalendarFoundation
import LarkUIKit
import RustPB
import UniverseDesignColor
import LarkContainer

// 这里存放旧详情页遗留的一些定义、扩展等。如果不用了就可以直接删，或者放到合适的地方去

extension Calendar_V1_ResourceContactPerson: Avatar {
    public var avatarKey: String {
        return contactPerson.avatarKey
    }

    public var userName: String {
        return contactPerson.name
    }

    public var identifier: String {
        return contactPerson.chatterID
    }
}

typealias JoinEventAction = (_ success: @escaping () -> Void,
    _ failure: ((Error) -> Void)?) -> Void

struct DetailMeetingRoomCellModel: DetailMeetingRoomCellContent {

    struct Item: DetailMeetingRoomItemContent {
        var statusTitle: String?
        var title: String
        var isAvailable: Bool
        var isDisabled: Bool
        var appLink: String?
        var calendarID: String
    }

    var items: [DetailMeetingRoomItemContent]
}
