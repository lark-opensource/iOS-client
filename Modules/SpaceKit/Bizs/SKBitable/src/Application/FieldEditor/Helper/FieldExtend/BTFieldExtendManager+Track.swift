//
//  BTFieldExtendManager+Track.swift
//  SKBitable
//
//  Created by zhysan on 2023/4/28.
//

import SKFoundation
import SKCommon

enum BTExtTrackKey: String {
    case ccm_bitable_extendable_field_format_modify_click
    case ccm_bitable_field_extend_modify_view
    case ccm_bitable_field_extend_modify_click
    case ccm_bitable_field_extend_sync_error_view
    case ccm_bitable_field_extend_sync_error_click
    case ccm_bitable_field_modify_board_extend_warning_view
}

private extension FieldExtendExceptNotice {
    var trackReason: String {
        switch self {
        case .originDeleteForOwner, .originDeleteForUser:
            return "field_delete"
        case .noExtendFieldPermForOwner, .noExtendFieldPermForUser:
            return "permission_limited"
        case .originMultipleEnable:
            return "multiple_enable"
        }
    }
    
    var clickReportValue: String {
        switch self {
        case .noExtendFieldPermForOwner:
            return "continue_sync"
        case .originDeleteForOwner:
            return "change_field"
        case .originDeleteForUser, .noExtendFieldPermForUser, .originMultipleEnable:
            return ""
        }
    }
}

extension BTFieldExtendManager {
    func trackExtendSwitchChange(model: BTFieldEditModel, start: FieldExtendConfig, end: FieldExtendConfig) {
        let startItems = start.extendState ? start.extendItems.filter({ $0.isChecked }) : []
        let endItems = end.extendState ? end.extendItems.filter({ $0.isChecked }) : []
        DocsTracker.newLog(
            event: BTExtTrackKey.ccm_bitable_extendable_field_format_modify_click.rawValue,
            parameters: [
                "click": "extend_for_more",
                "field_type": model.fieldTrackName,
                "switch_type": end.extendState ? "switch_on" : "switch_off",
                "extend_switch_type": end.extendState ? "switch_on" : "switch_off",
                "before_save_extend_field_num": startItems.count,
                "after_save_extend_field_num": endItems.count,
                "before_extend_field_detail": startItems.map({ ["extend_field_type": $0.extendFieldType] }).toJSONString() ?? "",
                "after_extend_field_detail": endItems.map({ ["extend_field_type": $0.extendFieldType] }).toJSONString() ?? "",
            ]
        )
    }
    
    func trackExtendSave(model: BTFieldEditModel, start: FieldExtendConfig, end: FieldExtendConfig) {
        let startItems = start.extendState ? start.extendItems.filter({ $0.isChecked }) : []
        let endItems = end.extendState ? end.extendItems.filter({ $0.isChecked }) : []
        DocsTracker.newLog(
            event: BTExtTrackKey.ccm_bitable_extendable_field_format_modify_click.rawValue,
            parameters: [
                "click": "save",
                "field_type": model.fieldTrackName,
                "switch_type": end.extendState ? "switch_on" : "switch_off",
                "extend_switch_type": end.extendState ? "switch_on" : "switch_off",
                "before_save_extend_field_num": startItems.count,
                "after_save_extend_field_num": endItems.count,
                "before_extend_field_detail": startItems.map({ ["extend_field_type": $0.extendFieldType] }).toJSONString() ?? "",
                "after_extend_field_detail": endItems.map({ ["extend_field_type": $0.extendFieldType] }).toJSONString() ?? "",
            ]
        )
    }
    
    
    func trackExtendSubTypePanelView(origin: FieldExtendOrigin, sceneType: String) {
        DocsTracker.newLog(
            event: BTExtTrackKey.ccm_bitable_field_extend_modify_view.rawValue,
            parameters: [
                "extend_from_field_type": origin.fieldUIType.fieldTrackName,
                "edit_type": editMode == .add ? "new_field" : "switch",
                "scene_type": sceneType,
            ]
        )
    }
    
    func trackExtendSubTypePanelClick(origin: FieldExtendOrigin, item: FieldExtendConfigItem, sceneType: String) {
        DocsTracker.newLog(
            event: BTExtTrackKey.ccm_bitable_field_extend_modify_click.rawValue,
            parameters: [
                "click": item.extendFieldType,
                "from_hover_field_type": origin.fieldUIType.fieldTrackName,
                "edit_type": editMode == .add ? "new_field" : "switch",
                "scene_type": sceneType,
            ]
        )
    }
    
    func trackExtendRefreshButtonClick(model: BTFieldEditModel, extendInfo: FieldExtendInfo) {
        DocsTracker.newLog(
            event: DocsTracker.EventType.bitableFieldModifyViewClick.rawValue,
            parameters: [
                "click": "data_refresh",
                "extend_from_field_type": extendInfo.extendInfo.originFieldUIType.fieldTrackName,
                "extend_field_type": extendInfo.extendInfo.extendFieldType,
            ]
        )
    }
    
    func trackExtendNoticeView(model: BTFieldEditModel, notice: FieldExtendExceptNotice, isOwner: Bool) {
        DocsTracker.newLog(
            event: BTExtTrackKey.ccm_bitable_field_extend_sync_error_view.rawValue,
            parameters: [
                "from_field_type": model.fieldExtendInfo?.extendInfo.originFieldUIType.fieldTrackName ?? "",
                "error_type": notice.trackReason,
                "is_owner": isOwner ? "true" : "false",
            ]
        )
        DocsTracker.newLog(
            event: BTExtTrackKey.ccm_bitable_field_modify_board_extend_warning_view.rawValue,
            parameters: [
                "extend_from_field_type": model.fieldExtendInfo?.extendInfo.originFieldUIType.fieldTrackName ?? "",
                "extend_field_type": model.fieldExtendInfo?.extendInfo.extendFieldType ?? "",
            ]
        )
    }
    
    func trackExtendNoticeClick(model: BTFieldEditModel, notice: FieldExtendExceptNotice) {
        DocsTracker.newLog(
            event: BTExtTrackKey.ccm_bitable_field_extend_sync_error_click.rawValue,
            parameters: [
                "click": notice.clickReportValue,
                "from_field_type": model.fieldExtendInfo?.extendInfo.originFieldUIType.fieldTrackName ?? "",
                "extend_field_type": model.fieldExtendInfo?.extendInfo.extendFieldType ?? "",
            ]
        )
    }
}
