//
//  EventEditViewControllerDelegate.swift
//  Calendar
//
//  Created by 张威 on 2020/2/25.
//

import EventKit

protocol EventEditAttendeeDelegate: AnyObject {
    func addAttendee(from fromVC: EventEditViewController)
    func listAttendee(from fromVC: EventEditViewController)
}

protocol EventEditWebinarAttendeeDelegate: AnyObject {
    func addWebinarAttendee(from fromVC: EventEditViewController, type: WebinarAttendeeType)
    func listWebinarAttendee(from fromeVC: EventEditViewController, type: WebinarAttendeeType)
}

protocol EventEditDateDelegate: AnyObject {
    func pickDate(from fromVC: EventEditViewController, selectStart: Bool)
    func arrangeDate(from fromVC: EventEditViewController)
}

protocol EventEditRruleDelegate: AnyObject {
    func selectRrule(from fromVC: EventEditViewController)
    func selectRruleEndDate(from fromVC: EventEditViewController)
}

protocol EventEditVideoMeetingDelegate: AnyObject {
    func selectVideoMeeting(from fromVC: EventEditViewController)
}

protocol EventEditCalendarDelegate: AnyObject {
    func selectCalendar(from fromVC: EventEditViewController)
}

protocol EventEditColorDelegate: AnyObject {
    func selectColor(from fromVC: EventEditViewController)
}

protocol EventEditVisibilityDelegate: AnyObject {
    func selectVisibility(from fromVC: EventEditViewController)
}

protocol EventEditFreeBusyDelegate: AnyObject {
    func selectFreeBusy(from fromVC: EventEditViewController)
}

protocol EventEditMeetingRoomDelegate: AnyObject {
    func selectMeetingRoom(from fromVC: EventEditViewController)
}

protocol EventEditReminderDelegate: AnyObject {
    func selectReminder(from fromVC: EventEditViewController)
}

protocol EventEditCheckInDelegate: AnyObject {
    func selectCheckIn(from fromVC: EventEditViewController)
}

protocol EventEditLocationDelegate: AnyObject {
    func selectLocation(from fromVC: EventEditViewController)
}

protocol EventEditAttachmentDelegate: AnyObject {
    func selectAttachment(from fromVC: EventEditViewController, withToken token: String)
    func deleteAttachment(from fromVC: EventEditViewController, with index: Int)
    func reuploadAttachment(from fromVC: EventEditViewController, with index: Int)
    func addAttachment(from fromVC: EventEditViewController)
}

protocol EventEditNotesDelegate: AnyObject {
    func editNotes(from fromVC: EventEditViewController)
}

protocol EventEditGuestPermissionDelegate: AnyObject {
    func selectGuestPermission(from fromVC: EventEditViewController)
}

protocol EventEditViewControllerDelegate: EventEditAttendeeDelegate,
    EventEditDateDelegate,
    EventEditVideoMeetingDelegate,
    EventEditCalendarDelegate,
    EventEditColorDelegate,
    EventEditVisibilityDelegate,
    EventEditFreeBusyDelegate,
    EventEditMeetingRoomDelegate,
    EventEditLocationDelegate,
    EventEditCheckInDelegate,
    EventEditReminderDelegate,
    EventEditRruleDelegate,
    EventEditAttachmentDelegate,
    EventEditNotesDelegate,
    EventEditWebinarAttendeeDelegate,
    EventEditGuestPermissionDelegate {
    func didCancelEdit(from fromVC: EventEditViewController)
    func didFinishSaveEvent(_ pbEvent: Rust.Event, span: Span, from fromVC: EventEditViewController)
    func didFinishSaveLocalEvent(_ ekEvent: EKEvent, from fromVC: EventEditViewController)
    func didFinishDeleteEvent(_ pbEvent: Rust.Event, from fromVC: EventEditViewController)
    func didFinishDeleteLocalEvent(_ ekEvent: EKEvent, from fromVC: EventEditViewController)
}
