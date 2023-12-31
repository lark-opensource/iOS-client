//
//  EventEditCalendar.swift
//  Calendar
//
//  Created by 张威 on 2020/4/29.
//

import CalendarFoundation
import RustPB

/// 日程-日历
struct EventEditCalendar: EventCalendarType, PBModelConvertible {

    typealias PBModel = RustPB.Calendar_V1_Calendar

    private let pb: PBModel
    private var isLocal = false
    private var parentPb: PBModel?

    static func localCalendar(name: String) -> Self {
        var pb = PBModel()
        pb.summary = name
        pb.serverID = "local"
        return Self(from: pb)
    }

    init(from pb: PBModel, parentPb: PBModel) {
        self.pb = pb
        self.parentPb = parentPb
    }

    init(from pb: PBModel) {
        self.pb = pb
    }

    func getPBModel() -> PBModel {
        return pb
    }

    var id: String { pb.serverID }

    var source: EventCalendarSource {
        if isLocal {
            return .local
        }
        switch pb.type {
        case .exchange: return .exchange
        case .google: return .google
        @unknown default: return .lark
        }
    }

    // 主日历
    var isPrimary: Bool {
        switch pb.type {
        case .exchange, .google: return pb.isPrimary
        @unknown default: return pb.type == .primary
        }
    }

    // 共享日历
    var isShared: Bool { pb.type == .other }

    var name: String {
        // 日历名称和备注
        let summary = pb.localizedSummary.isEmpty ? pb.summary : pb.localizedSummary
        let note = pb.note.isEmpty ? summary : pb.note
        return summary
    }

    var emailAddress: String { pb.externalAccountEmail }

    var color: ColorIndex { pb.personalizationSettings.colorIndex }

    var parentId: String? { parentPb?.serverID }

    var userChatterId: String { pb.userID }

    var isOwnerOrWriter: Bool {
        return pb.selfAccessRole == .owner || pb.selfAccessRole == .writer
    }
}

extension EventEditCalendar: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        /// id 唯一的话只需要判断 id 即可
        return lhs.id == rhs.id
    }
}
