//
//  OwnedPrimaryCalendarManagerViewController.swift
//  Calendar
//
//  Created by harry zou on 2019/3/25.
//

import UIKit
import Foundation
import CalendarFoundation

final class OwnedPrimaryCalendarController: CalendarManagerController, CalendarAccessEditable, CalendarDescEditable, CalendarMemberEditable, CalendarUnsubscribeable {

    init(dependency: CalendarManagerDependencyProtocol & AddMemberableDependencyProtocol,
         calendarDependency: CalendarDependency,
         model: CalendarManagerModel,
         setLeftNaviationItem: @escaping ((UIBarButtonItem) -> Void),
         setRightNaviationItem: @escaping ((UIBarButtonItem) -> Void)) {
        super.init(dependency: dependency,
                   calendarDependency: calendarDependency,
                   model: model,
                   condition: CalendarEditPermission(calendarfrom: .fromEdit(calendar: model.calendar.getCalendarPB())),
                   setLeftNaviationItem: setLeftNaviationItem,
                   setRightNaviationItem: setRightNaviationItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func calAccessPressed() {
        modifyAccess(withModel: model, autoTrace: true)
    }

    override func calDescPressed() {
        modifyDesc(withModel: model, editable: true)
    }

    override func addCalMemberPressed() {
        addAttendee(withModel: model)
    }

    override func calMemberPressed(index: Int) {
        editAttendee(withModel: model, index: index)
    }

    override func unsubscribeCalPressed() {
        EventAlert.showUnsubscribeOwnedCalendarAlert(controller: self) { [unowned self] in
            CalendarTracer.shareInstance.calUnsubscribeCalendar(actionSource: .manage, calendarType: .contacts)
            self.unsubscribeCal(calendarId: self.model.calendar.serverId)
        }
        CalendarTracerV2.CalendarSetting.traceClick {
            $0.click("unsubscribe").target("none")
            $0.calendar_id = self.model.calendar.serverId
        }
    }

    override func calNoteChanged(newNote: String) {
        model.calSummaryRemark = newNote
    }
}
