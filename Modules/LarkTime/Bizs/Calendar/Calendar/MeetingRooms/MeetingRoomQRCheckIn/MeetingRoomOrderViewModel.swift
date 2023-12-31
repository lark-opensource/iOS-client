//
//  MeetingRoomOrderViewModel.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/28.
//

import Foundation
import RxCocoa
import RxSwift
import LarkTimeFormatUtils
import CalendarFoundation
import LarkContainer

final class MeetingRoomOrderViewModel: UserResolverWrapper {

    let userResolver: UserResolver
    @ScopedInjectedLazy private var api: CalendarRustAPI?
    private(set) var token: String

    private let bag = DisposeBag()

    let responseSubject = PublishSubject<MeetingRoomCheckInResponseModel>()

    // 埋点所需参数
    private(set) var trackParams = [String: String]()

    init(token: String, userResolver: UserResolver) {
        self.token = token
        self.userResolver = userResolver
    }

    func update() {
        api?.checkInInfo(token: token)
            .do(onNext: { [weak self] response in
                guard let self = self else { return }

                var usertype = "other"
                let (current, next, canCheckInList) = response.calculateCurrentInstanceAndNextInstance()
                if let next = next, canCheckInList.contains(where: { $0.0.quadrupleStr == next.0.quadrupleStr }) {
                    usertype = "next_event"
                }
                if let current = current, canCheckInList.contains(where: { $0.0.quadrupleStr == current.0.quadrupleStr }) {
                    usertype = "current_event"
                }

                var currentEventType = "available"
                if let current = current {
                    switch current.1.status {
                    case .alreadyCheckIn:
                        currentEventType = "busy"
                    case .notCheckIn:
                        currentEventType = "checkin"
                    case .userNotAuthorized: fallthrough
                    case .unknown:
                        currentEventType = "no_checkin"
                    @unknown default: break
                    }
                }

                var nextEventType = "available"
                if let next = next {
                    switch next.1.status {
                    case .alreadyCheckIn:
                        nextEventType = "busy"
                    case .notCheckIn:
                        nextEventType = "checkin"
                    case .userNotAuthorized: fallthrough
                    case .unknown:
                        nextEventType = "no_checkin"
                    @unknown default: break

                    }
                }

                self.trackParams = [
                    "mtgroom_name": "\(response.meetingRoom.floorName)-\(response.meetingRoom.name)",
                    "resource_id": response.meetingRoom.calendarID,
                    "user_type": usertype,
                    "current_event_type": currentEventType,
                    "next_event_type": nextEventType
                ]
            })
            .bind(to: responseSubject)
            .disposed(by: bag)
    }

    enum InactiveStatusCalculator {
        enum InactiveStatus: Equatable {
            case none // 会议室可用
            case qrCodeNotEnable // 二维码签到功能未开启
            case meetingRoomDisabled // 当前时间会议室被永久禁用（对应admin老版禁用）
            case duringStrategy(range: String, availableRange: String) // 当前时间会议室限制预定
            case duringRequisition(reason: String, range: String, chatters: [EventCreator]) // 当前时间会议室被计划性征用
            case userStrategy // 当前用户没有该会议室的权限 且没有可签到的instance
        }

        static func calculate(responseModel: MeetingRoomCheckInResponseModel) -> InactiveStatus {
            if !responseModel.strategy.qrCodeCheckInEnabled {
                return .qrCodeNotEnable
            }
            if responseModel.meetingRoom.isDisabled {
                return .meetingRoomDisabled
            }
            if let current = responseModel.calculateCurrentInstanceAndNextInstance().currentMeeting {
                if current.0.category == .resourceStrategy,
                   let resourceStrategy = responseModel.meetingRoom.schemaExtraData.cd.resourceStrategy {
                    let start = Date(timeIntervalSince1970: TimeInterval(current.0.startTime))
                    let end = Date(timeIntervalSince1970: TimeInterval(current.0.endTime))

                    var range: String
                    if start < end {
                        range = TimeFormatUtils.formatDateTimeRange(startFrom: start, endAt: end, with: .init(timePrecisionType: .minute))
                    } else {
                        range = TimeFormatUtils.formatDateTime(from: start, with: .init(timePrecisionType: .minute))
                        range = BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactiveForever(StartTime: range)
                    }

                    let timeIntervalRanges = CalendarMeetingRoom.availableTimeIntervalRanges(
                        by: Date(),
                        TimeInterval(resourceStrategy.dailyStartTime),
                        TimeInterval(resourceStrategy.dailyEndTime),
                        .current,
                        TimeZone(identifier: resourceStrategy.timezone) ?? .current,
                        false
                    )
                    let comma = BundleI18n.Calendar.Calendar_Common_Comma
                    let timeString = timeIntervalRanges.map { range in
                        return CalendarTimeFormatter.formatOneDayTimeRange(
                            startFrom: range.startDate,
                            endAt: range.endDate,
                            with: TimeFormatUtils.defaultOptions
                        )
                    }
                    .joined(separator: comma)

                    return .duringStrategy(range: range, availableRange: timeString)
                }

                if current.0.category == .resourceRequisition,
                   let resourceRequisition = responseModel.meetingRoom.schemaExtraData.cd.resourceRequisition {
                    let start = Date(timeIntervalSince1970: TimeInterval(resourceRequisition.startTime))
                    let end = Date(timeIntervalSince1970: TimeInterval(resourceRequisition.endTime))

                    var option = TimeFormatUtils.defaultOptions
                    option.timePrecisionType = .minute
                    var range: String
                    if start < end {
                        range = BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactive(StartTime: TimeFormatUtils.formatDateTime(from: start, with: .init(timePrecisionType: .minute)), EndTime: TimeFormatUtils.formatDateTime(from: end, with: .init(timePrecisionType: .minute)))
                    } else {
                        range = TimeFormatUtils.formatDateTime(from: start, with: option)
                        range = BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactiveForever(StartTime: range)
                    }

                    return .duringRequisition(reason: resourceRequisition.reason,
                                              range: range,
                                              chatters: resourceRequisition.contactIds.compactMap { responseModel.eventCreators[$0] })
                }
            }

            let (current, next, _) = responseModel.calculateCurrentInstanceAndNextInstance()
            if responseModel.auth == .limitedByUserStrategy {
                // 用户对于会议室无权限 除非其对当前或下一个日程有权限 否则显示无权限
                if let current = current, (current.1.status == .alreadyCheckIn || current.1.status == .notCheckIn) {
                    return .none
                }
                if let next = next, (next.1.status == .alreadyCheckIn || next.1.status == .notCheckIn) {
                    return .none
                }
                return .userStrategy
            }

            return .none
        }
    }
}
