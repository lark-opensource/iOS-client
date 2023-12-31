//
//  MyPrimaryCalManagementViewController.swift
//  Calendar
//
//  Created by harry zou on 2019/3/22.
//

import UIKit
import RxSwift
import CalendarFoundation

final class MyPrimaryCalendarController: CalendarManagerController, CalendarMemberEditable,
                                         CalendarAccessEditable, CalendarDescEditable {
    
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

    override func calNoteChanged(newNote: String) {
        model.calSummaryRemark = newNote
    }
}
