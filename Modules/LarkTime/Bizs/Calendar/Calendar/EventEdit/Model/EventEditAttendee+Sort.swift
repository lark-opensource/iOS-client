//
//  EventEditAttendee+Sort.swift
//  Calendar
//
//  Created by huoyunjie on 2022/6/17.
//

import Foundation

// MARK: - Sort
struct AttendeeSortContext {
    var organizerCalendarId: String // 组织者id
    var creatorCalendarId: String // 创建者id
    var addedAtTail: Bool // 后添加的放在最后
    var originalKeys: [String]
}

extension Array where Element == EventEditAttendee {
    func sortedWith(context: AttendeeSortContext) -> [EventEditAttendee] {
        self.sorted { EventEditAttendee.attendeeCompare($0, $1, context: context) != .orderedDescending }
    }
}

extension EventEditAttendee {

    static func attendeeCompare(_ a0: EventEditAttendee, _ a1: EventEditAttendee, context: AttendeeSortContext) -> ComparisonResult {
        // 排序优先级 group > user > email > local
        switch (a0, a1) {
        case (.group, .user), (.group, .email), (.group, .local),
             (.user, .email), (.user, .local),
             (.email, .local):
            return .orderedAscending
        case (.user, .group), (.email, .group), (.local, .group),
             (.email, .user), (.local, .user),
             (.local, .email):
            return .orderedDescending
        case (.user(let u0), .user(let u1)):
            return userAttendeeCompare(u0, u1, context: context)
        case (.email(let e0), .email(let e1)):
            return emailAttendeeCompare(e0, e1)
        case (.local(let l0), .local(let l1)):
            return localAttendeeCompare(l0, l1)
        case (.group(let g0), .group(let g1)):
            return groupAttendeeCompare(g0, g1, context: context)
        }
    }

    /// 根据 status 排序: accept > decline > tentative > needsAction
    static private func attendeeStatusCompare(_ s0: AttendeeStatus, _ s1: AttendeeStatus) -> ComparisonResult {
        let statusWeights: [AttendeeStatus: Int] = [
            .accept: 1000,
            .decline: 100,
            .tentative: 10,
            .needsAction: 1,
            .removed: 0
        ]
        let w0 = statusWeights[s0] ?? 0
        let w1 = statusWeights[s1] ?? 0
        if w0 > w1 {
            return .orderedAscending
        } else if w0 == w1 {
            return .orderedSame
        } else {
            return .orderedDescending
        }
    }

    // 根据 calendarId 排序
    static private func calendarIdCompare(_ c0: String, _ c1: String, _ calendarId: String) -> ComparisonResult {
        if calendarId == c0 {
            return .orderedAscending
        } else if calendarId == c1 {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }

    static func userAttendeeCompare(_ a0: EventEditUserAttendee, _ a1: EventEditUserAttendee, context: AttendeeSortContext) -> ComparisonResult {
        var comparisonResult = ComparisonResult.orderedSame

        // 组织者优先
        if !context.organizerCalendarId.isEmpty {
            comparisonResult = calendarIdCompare(a0.calendarId, a1.calendarId, context.organizerCalendarId)
        }
        guard comparisonResult == .orderedSame else { return comparisonResult }

        // 创建者其次
        if !context.creatorCalendarId.isEmpty {
            comparisonResult = calendarIdCompare(a0.calendarId, a1.calendarId, context.creatorCalendarId)
        }
        guard comparisonResult == .orderedSame else { return comparisonResult }

        // 后添加的放在最后
        if belongsToAppended(at: a0, context: context) { return .orderedDescending }
        if belongsToAppended(at: a1, context: context) { return .orderedAscending }

        // 根据 status 排序
        comparisonResult = attendeeStatusCompare(a0.status, a1.status)
        guard comparisonResult == .orderedSame else { return comparisonResult }

        // 根据 name 排序
        return a0.name.localizedCompare(a1.name)
    }

    static private func localAttendeeCompare(_ a0: EventEditLocalAttendee, _ a1: EventEditLocalAttendee)
        -> ComparisonResult {
        let compareResultByStatus = attendeeStatusCompare(a0.status, a1.status)
        if compareResultByStatus != .orderedSame {
            return compareResultByStatus
        }
        return a0.name.lowercased().localizedCompare(a1.name.lowercased())
    }

    static private func emailAttendeeCompare(_ a0: EventEditEmailAttendee, _ a1: EventEditEmailAttendee)
        -> ComparisonResult {
        let compareResultByStatus = attendeeStatusCompare(a0.status, a1.status)
        if compareResultByStatus != .orderedSame {
            return compareResultByStatus
        }
        return a0.address.lowercased().localizedCompare(a1.address.lowercased())
    }

    static private func groupAttendeeCompare(_ a0: EventEditGroupAttendee, _ a1: EventEditGroupAttendee, context: AttendeeSortContext) -> ComparisonResult {
        if belongsToAppended(at: a0, context: context) { return .orderedDescending }
        if belongsToAppended(at: a1, context: context) { return .orderedAscending }
        return .orderedAscending
    }

    static private func belongsToAppended(at user: EventEditUserAttendee, context: AttendeeSortContext) -> Bool {
        guard context.addedAtTail else {
            return false
        }

        return !context.originalKeys.contains(user.deduplicatedKey)
    }

    static private func belongsToAppended(at group: EventEditGroupAttendee, context: AttendeeSortContext) -> Bool {
        guard context.addedAtTail else {
            return false
        }

        return !context.originalKeys.contains(group.deduplicatedKey)
    }
}
