//
//  MeetingRoomDetailEntity.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/1/22.
//

import Foundation
import RustPB

struct MeetingRoomDetailEntity: CustomPermissionConvertible {
    var permission: PermissionOption = .readable

    private var status: MeetingRoomStatus?
    private var subscriptionInfo: SubscriptionInfo?
    private var unusableReasons: UnusableReasons?
    private var statusContext: DetailWithStatusContext?
    private var meetingRoomInfo: MeetingRoomInfo

    init(fromStatusInfo statusInfo: StatusInformation, with context: DetailWithStatusContext) {
        meetingRoomInfo = statusInfo.information
        if statusInfo.hasStatus { status = statusInfo.status }
        subscriptionInfo = statusInfo.subscriptionInfo
        unusableReasons = statusInfo.unusableReasons
        statusContext = context
    }

    init(fromInfo info: RustPB.Calendar_V1_MeetingRoomInformation) {
        meetingRoomInfo = info
    }
}

// 会议室详情变量
extension MeetingRoomDetailEntity {
    // title
    var roomName: String {
        var name = ""
        let displayType = meetingRoomInfo.displayType
        if displayType == .buildingLike {
            name = (meetingRoomInfo.floorName + "-" + meetingRoomInfo.name).trimmingCharacters(in: .init(charactersIn: "-"))
        } else if displayType == .hierarchical {
            name = meetingRoomInfo.name
        }
        return name
    }

    var buildingName: String {
        var name = ""
        let displayType = meetingRoomInfo.displayType
        if displayType == .buildingLike {
            name = (meetingRoomInfo.cityName + "-" + meetingRoomInfo.buildingName).trimmingCharacters(in: .init(charactersIn: "-"))
        } else if displayType == .hierarchical {
            name = meetingRoomInfo.levelsName
        }
        return name
    }

    var state: MeetingRoomStatus? {
        return status
    }

    // basicInfo
    var capcity: String? {
        if meetingRoomInfo.hasCapacity {
            return BundleI18n.Calendar.Calendar_MeetingView_GuestCapacity(number: meetingRoomInfo.capacity)
        } else {
            return nil
        }
    }

    var equipments: String? {
        let array = meetingRoomInfo.equipmentLists.filter {
            return $0.hasI18NName && !$0.i18NName.isEmpty
        }.map { (equipment) -> String in
            return equipment.i18NName
        }
        return array.isEmpty ? nil : array.joined(separator: "·")
    }

    var resourcesRules: [String]? {
        var contents: [String] = []
        // 审批
        if meetingRoomInfo.hasIsApproval && meetingRoomInfo.isApproval {
            contents.append(BundleI18n.Calendar.Calendar_MeetingView_ReservationRequireApproval)
        }
        // 条件审批
        if meetingRoomInfo.hasTrigger {
            let value = Double(meetingRoomInfo.trigger.durationTrigger) / 3600.0
            contents.append(BundleI18n.Calendar.Calendar_Rooms_OverReserveTimeApprove(num: String(format: "%g", value)))
        }

        // 需要填写表单
        if meetingRoomInfo.hasIsCustomized {
            contents.append(BundleI18n.Calendar.Calendar_MeetingRoom_CustomizedSeriveDescription)
        }

        if meetingRoomInfo.shouldShowSummary {
            contents.append(BundleI18n.Calendar.Calendar_Rooms_PublicTopics)
        }

        // 会议室策略
        if meetingRoomInfo.hasResourceStrategy || meetingRoomInfo.hasResourceRequisition {
            let strategy = meetingRoomInfo.resourceStrategy
            let eventTimeZone = statusContext?.timeZone ?? TimeZone.current.identifier
            let meetingRoomTimeZone = strategy.timezone
            // 限时预定
            if strategy.hasDailyEndTime && strategy.hasDailyStartTime {
                let start = strategy.dailyStartTime
                let end = strategy.dailyEndTime
                if end - start < 24 * 60 * 60 {
                    let text = CalendarMeetingRoom.usableTimeText(
                        eventStartDate: statusContext?.startTime ?? Date(),
                        dailyStartTime: TimeInterval(start), dailyEndTime: TimeInterval(end),
                        eventTimeZoneId: eventTimeZone, meetingRoomTimeZoneId: meetingRoomTimeZone,
                        isReason: false
                    )
                    contents.append(text)
                }
            }
            // 最大预定时长限制
            if strategy.hasSingleMaxDuration {
                let maxDuration = strategy.singleMaxDuration
                // 服务端不处理，端上过滤
                if maxDuration < Int32.max {
                    let text = CalendarMeetingRoom.maxDurationText(fromSeconds: maxDuration, isReason: false)
                    contents.append(text)
                }
            }
            // 最远预定范围
            if strategy.hasUntilMaxDuration {
                let maxReservable = TimeInterval(meetingRoomInfo.resourceStrategy.untilMaxDuration)
                let meetingRoomTimeZone = meetingRoomInfo.resourceStrategy.timezone
                let regularReservableTime = TimeInterval(meetingRoomInfo.resourceStrategy.earliestBookTime)
                // 最大
                let text = CalendarMeetingRoom.preReserveRuleText(
                    maxDaysReservable: maxReservable,
                    regularReservableTime: regularReservableTime,
                    workDay: meetingRoomInfo.resourceStrategy.maxWorkday,
                    maxType: meetingRoomInfo.resourceStrategy.maxReservableType,
                    meetingRoomTimeZone: meetingRoomTimeZone
                )
                contents.append(text)
            }
            // 会议室限时禁用，当前时间在禁用时间之后不显示 （requisitionEndTime=0 -> 无限期禁用）
            let requisitionEndTime = TimeInterval(meetingRoomInfo.resourceRequisition.endTime)
            if meetingRoomInfo.hasResourceRequisition &&
                (Date().timeIntervalSince1970 < requisitionEndTime || requisitionEndTime == 0) {
                let requisitionStartTime = TimeInterval(meetingRoomInfo.resourceRequisition.startTime)
                let text = CalendarMeetingRoom.requisitionText(
                    requiStartTime: requisitionStartTime,
                    requiEndTime: requisitionEndTime,
                    eventTimeZoneId: eventTimeZone,
                    meetingRoomTimeZoneId: meetingRoomTimeZone,
                    isReason: false
                )
                contents.append(text)

                let reason = meetingRoomInfo.resourceRequisition.reason
                if !reason.isEmpty {
                    contents.append(BundleI18n.Calendar.Calendar_MeetingRoom_InactiveReason(InactiveReason: reason))
                }
            }
        }

        return contents.isEmpty ? nil : contents
    }

    var remark: String? {
        if meetingRoomInfo.hasRemark && !meetingRoomInfo.remark.isEmpty {
            return meetingRoomInfo.remark
        } else { return nil }
    }

    var picture: String? {
        if meetingRoomInfo.hasPicture && !meetingRoomInfo.picture.isEmpty {
            return meetingRoomInfo.picture
        } else { return nil }
    }

    var creator: String? {
        // 个人主日历上的日程，organzier是组织者，creator是创建者
        // 共享日历上的日程，creator是继承者，original_event_creator是创建者
        // 端上创建者的逻辑应该是organizer不为空，创建者为creator，否则，创建者为original_event_creator。将要显示的创建者与显示的组织者做比较，若不同，显示创建者
        let booker = subscriptionInfo?.eventBooker()
        let creater = subscriptionInfo?.eventCreater()

        guard booker?.chatterID != creater?.chatterID,
              let creatorName = creater?.name else { return nil }
        let creatorInfo = BundleI18n.Calendar.Calendar_Detail_CreatedBy(creator: creatorName)
        return creatorInfo
    }

}

extension SubscriptionInfo {
    func eventBooker() -> EventCreator {
        if !eventOrganizer.chatterID.isEmpty {
            return eventOrganizer
        }
        return creator
    }

    func eventCreater() -> EventCreator {
        if !originalEventCreator.chatterID.isEmpty {
            return originalEventCreator
        }
        return creator
    }
}

// 会议室状态变量
extension MeetingRoomDetailEntity {
    // 已预定
    var scheduledTime: String {
        guard let subscriptionInfo = subscriptionInfo else {
            assertionFailure("会议室订阅信息为空")
            return ""
        }
        let availableTimePeriod = CalendarMeetingRoom.scheduledTimeText(
            startTime: TimeInterval(subscriptionInfo.startTime),
            endTime: TimeInterval(subscriptionInfo.endTime),
            isAllday: subscriptionInfo.isAllDay
        )
        return availableTimePeriod
    }

    var bookerInfo: [String] {
        guard let subscriptionInfo = subscriptionInfo else {
            assertionFailure("会议室订阅信息为空")
            return []
        }
        let organizer = !subscriptionInfo.eventOrganizer.chatterID.isEmpty ? subscriptionInfo.eventOrganizer : subscriptionInfo.creator
        let avatorKey = organizer.avatarKey
        let userName = organizer.name
        let identifier = organizer.chatterID
        let department = organizer.department
        return [avatorKey, userName, identifier, department]
    }

    // 不可预定
    var cantReserveReasons: [String] {
        guard let unusableReasons = unusableReasons?.unusableReasons else {
            assertionFailure("会议室不可预定原因为空")
            return []
        }
        let meetingRoomTimeZoneID = meetingRoomInfo.resourceStrategy.timezone
        let eventTimeZone = statusContext?.timeZone ?? TimeZone.current.identifier
        var contents = unusableReasons.compactMap { (reason) -> String? in
            switch reason {
            case .duringRequisition:
                let start = meetingRoomInfo.resourceRequisition.startTime
                let end = meetingRoomInfo.resourceRequisition.endTime
                if Int64(Date().timeIntervalSince1970) > end && end != 0 { return nil }
                return CalendarMeetingRoom.requisitionText(requiStartTime: TimeInterval(start),
                                                           requiEndTime: TimeInterval(end),
                                                           eventTimeZoneId: eventTimeZone,
                                                           meetingRoomTimeZoneId: meetingRoomTimeZoneID)
            case .notInUsableTime:
                let start = meetingRoomInfo.resourceStrategy.dailyStartTime
                let end = meetingRoomInfo.resourceStrategy.dailyEndTime
                return CalendarMeetingRoom.usableTimeText(
                    eventStartDate: statusContext?.startTime ?? Date(),
                    dailyStartTime: TimeInterval(start), dailyEndTime: TimeInterval(end),
                    eventTimeZoneId: eventTimeZone, meetingRoomTimeZoneId: meetingRoomTimeZoneID
                )
            case .overMaxDuration:
                let maxDuration = meetingRoomInfo.resourceStrategy.singleMaxDuration
                return CalendarMeetingRoom.maxDurationText(fromSeconds: maxDuration)
            case .overMaxUntilTime:
                return CalendarMeetingRoom.furthestBookTimeText(furthestTime: meetingRoomInfo.resourceStrategy.furthestBookTime)
            case .beforeEarliestBookTime:
                let regularReservableTime = meetingRoomInfo.resourceStrategy.earliestBookTime
                return CalendarMeetingRoom.earliestBookTimeText(
                    regularReservableTime: TimeInterval(regularReservableTime),
                    meetingRoomTimeZone: meetingRoomTimeZoneID
                )
            case .pastTime:
                return BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserveForPastEvent
            case .cantReserveOverTime:
                let trigger = Double(meetingRoomInfo.trigger.durationTrigger)
                let duration = trigger / 3600.0
                return BundleI18n.Calendar.Calendar_Rooms_CantReserveOverTime(num: String(format: "%g", duration))
            @unknown default:
                assertionFailure("未知原因")
                return ""
            }
        }.filter { return !$0.isEmpty }

        if !contents.isEmpty {
            contents.insert(BundleI18n.Calendar.Calendar_MeetingView_ReservationFailTo, at: 0)
        }
        return contents
    }
}
