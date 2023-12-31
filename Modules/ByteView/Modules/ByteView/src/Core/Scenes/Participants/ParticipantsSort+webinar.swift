//
//  ParticipantsSort+webinar.swift
//  ByteView
//
//  Created by wulv on 2022/11/18.
//

import Foundation

protocol WebinarAttendeeSortType {
    var sortId: Int64 { get }
}

extension ParticipantsSortTool {

    static func sortAttendee<T: WebinarAttendeeSortType>(_ attendees: [T]) -> [T] {
        return attendees.sorted { (firP, secP) -> Bool in
            return firP.sortId < secP.sortId
        }
    }
}
