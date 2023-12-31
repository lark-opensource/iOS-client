//
//  CalendarEditViewModel+chores.swift
//  Calendar
//
//  Created by Hongbin Liang on 6/6/23.
//

import Foundation
import UniverseDesignTheme

extension CalendarEditViewModel {

    typealias AlertAction = () -> Void
    typealias ActionSheetAction = () -> Void

    enum Alert {
        // 删除
        case deleteConfirm(doDelete: AlertAction)
        // 离职交接人退订日历
        case successorUnsubscribe(doUnsubscribe: AlertAction, delete: AlertAction)
        // 弹窗
        case comfirmAlert(title: String, content: String)
        // 我管理的二次确认
        case ownedCalUnsubAlert(doUnsubscribe: AlertAction)
    }

    enum CalendarError: Error {
        case alertNoti(title: String, content: String)
        case weakSelfNil
    }

    enum TracerType {
        case viewAppear
        case editInnerAuth(authValue: String)
        case editExternalAuth(authValue: String)
        case save(isTitleAlias: String, isDescAlias: String)
        case deleteCalendar
        case addShareMember
    }

    func trace(_ type: TracerType) {
        if input.isFromCreate {
            switch type {
            case .viewAppear:
                CalendarTracerV2.CalendarCreate.traceView()
            case .editInnerAuth(let authValue):
                CalendarTracerV2.CalendarCreate.traceClick {
                    $0.click("edit_inner_auth")
                    $0.auth_value = authValue
                }
            case .editExternalAuth(let authValue):
                CalendarTracerV2.CalendarCreate.traceClick {
                    $0.click("edit_external_auth")
                    $0.auth_value = authValue
                }
            case .save(_, let hasDesc):
                CalendarTracerV2.CalendarCreate.traceClick {
                    $0.click("save")
                    $0.has_description = hasDesc
                }
            case .addShareMember:
                CalendarTracerV2.CalendarCreate.traceClick { $0.click("add_share_member") }
            case .deleteCalendar: return
            }
        } else {
            let calID = modelTupleBeforeEditing.calendar.serverID
            switch type {
            case .viewAppear:
                CalendarTracerV2.CalendarSetting.traceView {
                    $0.calendar_id = calID
                }
            case .editInnerAuth(let authValue):
                CalendarTracerV2.CalendarSetting.traceClick {
                    $0.click("edit_inner_auth")
                    $0.auth_value = authValue
                    $0.calendar_id = calID
                }
            case .editExternalAuth(let authValue):
                CalendarTracerV2.CalendarSetting.traceClick {
                    $0.click("edit_external_auth")
                    $0.auth_value = authValue
                    $0.calendar_id = calID
                }
            case .save(let isTitleAlias, let isDescAlias):
                CalendarTracerV2.CalendarSetting.traceClick {
                    $0.click("save")
                    $0.is_title_alias = isTitleAlias
                    $0.is_desc_alias = isDescAlias
                    $0.calendar_id = calID
                }
            case .addShareMember:
                CalendarTracerV2.CalendarSetting.traceClick {
                    $0.click("add_share_member")
                    $0.calendar_id = calID
                }
            case .deleteCalendar:
                CalendarTracerV2.CalendarSetting.traceClick {
                    $0.click("delete_calendar")
                    $0.calendar_id = calID
                }
            }
        }
    }
}

#if !LARK_NO_DEBUG
// MARK: 日历编辑页便捷调试数据
extension CalendarEditViewModel: ConvenientDebugInfo {
    var eventDebugInfo: Rust.Event? { nil }

    var calendarDebugInfo: Rust.Calendar? { self.rxCalendar.value.pb }

    var meetingRoomInstanceDebugInfo: RoomViewInstance? { nil }

    var meetingRoomDebugInfo: Rust.MeetingRoom? { nil }

    var otherDebugInfo: [String: String]? {
        return ["calendarMembers": self.rxCalendarMembers.value.debugDescription]
    }
}
#endif

extension UDComponentsExtension where BaseType == UIColor {
    static var panelBgColor: UIColor {
        UIDevice.current.userInterfaceIdiom == .pad ? .ud.bgFloat : .ud.bgBody
    }
}
