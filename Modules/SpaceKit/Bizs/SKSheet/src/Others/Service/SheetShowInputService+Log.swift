//
//  SheetShowInputService+analysis.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/13.
//

import Foundation
import SKCommon
import SKBrowser
import SKFoundation

extension SheetShowInputService {

    var isInSheetCardMode: Bool {
        guard let browserVC = registeredVC as? SheetBrowserViewController else {
            return false
        }
        return browserVC.isInSheetCardMode
    }
    
    var modeName: String {
        return isInSheetCardMode ? "card_view" : currentInputMode.logName()
    }

    func logKeyboardEditStatus() {
        guard let info = model?.browserInfo.docsInfo else { return }
        for item in everEditKeyboard {
            let params = ["action": "input",
                          "file_id": DocsTracker.encrypt(id: info.objToken),
                          "file_type": info.type.name,
                          "mode": modeName,
                          "module": "sheet",
                          "source": "keyboard",
                          "keyboard_type": item.mainKeyboard.rawValue]
            DocsTracker.log(enumEvent: DocsTracker.EventType.sheetEditCellContent, parameters: params)
        }
        everEditKeyboard.removeAll()
    }

    func logSwitchKeyboard(type: BarButtonIdentifier) {
        guard let info = model?.browserInfo.docsInfo else { return }
        var action = "switch_text_tab"
        switch type {
        case .customDate:
            action = "switch_date_tab"
        case .customNumber:
            action = "switch_number_tab"
        case .systemText:
            action = "switch_text_tab"
        case .insertImage:
            break
        case .checkbox:
            break
        case .at:
            break
        case .addReminder:
            break
        default: () // FIXME: 埋点新增类型
        }
        let params = ["action": action,
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "source": "keyboard",
                      "mode": modeName,
                      "module": "sheet"]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
        everEditKeyboard.removeAll()
    }

    func logPressNumKeyboardItem(type: SheetNumKeyboardButtonType) {
        guard let info = model?.browserInfo.docsInfo else { return }
        var action = "bad-action"
        switch type {
        case .down:
            action = "click_keyboard_next_column"
        case .right:
            action = "click_keyboard_next_row"
        case .sign:
            action = "click_keyboard_plus_minus"
        case .currency:
            action = "click_keyboard_money"
        case .slash:
            action = "click_keyboard_slash"
        case .pecent:
            action = "click_keyboard_ratio"
        default:
            ()
        }
        if action == "bad-action" { return }
        let params = ["action": action,
                      "op_item": "number",
                      "source": "keyboard",
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "mode": modeName,
                      "module": "sheet"]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
        everEditKeyboard.removeAll()
    }

    func logPressSystemKeyboardNextItem() {
        guard let info = model?.browserInfo.docsInfo else { return }
        let params = ["action": "click_keyboard_next_row",
                      "op_item": "text",
                      "source": "keyboard",
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "mode": modeName,
                      "module": "sheet"]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
    }

    func logCompleteDateTimeKeyboardSelection(type: SheetDateTimeKeyboardSubtype) {
        guard let info = model?.browserInfo.docsInfo else { return }
        var action: String
        switch type {
        case .date: action = "click_keyboard_done_date"
        case .time: action = "click_keyboard_done_time"
        case .dateTime: action = "click_keyboard_done_date_time"
        case .none: action = "click_keyboard_done_all"
        case .clear: action = "click_keyboard_clear"
        }
        let params = ["action": action,
                      "op_item": "date",
                      "source": "keyboard",
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "mode": modeName,
                      "module": "sheet"]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
    }

    func logKeyboardToolkitSwitchToFAB() {
        guard let info = model?.browserInfo.docsInfo else { return }
        let params = ["action": "cell_action_open",
                      "source": "sheet_m_fab",
                      "fab_tpe": "keyboard",
                      "eventType": "click",
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "mode": modeName,
                      "module": "sheet"]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
    }
}
