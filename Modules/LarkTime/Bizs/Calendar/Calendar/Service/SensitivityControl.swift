//
//  SensitivityControl.swift
//  Calendar
//
//  Created by tuwenbo on 2023/7/7.
//

import Foundation
import CalendarFoundation
import LarkSensitivityControl

// https://meego.feishu.cn/larksuite/story/detail/10077840?parentUrl=%2Flarksuite%2FstoryView%2Fj5aQ5NmnR
enum SensitivityControlToken: String {

    // 日历业务启动时，预加载本地日历
    case preloadLocalCalendarOnSetup = "LARK-PSDA-calendar_preload_on_setup"

    // 授权本地日历权限完成后更新本地日历
    case updateLocalCalendarsAfterAuth = "LARK-PSDA-calendar_update_local_calendars_after_auth"

    // 日历业务第一次被调用时，预加载日历可见性
    case preloadLocalCalendarSourceVisibilityOnInit = "LARK-PSDA-calendar_preload_visiblity_on_init"

    // 系统日历变更时更新lark内的本地日历
    case updateLocalCalendarWhenSystemNotified = "LARK-PSDA-calendar_update_when_system_notified"

    // 系统日历变更时更新日历可见性
    case updateCalendarSourceVisibilityWhenSystemNotified = "LARK-PSDA-calendar_update_visibility_when_system_notified"
    
    // 系统授权后加载本地日历设置界面更新日历可见性
    case updateCalendarSourceVisibilityWhenLocalCalendarAuthorization = "LARK-PSDA-calendar_update_visibility_when_local_calendar_authorization"

    // 视图页显示时刷新日历数据，内部会读本地日历
    case readCalendarWhenCalendarViewShowed = "LARK-PSDA-calendar_read_local_when_calendar_view_showed"

    // 视图页读本地日程实例
    case readLocalEventInstanceOnEventView = "LARK-PSDA-calendar_read_event_on_event_view"

    // 视图页即时保存本地日程 (在日视图拖拽改变日程时间）
    case instantSaveEventOnDayScene = "LARK-PSDA-calendar_instant_save_event_on_day_scene"

    // 第三方日历管理页，读取本地日历
    case loadLocalCalendarOnAccountManager = "LARK-PSDA-calendar_load_on_account_manager_view"

    // 本地日历设置页，读取本地日历
    case localCalendarSettingView = "LARK-PSDA-calendar_load_on_local_setting_view"

    // 根据本地日历 identifier 跳转详情页， getLocalDetailController(identifier: String)，现在没有这个调用场景，以防万一，加上
    case readEventOnEventDetailView = "LARK-PSDA-calendar_read_event_on_detail_view"

    // 详情页删除本地日程
    case deleteEventOnEventDetailView = "LARK-PSDA-calendar_delete_event_on_detail_view"

    // 编辑页删除本地日程
    case deleteEventOnEventEditView = "LARK-PSDA-calendar_delete_event_on_edit_view"

    // 编辑页保存本地日程
    case saveEventOnEventEditView = "LARK-PSDA-calendar_save_event_on_edit_view"

    // 签到保存二维码
    case checkInSaveQR = "LARK-PSDA-calendar_save_image_on_checkin_view"

    // 分享保存日历二维码
    case shareCalendarSaveQR = "LARK-PSDA-calendar_save_image_on_share_calendar_view"

    // 导入本地日历时，请求授权
    case requestCalendarAccessWhenImportLocalCalendar = "LARK-PSDA-calendar_request_access_when_import_local_calendar"

    // 第三方账号管理页，导入本地日历时，请求授权
    case requestCalendarAccessOnAccountManagerView = "LARK-PSDA-calendar_request_access_on_account_manager_view"
    
    // 适配iOS17，导入本地日历时，请求授权
    case requestCalendarFullAccessWhenImportLocalCalendar = "LARK-PSDA-calendar_request_full_access_when_import_local_calendar"

    // 适配iOS17，第三方账号管理页，导入本地日历时，请求授权
    case requestCalendarFullAccessOnAccountManagerView = "LARK-PSDA-calendar_request_full_access_on_account_manager_view"

}

extension SensitivityControlToken {
    static func logFailure(_ message: String) {
        assertionFailureLog("[CalendarSensitivityControl] - \(message)")
    }

    var LSCToken: LarkSensitivityControl.Token {
        return LarkSensitivityControl.Token(self.rawValue)
    }
}

extension SensitivityControlToken: CustomStringConvertible {
    var description: String {
         rawValue
     }
}
