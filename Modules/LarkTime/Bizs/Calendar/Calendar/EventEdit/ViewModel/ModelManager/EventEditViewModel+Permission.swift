//
//  EventEditViewModel+Permission.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation

// MARK: Setup PermissionManager

extension EventEditViewModel {

    var permissionModel: EventEditPermissionManager? {
        self.models[EventEditModelType.permission] as? EventEditPermissionManager
    }

    func makePermissionModel() -> EventEditPermissionManager {
        let permission_model = EventEditPermissionManager(
            userResolver: self.userResolver,
            identifier: EventEditModelType.permission.rawValue,
            input: self.input,
            eventModel: EventEditModel(),
            primaryCalendar: calendarManager?.primaryCalendar ?? CalendarModelFromPb(pb: .init())
        )
        permission_model.relyModel = [EventEditModelType.event.rawValue]
        permission_model.initMethod = { [weak self, weak permission_model] observer in
            guard let event = self?.eventModel?.rxModel?.value, let permission_model = permission_model else { return }
            permission_model.updateEventModel(event)
            observer.onCompleted()
        }
        permission_model.initLater = { [weak self, weak permission_model] in
            // init_later
            guard let self = self, let permission_model = permission_model else { return }
            self.eventModel?.rxModel?.skip(1).bind { [weak permission_model] eventModel in
                permission_model?.updateEventModel(eventModel)
            }.disposed(by: self.disposeBag)
        }
        return permission_model
    }
}
