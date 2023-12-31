//
//  MailSendController+Images.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/3/31.
//

import Foundation
import LarkAlertController
import EENavigator


extension MailSendController: MailSendCalendarViewDelegate {
    func calendarItemClick() {
        //点击toolbar上的calendar item
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["target": "none",
                        "click": "add_calendar"]
        event.post()
        accountContext.provider.calendarProvider?.showCalendarEditorVC(originEventModel: nil,
                                                                       title: BundleI18n.MailSDK.Mail_Event_NewEventInvitation,
                                                                       vc: self) { [weak self] model in
            guard let `self` = self else { return }
            self.updateCalendarModel(model: model, editable: true)
        }
    }
    func deleteCalendarView() {
        getCalendarInfo()// 等待信息返回再决定是否弹框
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["target": "none",
                        "click": "delete_calendar"]
        event.post()
    }
    func clickCalenderView() {
        guard let draftEvent = self.draft?.calendarEvent else {
            MailLogger.info("[send_calendar] calendar event if empty")
            return
        }
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["target": "none",
                        "click": "check_in_calendar"]
        event.post()
        let editable = draftEvent.editable
        let originModel = convertDraftModelToCalendar(draftEvent: draftEvent)
        accountContext.provider.calendarProvider?.showCalendarEditorVC(originEventModel: originModel,
                                                                       title: BundleI18n.MailSDK.Mail_Event_EditEventInvitation,
                                                                       vc: self) { [weak self] model in
            guard let `self` = self else { return }
            self.updateCalendarModel(model: model, editable: editable)
        }
    }
    func updateCalendarModel(model: CalendarEventModel, editable: Bool) {
        let draftEventModel = convertCalendarToDraftModel(model: model, editable: editable)
        self.draft?.calendarEvent = draftEventModel
        updateCalendarIcon()
        scrollContainer.updateCalendarView(calendarEvent: self.draft?.calendarEvent)
    }
    private func convertCalendarToDraftModel(model: CalendarEventModel, editable: Bool) -> DraftCalendarEvent {
        var res = DraftCalendarEvent()
        res.basicEvent = model.0
        if model.1.hasLongitude == true ||
            model.1.hasLongitude == true ||
            model.1.hasLatitude == true {
            res.location = model.1
        }
        res.meetingRooms = model.2
        res.videoMeeting = model.3
        res.calendarEventRef = model.4
        res.reminders = model.5
        res.editable = editable
        res.videoMeetingTemplate = fetchTemplateStr()
        return res
    }
    private func fetchTemplateStr() -> String {
        var str = constCalendarTemplate
        if !calendarTemplateFetched.isEmpty {
            str = calendarTemplateFetched
        }
        str = str.trimmingCharacters(in: .whitespacesAndNewlines)
        str = str.replacingOccurrences(of: "{{calendarDesc}}",
                                       with: BundleI18n.MailSDK.Mail_Event_JoinVideoMeeting)
        return str
    }
    private func convertDraftModelToCalendar(draftEvent: DraftCalendarEvent) -> CalendarEventModel {
        return CalendarEventModel(draftEvent.basicEvent,
                                  draftEvent.location,
                                  draftEvent.meetingRooms,
                                  draftEvent.videoMeeting,
                                  draftEvent.calendarEventRef,
                                  draftEvent.reminders)
    }
    func showDeleteCalendarAlert(showLink: Bool) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_Event_DeleteEventInvitationDialog)
        if showLink {
            alert.setContent(text: BundleI18n.MailSDK.Mail_Event_VideoMeetingDelete,
                             alignment: .center)
        }
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Event_GoBack)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Event_Delete, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.deleteCalendarEvent()
        })
        navigator?.present(alert, from: self)
    }
    private func deleteCalendarEvent() {
        let id = self.draft?.calendarEvent?.basicEvent.eventID
        if let id = id {
            self.removeCalendarInfo(id: id)
        }
        self.draft?.calendarEvent = nil
        updateCalendarIcon()
        scrollContainer.updateCalendarView(calendarEvent: nil)
    }
    private func getCalendarInfo() {
        var script = "window.command.getCalendarInfo()"
        self.requestEvaluateJavaScript(script) { (_, err) in
            if let err = err {
                MailLogger.error("getCalendarInfo err \(err)")
            }
        }
    }
    func getCalendarTemplate() {
        var script = "window.command.getCalendarTemplate(`\(BundleI18n.MailSDK.Mail_Event_JoinVideoMeeting)`)"
        self.requestEvaluateJavaScript(script) { (_, err) in
            if let err = err {
                MailLogger.error("getCalendarTemplate err \(err)")
            }
        }
    }
    func updateCalendarIcon() {
        var enable = true
        if let calendarEvent = self.draft?.calendarEvent {
            enable = false
        }
        var script = "window.command.enableCalendarToolbar(\(enable))"
        self.requestEvaluateJavaScript(script) { (_, err) in
            if let err = err {
                MailLogger.error("updateCalendarIcon err \(err)")
            }
        }
    }
    private func removeCalendarInfo(id: String) {
        var script = "window.command.removeCalendarInfo(`\(id)`)"
        self.requestEvaluateJavaScript(script) { (_, err) in
            if let err = err {
                MailLogger.error("remove calendar err \(err)")
            }
        }
    }
}
