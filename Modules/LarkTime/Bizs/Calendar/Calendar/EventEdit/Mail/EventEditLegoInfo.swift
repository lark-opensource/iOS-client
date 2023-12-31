//
//  EventEditLegoInfo.swift
//  Calendar
//
//  Created by Rico on 2022/3/10.
//

import Foundation
import RustPB

public enum EventEditMode {
    case create
    case edit(event: MailCalendarEvent)
}

public enum EventEditInterceptor {

    public typealias EventEditResult = (MailCalendarEvent) -> Void

    // 不影响正常编辑保存流程 不返回结果
    case none
    // 不影响正常编辑保存流程 返回结果
    case needResult(callBack: EventEditResult)
    // 阻断编辑保存流程 返回结果
    case onlyResult(callBack: EventEditResult)

    var callBack: EventEditResult? {
        switch self {
        case .none: return nil
        case let .needResult(callBack),
            let .onlyResult(callBack): return callBack
        }
    }
}

public struct EventEditLegoInfo: Equatable {
    public enum LegoID: CaseIterable {
        case unknown
        case summary
        case webinarAttendee
        case attendee
        case guestPermission
        case arrangeDate
        case datePicker
        case timeZone
        case videoMeeting
        case calendar
        case color
        case visibility
        case freebusy
        case reminder
        case meetingRoom
        case location
        case checkIn
        case rrule
        case description
        case attachment
        case meetingNotes
        case delete
        case larkVideoMeetingSetting
    }

    public struct Unit: Equatable {

        public enum UIVisible {
            case none
            case show

            var shouldShow: Bool {
                switch self {
                case .none: return false
                case .show: return true
                }
            }
        }

        // 标识
        let id: LegoID

        // 默认显示
        private(set) var visible: UIVisible = .show

        public static func id(_ id: LegoID) -> Self {
            Unit(id: id)
        }

        public func visible(v: UIVisible) -> Self {
            Unit(id: id, visible: v)
        }
    }

    let legoConfig: [LegoID: Unit]

    public init(legoConfig: [LegoID: Unit]) {
        self.legoConfig = legoConfig
    }

    public static func all(except: [EventEditLegoInfo.LegoID] = []) -> Self {
        var lego = all().to_dic()
        for id in except {
            lego[id] = Unit.id(id).visible(v: .none)
        }
        return EventEditLegoInfo(legoConfig: lego)
    }

    public static func normal() -> Self {
        Self.all(except: [.webinarAttendee])
    }

    public static func none(adding: [Unit] = []) -> Self {
        var lego = none().to_dic()
        for element in adding {
            lego[element.id] = element
        }
        return EventEditLegoInfo(legoConfig: lego)
    }

    private static func all() -> [Unit] {
        LegoID.allCases.map { Unit.id($0) }
    }

    private static func none() -> [Unit] {
        LegoID.allCases.map { Unit.id($0).visible(v: .none) }
    }

    // 是否包含所有部分
    func containAll() -> Bool {
        let fullCount = legoConfig.keys.count == LegoID.allCases.count
        let allShow = legoConfig.allSatisfy { $1.visible == .show }
        return fullCount && allShow
    }

}

extension Array where Element == EventEditLegoInfo.Unit {

    func to_dic() -> [EventEditLegoInfo.LegoID: EventEditLegoInfo.Unit] {
        Dictionary(grouping: self, by: { $0.id }).mapValues { $0.first ?? EventEditLegoInfo.Unit.id(.unknown) }
    }
}

extension EventEditLegoInfo {

    func shouldShow(_ id: EventEditLegoInfo.LegoID) -> Bool {
        guard let unit = legoConfig[id] else {
            return false
        }
        if id == .checkIn && !FG.eventCheckIn { return false }
        return unit.visible.shouldShow
    }

}

// MARK: Webinar Lego
extension EventEditLegoInfo {
    public static func webinar() -> Self {
        var legoIDs: [LegoID] = [
            .summary,
            .webinarAttendee,
            .datePicker,
            .timeZone,
            .calendar,
            .color,
            .visibility,
            .freebusy,
            .location,
            .description,
            .meetingRoom,
            .attachment,
            .larkVideoMeetingSetting
        ]
        let lego = legoIDs.map { Unit.id($0) }.to_dic()
        return EventEditLegoInfo(legoConfig: lego)
    }
}
