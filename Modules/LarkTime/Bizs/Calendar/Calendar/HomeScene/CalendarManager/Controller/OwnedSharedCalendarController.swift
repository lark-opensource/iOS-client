//
//  OwnedSharedCalendarManagerViewController.swift
//  Calendar
//
//  Created by harry zou on 2019/3/25.
//

import UIKit
import Foundation
import CalendarFoundation
import UniverseDesignActionPanel

final class OwnedSharedCalendarController: CalendarManagerController, CalendarAccessEditable, CalendarDescEditable, CalendarMemberEditable, CalendarUnsubscribeable, CalendarDeletable {
    private let deleteCallBack: () -> Void

    init(dependency: CalendarManagerDependencyProtocol & AddMemberableDependencyProtocol,
         calendarDependency: CalendarDependency,
         model: CalendarManagerModel,
         setLeftNaviationItem: @escaping ((UIBarButtonItem) -> Void),
         setRightNaviationItem: @escaping ((UIBarButtonItem) -> Void)) {
        self.deleteCallBack = dependency.eventDeleted
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
        let successorChatterID = model.calendar.getCalendarPB().successorChatterID

        let isResigned = !(successorChatterID.isEmpty || successorChatterID == "0") && model.calendar.type == .other
        if isResigned {
            let source = UDActionSheetSource(sourceView: view,
                                             sourceRect: view.bounds,
                                             arrowDirection: .up)
            // 必须再设置isShowTitle title才能生效 @qihao
            let pop = UDActionSheet(config: UDActionSheetUIConfig(style: .normal, isShowTitle: true))
            pop.setTitle(BundleI18n.Calendar.Calendar_Detail_UnsubscribeResignedPersonCalendar)
            pop.addDefaultItem(text: BundleI18n.Calendar.Calendar_Detail_UnsubscribeCalendar) { [weak self] in
                self?.unsubscribeCal(calendarId: successorChatterID)
            }
            pop.addDestructiveItem(text: BundleI18n.Calendar.Calendar_Detail_DeleteCalendar) { [weak self] in
                self?.deleteCalendar(with: successorChatterID)
            }
            pop.setCancelItem(text: BundleI18n.Calendar.Calendar_Common_Cancel)
            present(pop, animated: true, completion: nil)
        } else {
            EventAlert.showUnsubscribeOwnedCalendarAlert(controller: self) { [unowned self] in
                CalendarTracer.shareInstance.calUnsubscribeCalendar(actionSource: .manage, calendarType: .contacts)
                self.unsubscribeCal(calendarId: self.model.calendar.serverId)
            }
        }
        CalendarTracerV2.CalendarSetting.traceClick {
            $0.click("unsubscribe").target("none")
            $0.calendar_id = self.model.calendar.serverId
        }
    }

    override func deleteCalPressed() {
        EventAlert.showDeleteOwnedCalendarAlert(controller: self) { [unowned self] in
            self.deleteCalendar(with: self.model.calendar.serverId)
        }
        CalendarTracerV2.CalendarSetting.traceClick {
            $0.click("delete_calendar").target("cal_calendar_delete_confirm_view")
            $0.calendar_id = self.model.calendar.serverId
        }
    }

    override func calSummaryChanged(newSummary: String) {
        model.calSummary = newSummary
        updateSaveItem(withModel: model)
    }

    override func calNoteChanged(newNote: String) {
        model.calSummaryRemark = newNote
    }

    func deleteSuccess() {
        deleteCallBack()
    }

}
