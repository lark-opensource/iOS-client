//
//  SubscribedMeetingroomCalendarController.swift
//  Calendar
//
//  Created by harry zou on 2019/3/31.
//

import UIKit
import Foundation
import CalendarFoundation

final class SubscribedMeetingroomCalendarController: CalendarManagerController, CalendarDescEditable, CalendarUnsubscribeable {

    init(dependency: CalendarManagerDependencyProtocol,
         calendarDependency: CalendarDependency,
         model: CalendarManagerModel,
         setLeftNaviationItem: @escaping ((UIBarButtonItem) -> Void),
         setRightNaviationItem: @escaping ((UIBarButtonItem) -> Void)) {
        super.init(dependency: dependency,
                   calendarDependency: calendarDependency,
                   model: model,
                   condition: .init(calendarfrom: .fromEdit(calendar: model.calendar.getCalendarPB())),
                   setLeftNaviationItem: setLeftNaviationItem,
                   setRightNaviationItem: setRightNaviationItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func calDescPressed() {        modifyDesc(withModel: model, editable: false)
    }

    override func unsubscribeCalPressed() {
        let serverId = model.calendar.serverId
        CalendarTracer.shareInstance.calUnsubscribeCalendar(actionSource: .manage, calendarType: .meetingRoom)
        unsubscribeCal(calendarId: serverId)
        CalendarTracerV2.CalendarSetting.traceClick {
            $0.click("unsubscribe").target("none")
            $0.calendar_id = self.model.calendar.serverId
        }
    }

    override func calNoteChanged(newNote: String) {
        model.calSummaryRemark = newNote
    }
}
