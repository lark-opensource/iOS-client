//
//  AddNewCalendarController.swift
//  AudioSessionScenario
//
//  Created by harry zou on 2019/3/25.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift

final class AddNewCalendarController: CalendarManagerController, CalendarAccessEditable, CalendarDescEditable, CalendarMemberEditable {
    let showSidebar: () -> Void
    init(dependency: CalendarManagerDependencyProtocol & AddMemberableDependencyProtocol,
         calendarDependency: CalendarDependency,
         model: CalendarManagerModel,
         showSidebar: @escaping () -> Void,
        setLeftNaviationItem: @escaping ((UIBarButtonItem) -> Void),
        setRightNaviationItem: @escaping ((UIBarButtonItem) -> Void)) {
        self.showSidebar = showSidebar
        super.init(dependency: dependency,
                   calendarDependency: calendarDependency,
                   model: model,
                   condition: CalendarEditPermission(calendarfrom: .fromCreate),
                   setLeftNaviationItem: setLeftNaviationItem,
                   setRightNaviationItem: setRightNaviationItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        CalendarTracerV2.CalendarCreate.traceView()
    }

    @objc
    override func cancelPressed() {
        super.cancelPressed()
        showSidebar()
    }

    @objc
    override func savePressed() {
        saveCal(withModel: model, saveSucess: self.showSidebar)
        CalendarTracerV2.CalendarCreate.traceClick { param in
            param
                .click("save")
                .target("none")
            param.has_description = (!self.model.desc.isEmpty).description
        }
    }

    override func calAccessPressed() {
        modifyAccess(withModel: model) {
            CalendarTracerV2.CalendarCreate.traceClick {
                $0.click("edit_public_scale").target("none")
            }
        }
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

    override func calSummaryChanged(newSummary: String) {
        model.calSummary = newSummary
        updateSaveItem(withModel: model)
    }
}
