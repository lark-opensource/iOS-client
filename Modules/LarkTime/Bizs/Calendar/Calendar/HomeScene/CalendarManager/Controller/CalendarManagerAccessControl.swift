//
//  CalendarManagerAccessControl.swift
//  AudioSessionScenario
//
//  Created by harry zou on 2019/3/27.
//

import UIKit
import Foundation
import UniverseDesignToast
import CalendarFoundation

protocol CalendarAccessEditable {
    func update(withModel model: CalendarManagerModel)
}

extension CalendarAccessEditable where Self: UIViewController {

    func modifyAccess(withModel model: CalendarManagerModel,
                      completion: (() -> Void)? = nil) {
        modifyAccess(withModel: model, completion: completion, autoTrace: false)
    }

    func modifyAccess(withModel model: CalendarManagerModel,
                           completion: (() -> Void)? = nil,
                           autoTrace: Bool = false) {
        guard !model.calendar.getCalendarPB().isAllStaff else {
            UDToast.showTips(with: I18n.Calendar_Share_UnableChangePermissionsForAllStaff, on: self.view)
            return
        }
        let access = model.calendar.calendarAccess
        let controller = CalendarAccessRoleViewController(access: access) { [unowned self] (newAccess) in
            model.permission = newAccess
            self.update(withModel: model)
            CalendarTracer.shareInstance.calCalPermissionChange(permission: .init(access: newAccess))
            completion?()
            if autoTrace {
                CalendarTracerV2.CalendarSetting.traceClick {
                    $0.click("edit_public_scale").target("none")
                    $0.calendar_id = model.calendar.serverId
                }
            }
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}

protocol CalendarColorEditable: EventColorViewControllerDelegate {
    var model: CalendarManagerModel { get }
    func update(withModel model: CalendarManagerModel)
}

extension CalendarColorEditable where Self: UIViewController {
    func modifyColor(withModel model: CalendarManagerModel) {
        let headerTitle = BundleI18n.Calendar.Calendar_Setting_CalendarColor
        let controller = EventColorViewController(
            selectedColor: model.colorIndex,
            headerTitle: headerTitle,
            isShowBack: true
        )
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    func didFinishEdit(from viewController: EventColorViewController) {
        model.colorIndex = viewController.selectedColor
        model.calendar.backgroundColor = colorToRGB(color: model.color)
        self.update(withModel: model)
        viewController.navigationController?.popViewController(animated: true)
     }

     func didCancelEdit(from viewController: EventColorViewController) {
         viewController.navigationController?.popViewController(animated: true)
     }
}

protocol CalendarDescEditable {
    func update(withModel model: CalendarManagerModel)
}

extension CalendarDescEditable where Self: UIViewController {
    func modifyDesc(withModel model: CalendarManagerModel, editable: Bool) {
        let desc = model.calendar.description ?? ""
        let controller = CalendarDescriptionViewController(desc: desc, editable: editable) { (newDesc) in
            if !editable {
                assertionFailureLog()
                return
            }
            model.desc = newDesc
            self.update(withModel: model)
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}
