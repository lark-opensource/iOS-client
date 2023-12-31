//
//  CalendarSavable.swift
//  Calendar
//
//  Created by harry zou on 2019/3/21.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import RxSwift
import LarkUIKit
import LarkContainer

protocol CalendarManagerDataProtocol {
    var calendar: CalendarModel { get set }
    var calendarMembers: [CalendarMember] { get set }
    var rejectedUserIDs: [String] { get set }
}

class CalendarManagerController: CalendarController, CalendarManagerViewDelegate, CalendarColorEditable, CalendarSaveable {
    var api: CalendarRustAPI
    var calendarDependency: CalendarDependency
    var setLeftNaviationItem: ((UIBarButtonItem) -> Void)
    var setRightNaviationItem: ((UIBarButtonItem) -> Void)
    var originalCalendar: CalendarModel
    var originalCalendarMember: [CalendarMember] = []
    let selfUserId: String
    let skinType: CalendarSkinType
    var model: CalendarManagerModel
    let disposeBag = DisposeBag()
    var inSetting: Bool = false

    private let childView: CalendarManagerView

    init(dependency: CalendarManagerDependencyProtocol,
         calendarDependency: CalendarDependency,
         model: CalendarManagerModel,
         condition: CalendarEditPermission,
         setLeftNaviationItem: @escaping ((UIBarButtonItem) -> Void),
         setRightNaviationItem: @escaping ((UIBarButtonItem) -> Void)) {
        self.api = dependency.api
        self.calendarDependency = calendarDependency
        self.childView = CalendarManagerView(condition: condition)
        self.originalCalendar = model.calendar
        self.originalCalendarMember = model.calendarMembers
        self.model = model
        self.selfUserId = dependency.selfUserId
        self.skinType = dependency.skinType
        self.setLeftNaviationItem = setLeftNaviationItem
        self.setRightNaviationItem = setRightNaviationItem
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.ud.bgBase
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addCancelItem()
        updateSaveItem(withModel: model)
        layout(childView: childView)
        childView.update(with: model)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateNewModelData() {
        updateSaveItem(withModel: model)
        childView.update(with: model)
    }

    func layout(childView: CalendarManagerView) {
        self.view.addSubview(childView)
        childView.delegate = self
        childView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func addCancelItem() {
        let barItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Cancel)
        barItem.button.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        self.setLeftNaviationItem(barItem)
    }

    func enableSaveItem() {
        let barItem = LKBarButtonItem(image: nil, title: BundleI18n.Calendar.Calendar_Common_Save, fontStyle: .medium)
        barItem.button.tintColor = UIColor.ud.primaryContentDefault
        barItem.button.addTarget(self, action: #selector(savePressed), for: .touchUpInside)
        self.setRightNaviationItem(barItem)
    }

    func disableSaveItem() {
        let barItem = LKBarButtonItem(image: nil, title: BundleI18n.Calendar.Calendar_Common_Save)
        barItem.button.tintColor = UIColor.ud.primaryContentDefault.withAlphaComponent(0.5)
        barItem.button.addTarget(self, action: #selector(cannotSavePressed), for: .touchUpInside)
        self.setRightNaviationItem(barItem)
    }

    func updateSaveItem(withModel model: CalendarManagerModel) {
        if model.calendar.summary.isEmpty || !model.calendarMembersInitiated {
            disableSaveItem()
        } else {
            enableSaveItem()
        }
    }

    func update(withModel model: CalendarManagerModel) {
        self.model = model
        updateSaveItem(withModel: model)
        childView.update(with: model)
    }

    @objc
    func savePressed() {
        saveCal(withModel: model)
        trackCalendarSaveAction()
    }

    @objc
    func cannotSavePressed() {
        if model.calendarMembersInitiated {
            EventAlert.showNewCalCannotSaveAlert(controller: self)
        }
    }

    @objc
    func cancelPressed() {
        if model.calendar == originalCalendar,
        model.calendarMembers == originalCalendarMember {
            self.dismiss(animated: true, completion: nil)
            return
        } else {
            EventAlert.showDismissModifiedCalendarAlert(controller: self) { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
    }

    func calColorPressed() {
        modifyColor(withModel: model)
    }

    func calDescPressed() {
        assertionFailureLog("Must Override")
    }

    func addCalMemberPressed() {
        assertionFailureLog("Must Override")
    }

    func calMemberPressed(index: Int) {
        assertionFailureLog("Must Override")
    }

    func unsubscribeCalPressed() {
        assertionFailureLog("Must Override")
    }

    func deleteCalPressed() {
        assertionFailureLog("Must Override")
    }

    func calAccessPressed() {
        assertionFailureLog("Must Override")
    }

    func calSummaryChanged(newSummary: String) {
        assertionFailureLog("Must Override")
    }

    func calNoteChanged(newNote: String) {
        assertionFailureLog("Must Override")
    }

    private func trackCalendarSaveAction() {
        let descChanged = model.desc != originalCalendar.description
        let summaryChanged = model.calendar.summary != originalCalendar.summary
        CalendarTracerV2.CalendarSetting.traceClick {
            $0.click("save").target("none")
            $0.calendar_id = self.model.calendar.serverId
            $0.is_title_alias = summaryChanged.description
            $0.is_desc_alias = descChanged.description
        }
    }
}
