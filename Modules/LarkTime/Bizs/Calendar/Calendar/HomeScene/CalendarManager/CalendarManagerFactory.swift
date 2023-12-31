//
//  CalendarManagerFactory.swift
//  Calendar
//
//  Created by harry zou on 2019/3/22.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit
import RoundedHUD
import EENavigator
import RustPB
import LarkNavigator

protocol CalendarManagerDependencyProtocol {
    var calendar: CalendarModel { get }
    var api: CalendarRustAPI { get }
    var skinType: CalendarSkinType { get }
    var selfUserId: String { get }
    var eventDeleted: () -> Void { get }
}

protocol AddMemberableDependencyProtocol {
}

struct CalendarManagerDependency: AddMemberableDependencyProtocol, CalendarManagerDependencyProtocol {
    var calendar: CalendarModel
    var api: CalendarRustAPI
    var skinType: CalendarSkinType
    var selfUserId: String
    var eventDeleted: () -> Void
}

final class CalendarManagerFactory {

    class func newController(selfUserId: String,
                             calendarAPI: CalendarRustAPI,
                             calendarDependency: CalendarDependency?,
                             skinType: CalendarSkinType,
                             showSidebar: @escaping () -> Void,
                             disappearCallBack: (() -> Void)?,
                             finishSharingCallBack: ((_ calendar: RustPB.Calendar_V1_Calendar) -> Void)?,
                             summary: String? = nil) -> UINavigationController {
        let dependency = CalendarManagerDependency(calendar: CalendarModelFromPb.defaultCalendar(skinType: skinType),
                                                   api: calendarAPI,
                                                   skinType: skinType,
                                                   selfUserId: selfUserId,
                                                   eventDeleted: {})
        CalendarTracer.shareInstance.calGoEditCalendar(editType: .new,
                                                       actionSource: .sideBar,
                                                       calendarType: .shareCalendars)
        let vc = NewCalendarLoadingController(dependency: dependency,
                                              calendarDependency: calendarDependency,
                                              showSidebar: showSidebar,
                                              disappearCallBack: disappearCallBack,
                                              finishSharingCallBack: finishSharingCallBack,
                                              summary: summary)
        let nav = LkNavigationController(rootViewController: vc)
        nav.update(style: .default)
        nav.modalPresentationStyle = .fullScreen
        return nav

    }
    class func settingController(with calendarID: String,
                                 selfCalendarId: String,
                                 selfUserId: String,
                                 calendarAPI: CalendarRustAPI,
                                 calendarManager: CalendarManager,
                                 calendarDependency: CalendarDependency,
                                 skinType: CalendarSkinType,
                                 navigator: UserNavigator,
                                 eventDeleted: @escaping () -> Void,
                                 disappearCallBack: (() -> Void)?
    ) -> UINavigationController? {
        guard let calendar = calendarManager.calendar(with: calendarID ) else {
            if let window = navigator.mainSceneWindow {
                RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_GoogleCal_TryLater, on: window)
            }
            return nil
        }

        CalendarTracerV2.CalendarList.traceClick { $0.click("calendar_setting") }
        CalendarTracer.shareInstance.calGoEditCalendar(editType: .edit,
                                                       actionSource: .sideBar,
                                                       calendarType: .init(type: calendar.type))
        let dependency = CalendarManagerDependency(calendar: calendar,
                                         api: calendarAPI,
                                         skinType: skinType,
                                         selfUserId: selfUserId,
                                         eventDeleted: eventDeleted)

        let vc = EditCalendarLoadingController(with: dependency,
                                               calendarDependency: calendarDependency,
                                               selfCalendarId: selfCalendarId,
                                               disappearCallBack: disappearCallBack)
        let nav = LkNavigationController(rootViewController: vc)
        nav.update(style: .default)
        nav.modalPresentationStyle = .fullScreen
        return nav
    }
}
