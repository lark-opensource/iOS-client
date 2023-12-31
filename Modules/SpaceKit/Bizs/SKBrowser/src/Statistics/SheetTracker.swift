//
//  SheetTracker.swift
//  SKSheet
//
//  Created by huayufan on 2021/6/8.
//  

import SKFoundation
import SKCommon


public struct SheetTracker {

    class ReminderRecord {
        /// 是否改变原有时间或日期
        var isEditOriginalTime: Bool = false
        /// 是否开启时间
        var isOpenTime: Bool = false
        /// 是否开启提醒
        var isOpenReminder: Bool = false
        /// 是否改变提醒人
        var isEditMention: Bool = false
        /// 是否编辑备注
        var isEditRemark: Bool = false
        init() {}
    }
    
    public static var commonParams: [String: Any] = [:]
    
    public enum Event {
        /// sheet 页面曝光
        case sheetAddExpose
        /// sheet 查找和替换曝光
        case searchViewExpose
        /// 点击
        case searchFinish
        
        /// 提醒面板关闭时上报
        case editReminder(old: ReminderModel, new: ReminderModel)

        case insertMention
        
        /// 关闭工具箱 action: 0 拖拽关闭 1其他
        case closeToolbox(action: Int)
        
        /// 触发智能截屏
        case smartScreencapture
        
        /// 智能截屏页面的点击  0 "save：点击保存  1 share：点击分享   2close：点击关闭
        case smartScreenCaptureClick(action: Int)
        
        var keyValue: (DocsTracker.EventType, [String: Any]) {
            switch self {
            case .sheetAddExpose:
                return (.sheetCreateTabView, [:])
            case .searchViewExpose:
                return (.sheetSearchReplaceView, [:])
            case .searchFinish:
                return (.sheetSearchReplaceClick, ["target": "none"])
            case let .editReminder(old, new):
                let record = convertToReminderRecord(old: old, new: new)
                return (.sheetContentPageClick, ["target": "none",
                                                 "is_edit_original_time": "\(record.isEditOriginalTime)",
                                                 "is_open_time": "\(record.isOpenTime)",
                                                 "is_open_reminder": "\(record.isOpenReminder)",
                                                 "is_edit_mention": "\(record.isEditMention)",
                                                 "is_edit_remark": "\(record.isEditRemark)"])
            case .insertMention:
                return (.sheetContentPageClick, ["target": "ccm_mention_panel_view"])
            case let .closeToolbox(action):
                return (.sheetContentPageClick, ["target": "none", "action_type": action == 0 ? "drag_to_close" : "other"])
            case .smartScreencapture:
                return (.sheetContentPageClick, ["target": "none"])
                
            case let .smartScreenCaptureClick(action):
                // "save：点击保存 ,share：点击分享, close：点击关闭"
                var subClick = "save"
                switch action {
                case 0:
                    subClick = "save"
                case 1:
                    subClick = "share"
                case 2:
                    subClick = "close"
                default:
                    break
                }
                return (.sheetContentPageClick, ["target": "none", "sub_click": subClick])
            }
        }
        
        var clickValue: String? {
            switch self {
            case .sheetAddExpose, .searchViewExpose:
                return nil
            case .editReminder:
                return "edit_reminder"
            case .insertMention:
                return "insert_mention"
            case .closeToolbox:
                return "close_toolbox"
            case .smartScreencapture:
                return "smart_screencapture"
            case .smartScreenCaptureClick:
                return "smart_screencapture_click"
            case .searchFinish:
                return "find_value"
            }
        }
    }
    
    public static func report(event: Event, docsInfo: DocsInfo?) {
        if let info = docsInfo {
            guard info.type == .sheet else {
                return
            }
        }
        let token = (docsInfo?.wikiInfo?.objToken ?? docsInfo?.objToken) ?? ""
        var parameters = event.keyValue.1
        if let clickValue = event.clickValue {
            parameters["click"] = clickValue
        }
        if !commonParams.isEmpty {
            parameters.merge(commonParams) { (_, new) in new }
        }
        if let docsInfo = docsInfo {
            let base = DocsParametersUtil.createCommonParams(by: docsInfo)
            parameters.merge(base) { (old, _) in old }
        }
        DocsTracker.newLog(event: event.keyValue.0.rawValue, parameters: parameters)
    }
    
    static func convertToReminderRecord(old: ReminderModel, new: ReminderModel) -> ReminderRecord {
        let record = ReminderRecord()
        record.isEditOriginalTime = old.expireTime != new.expireTime
        record.isOpenTime = new.shouldSetTime == true
        record.isOpenReminder = new.notifyUsers?.isEmpty == false
        let oldNotifyUsers = old.notifyUsers ?? []
        let newNotifyUsers = new.notifyUsers ?? []
        if oldNotifyUsers.count == newNotifyUsers.count {
            for (o, n) in zip(oldNotifyUsers, newNotifyUsers) {
                guard o.id == n.id else {
                    record.isEditMention = true
                    break
                }
            }
        }
        record.isEditRemark = old.notifyText != new.notifyText
        return record
    }
}
