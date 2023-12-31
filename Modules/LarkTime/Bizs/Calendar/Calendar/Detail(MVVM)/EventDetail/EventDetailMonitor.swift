//
//  EventDetailMonitor.swift
//  Calendar
//
//  Created by Rico on 2021/10/26.
//

import Foundation
import LKCommonsTracker
import LarkContainer

protocol MonitorDescription {

    var monitorDescription: String { get }
}

enum EventDetailMonitorKeys: String {

    enum Action: String {
        case load
        case loadUI
        case transfer
        case share
        case edit
        case delete
        case groupmeeting
        case docs
        case videomeeting
        case rsvp
        case join
    }

    enum Result: String {
        case success
        case failure
    }

    enum Reformer: String {
        case chat
        case main
        case fourTuple
        case local
        case roomLimit
        case rsvp
        case share
        case videoMeeting
    }

    enum CustomKey: String {
        case reformer
        case editResult
        case deleteType
        case toRSVP
        case span
    }

    case load = "cal_event_detail"
    case loadTime = "cal_event_detail_load_time"
}

final class EventDetailMonitor {

    let slardar_event_name = "cal_event_detail_monitor"
    let default_error_code = Int32.min

    let uuid: UUID

    let primaryCalendarID: String

    // 记录详情页入口类型
    var reformer: String = "unknown"

    static func makeMonitor(userResolver: UserResolver) -> EventDetailMonitor {
        var primaryCalendarID = ""
        if let calendarManager = try? userResolver.resolve(assert: CalendarManager.self) {
            primaryCalendarID = calendarManager.primaryCalendarID
        }
        return EventDetailMonitor(primaryCalendarID: primaryCalendarID)
    }

    init(primaryCalendarID: String) {
        uuid = UUID()
        self.primaryCalendarID = primaryCalendarID
    }

    enum Input {
        case start(_ action: EventDetailMonitorKeys.Action)
        case success(_ action: EventDetailMonitorKeys.Action,
                     _ model: EventDetailModel,
                     _ custom: [EventDetailMonitorKeys.CustomKey: Any])
        case failure(_ action: EventDetailMonitorKeys.Action,
                     _ model: EventDetailModel?,
                     _ error: Error,
                     _ custom: [EventDetailMonitorKeys.CustomKey: Any])
    }

    func track(_ input: Input, legacy: Bool = false) {
        switch input {
        case let .start(action):
            Tracker.start(token: action.rawValue)
        case let .success(action, model, custom):
            monitorSuccess(action, model, custom, legacy)
        case let .failure(action, model, error, custom):
            monitorFailure(action, model, error, custom, legacy)
        }
    }

    private func monitorSuccess(_ action: EventDetailMonitorKeys.Action,
                                _ model: EventDetailModel,
                                _ custom: [EventDetailMonitorKeys.CustomKey: Any],
                                _ legacy: Bool) {
        guard let time = Tracker.end(token: action.rawValue) else {
            return
        }
        let metrics: [String: Any] = [
            "time": time.duration
        ]
        var category: [String: Any] = [
            "action": action.rawValue,
            "result": EventDetailMonitorKeys.Result.success.rawValue,
            "is_legacy": legacy,
            "reformer": reformer,
            "isOnMyPriCalendar": (model.calendarId == self.primaryCalendarID),
        ]
        category.merge(model.monitorCategory) { $1 }
        category.merge(custom.map { ($0.rawValue, $1) }) { $1 }
        let extra: [String: Any] = [
            "monitor_id": uuid.uuidString
        ]
        Tracker.post(.init(name: slardar_event_name, metric: metrics, category: category, extra: extra))
    }

    private func monitorFailure(_ action: EventDetailMonitorKeys.Action,
                                _ model: EventDetailModel?,
                                _ error: Error,
                                _ custom: [EventDetailMonitorKeys.CustomKey: Any],
                                _ legacy: Bool) {
        guard let time = Tracker.end(token: action.rawValue) else {
            return
        }
        let metrics: [String: Any] = [
            "time": time.duration
        ]
        var category: [String: Any] = [
            "action": action.rawValue,
            "result": EventDetailMonitorKeys.Result.failure.rawValue,
            "errorCode": error.errorCode() ?? default_error_code,
            "is_legacy": legacy,
            "reformer": reformer
        ]
        if let model = model {
            category["isOnMyPriCalendar"] = (model.calendarId == self.primaryCalendarID)
            category.merge(model.monitorCategory) { $1 }
        }
        category.merge(custom.map { ($0.rawValue, $1) }) { $1 }
        let extra: [String: Any] = [
            "monitor_id": uuid.uuidString,
            "error_desc": error.localizedDescription
        ]
        Tracker.post(.init(name: slardar_event_name, metric: metrics, category: category, extra: extra))
    }
}

// 专门为统计监控做的扩展
extension EventDetailModel {

    var monitorTypeDesc: String {
        switch self {
        case .local: return "local"
        case .meetingRoomLimit: return "roomLimit"
        case .pb: return "pb"
        }
    }

    var monitorHasDesc: Bool {
        return !eventDescription.isEmpty || !docsDescription.isEmpty
    }

    var monitorCategory: [String: Any] {
        return [
            "isRecurrence": isRecurrence,
            "isException": isException,
            "type": monitorTypeDesc,
            "isThirdParty": isThirdParty,
            "hasDesc": monitorHasDesc,
            "rsvpStatus": selfAttendeeStatus.dt.description
        ]
    }
}
