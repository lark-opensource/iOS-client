//
//  EventDetailNavigationBarViewModel+More.swift
//  Calendar
//
//  Created by Rico on 2021/4/13.
//

import Foundation
import LarkUIKit
import LarkActionSheet
import UniverseDesignColor
import UniverseDesignActionPanel

extension EventDetailNavigationBarViewModel {

    struct OptionItem {

        enum ItemType: Hashable {
            case delete
            case transfer
            case report
            case copy
        }

        let type: ItemType
        let title: String
        let action: () -> Void
    }

    func handleMoreAction() {

        func _buildActions() -> [OptionItem.ItemType: OptionItem] {
            var actions: [OptionItem.ItemType: OptionItem] = [:]

            let canDeleteAll = model.canDeleteAll

            var isLarkCalendar = true

            if let calendar = calendarManager?.calendar(with: event.calendarID) {
                if calendar.isLocalCalendar() || calendar.type == .google || calendar.type == .exchange {
                    isLarkCalendar = false
                }
            }

            if enableCopy { actions[.copy] = OptionItem(type: .copy, title: I18n.Calendar_G_AnotherEvent_Button, action: copy) }
            if enableReport { actions[.report] = OptionItem(type: .report, title: BundleI18n.Calendar.Calendar_Detail_Report, action: report) }
            if enableTransfer { actions[.transfer] = OptionItem(type: .transfer, title: BundleI18n.Calendar.Calendar_Transfer_Transfer, action: transfer) }
            if enableDelete && canDeleteAll {
                actions[.delete] = OptionItem(type: .delete, title: I18n.Calendar_Event_CancelEvent, action: delete)
            } else if !(FG.eventRemoveOffline && isLarkCalendar) {
                actions[.delete] = OptionItem(type: .delete, title: I18n.Calendar_Event_DeleteEvent, action: delete)
            }

            return actions
        }

        let actions = _buildActions()
        doMoreAction(with: actions)
        CalendarTracer.shareInstance.calEventDetailMore()
        CalendarTracerV2.EventDetail.traceClick {
            $0
                .click("more_action")
                .target("cal_event_more_view")
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
        CalendarTracerV2.EventMore.traceView {
            $0.is_report = actions.keys.contains(.report).description
            $0.is_transfer = actions.keys.contains(.transfer).description
            $0.is_delete = actions.keys.contains(.delete).description
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
    }

    private func doMoreAction(with actions: [OptionItem.ItemType: OptionItem]) {

        guard !actions.isEmpty else { return }

        let possibleActionTypes: [OptionItem.ItemType] = [ .copy, .transfer, .delete, .report]
        let actions = possibleActionTypes.compactMap { actions[$0] }

        rxRoute.accept(.morePop(optionItems: actions))
        EventDetail.logInfo("do more. option count: \(actions.count)")
    }
}
