//
//  EventEditViewModel+MeetingNotes.swift
//  Calendar
//
//  Created by huoyunjie on 2023/5/31.
//

import Foundation

extension EventEditViewModel {

    var meetingNotesModel: EventEditMeetingNotesMananger? {
        self.models[EventEditModelType.meetingNotes] as? EventEditMeetingNotesMananger
    }

    func makeMeetingNotesModel() -> EventEditMeetingNotesMananger {

        let meetingNotesManager = EventEditMeetingNotesMananger(userResolver: self.userResolver, input: self.input, identifier: EventEditModelType.meetingNotes.rawValue)
        meetingNotesManager.delegate = self

        return meetingNotesManager
    }
}

extension EventEditViewModel: EventEditMeetingNotesManagerDelegate {
    func editSpanType() -> Span {
        self.span
    }
}
