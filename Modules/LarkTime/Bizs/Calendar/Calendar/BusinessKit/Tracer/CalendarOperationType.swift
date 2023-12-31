//
//  CalendarLogger.swift
//  Calendar
//
//  Created by 朱衡 on 2018/11/8.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import LarkRustClient
import LKCommonsLogging
import RustPB

enum CalendarOperationType: String {
    case botCard
    case botAccept
    case botRefuse
    case botUdm
    case shareCard
    case shareJoin
    case rmdCard
    case rmdDetail
    case rmdClose
    case eventAdd
    case oneAdd
    case threeAdd
    case listAdd
    case monthAdd
    case oneDetail
    case threeDetail
    case listDetail
    case monthDetail
    case oneClickTime
    case listClickTime
    case monthClickTime
    case monthToLeft
    case monthToRight
    case threeToLeft
    case threeToRight
    case oneToLeft
    case oneToRight
    case switchView
    case switchOne
    case switchThree
    case switchList
    case switchMonth
    case noSwitch
    case checkCal
    case uncheckCal
    case pushBot
    case pushShare
    case pushReminder
    case pushReminderClose
    case pushScrollClose
    case pushEventSync
    case pushCalSync
    case pushCalEventRefresh
    case pushCalEventChange
    case pushCalEventSync
    case pushInvite
    case pushSetting
    case share
    case edit
    case acceptThis
    case acceptAll
    case accept
    case refuseThis
    case refuseAll
    case refuse
    case udmThis
    case udmAll
    case udm
    case group
    case attend
    case saveEvent
    case del
    case back
    case saveThis
    case saveFollow
    case saveAll
    case delThis
    case delFollow
    case delAll
    case timeNotification
    case tabToRedLine
    case googleBinding
    case pushMeetingEditor
    case pushEventShareToChatNotification
    case pushGoogleBindSettingNotification
    case pushVideoMeetingChangeNotification
    case pushAssociatedVcStatusNotification
    case pushAssociatedLiveStatusNotification
}
