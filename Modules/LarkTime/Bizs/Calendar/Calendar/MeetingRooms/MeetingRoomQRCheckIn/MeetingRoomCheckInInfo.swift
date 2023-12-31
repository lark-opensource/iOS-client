//
//  MeetingRoomCheckInInfo.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/25.
//

import Foundation
import RustPB

struct MeetingRoomCheckInResponseModel {

    typealias ChatterID = String
//    case unknown = 0
//    case authorized = 1
//    case limitedByUserStrategy = 2
    typealias Auth = Calendar_V1_GetResourceCheckInInfoResponse.CreateEventAuth
    typealias InstanceWithInfo = (CalendarEventInstance, Info)

    struct Info: Equatable {
//        case unknown = 0
//        case alreadyCheckIn = 1
//        case notCheckIn = 2
//        case userNotAuthorized = 3
        typealias CheckInType = Calendar_V1_InstanceCheckInInfo.CheckInType

        let instanceID: String
        let timestamp: Int64
        let status: CheckInType

        init(pb: Calendar_V1_InstanceCheckInInfo) {
            instanceID = pb.instanceID
            timestamp = pb.checkInTimestampSecond
            status = pb.checkInStatus
        }
    }

    struct Strategy {
//        case unknown = 0
//        case activated = 1
//        case inactivated = 2
        typealias QRCodeStatus = Calendar_V1_ResourceCheckInStrategy.QRCodeStatus

        let durationBeforeCheckIn: Int64
        let durationAfterCheckIn: Int64
        let status: QRCodeStatus
        let qrCodeCheckInEnabled: Bool

        init(pb: Calendar_V1_ResourceCheckInStrategy) {
            durationBeforeCheckIn = pb.durationBeforeStartCheckIn
            durationAfterCheckIn = pb.durationAfterStartCheckIn
            status = pb.qrStatus
            qrCodeCheckInEnabled = pb.isQrCheckInEnable
        }
    }

    var meetingRoom: Rust.MeetingRoom
    var building: Rust.Building
    var eventCreators: [ChatterID: EventCreator]
    var timestamp: Int64
    var auth: Auth // 能否预定日程的权限
    var eventsWithCheckInInfo: [InstanceWithInfo]
    var strategy: Strategy //  会议室签到规则

    var sortedEventsByStartTime: [InstanceWithInfo] {
        eventsWithCheckInInfo.sorted { lhs, rhs in
            lhs.0.startTime < rhs.0.startTime
        }
    }

    func calculateCurrentInstanceAndNextInstance() -> (currentMeeting: MeetingRoomCheckInResponseModel.InstanceWithInfo?,
                                                       nextMeeting: MeetingRoomCheckInResponseModel.InstanceWithInfo?,
                                                       canCheckInMeetings: [MeetingRoomCheckInResponseModel.InstanceWithInfo]) {
        let sorted = sortedEventsByStartTime
        let current = sorted.first { $0.0.startTime < timestamp && $0.0.endTime > timestamp }
        let next = sorted.first { $0.0.startTime > timestamp }

        var canCheckInMeetings = [MeetingRoomCheckInResponseModel.InstanceWithInfo]()
        if let meeting = current, meeting.1.status == .notCheckIn {
            let startTime = meeting.1.timestamp
            if ((startTime - strategy.durationBeforeCheckIn)...(startTime + strategy.durationAfterCheckIn)).contains(timestamp) {
                canCheckInMeetings.append(meeting)
            }
        }
        if let meeting = next, meeting.1.status == .notCheckIn {
            let startTime = meeting.1.timestamp
            if ((startTime - strategy.durationBeforeCheckIn)...(startTime + strategy.durationAfterCheckIn)).contains(timestamp) {
                canCheckInMeetings.append(meeting)
            }
        }

        return (current, next, canCheckInMeetings)
    }

    init(pb: MeetingRoomGetResourceCheckInInfoResponse) {
        meetingRoom = pb.resource
        building = pb.building
        eventCreators = pb.chatters
        timestamp = pb.currentTimestampSecond
        auth = pb.authCreateEvent
        eventsWithCheckInInfo = pb.instanceInfos.map { ($0.instance, Info(pb: $0.instanceCheckInInfo)) }
        strategy = Strategy(pb: pb.resourceCheckInStrategy)
    }
}
