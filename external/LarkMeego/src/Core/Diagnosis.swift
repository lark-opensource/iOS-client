//
//  Diagnosis.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/6/4.
//

import Foundation
import LarkMeegoInterface
import LarkMeegoLogger
import ServerPB
import LKCommonsTracker

enum DiagnosisEntryName: String {
    // meego 链接
    case openUrl = "meego_open_url"
    // 消息长按面板
    case createWorkItemFromPanel = "meego_create_workitem_from_panel"
    // 键盘菜单
    case createWorkItemFromKeyboard = "meego_create_workitem_from_keyboard"
    // 多选消息菜单
    case createWorkItemFromMutiSelect = "meego_create_workitem_from_muti_select"
    // 快捷应用入口
    case createWorkItemFromShortcut = "meego_create_workitem_from_shortcut"

    static func entry(from: EntranceSource) -> DiagnosisEntryName {
        switch from {
        case .floatMenu: return .createWorkItemFromPanel
        case .keyboardMenu: return .createWorkItemFromKeyboard
        case .mutiSelect: return .createWorkItemFromMutiSelect
        case .shortcutMenu: return .createWorkItemFromShortcut
        }
    }
}

enum DiagnosisEntryResult {
    case success
    case failed(reason: DiagnosisDisableReason)
}

enum DiagnosisDisableReason {
    // 内存受限制设备，屏蔽 1GB 及以下
    case memoryProtected
    // 首次安装从未获取到过数据
    case payDataIsEmpty
    // 读取了上次结果为不可用的缓存数据
    case payCacheUnavailable
    // 后端由于各种原因返回了不可用的状态
    case payRemoteUnavailable(bizErrorCode: Int64, bizMsg: String)
    // 对应的 FG 开关未打开
    case fgClosed(fgName: String)
    // 强制升级拦截
    case forceUpgrade

    var categoryKey: String {
        switch self {
        // 内存受限制设备，屏蔽 1GB 及以下
        case .memoryProtected: return "memory_protected"
        // 首次安装从未获取到过数据
        case .payDataIsEmpty: return "pay_data_is_empty"
        // 读取了上次结果为不可用的缓存数据
        case .payCacheUnavailable: return "pay_cache_unavailable"
        // 后端由于各种原因返回了不可用的状态
        case .payRemoteUnavailable: return "pay_remote_unavailable"
        // 对应的 FG 开关未打开
        case .fgClosed: return "fg_false"
        case .forceUpgrade: return "force_upgrade"
        @unknown default: return "unknown"
        }
    }

    var description: String {
        if case .payRemoteUnavailable(let bizErrorCode, let bizMsg) = self {
            return "\(categoryKey), bizErrorCode = \(bizErrorCode), bizMsg = \(bizMsg)"
        }
        if case .fgClosed(let fgName) = self {
            return "\(categoryKey), fgName = \(fgName)"
        }
        return categoryKey
    }
}

enum DiagnosisAPICallResult {
    case success
    case failed(errorCode: Int64, errorMsg: String)
}

class Diagnosis {
    private static let loggerPrefix = "{diagnosis}"

    // 入口不可用时打点（点击时）
    static func hit(
        entry: DiagnosisEntryName,
        entryResult: DiagnosisEntryResult
    ) {
        var category: [AnyHashable: Any] = [
            "scene": entry.rawValue
        ]
        var extra: [AnyHashable: Any] = [:]
        switch entryResult {
        case .success: break
        case .failed(let reason):
            MeegoLogger.info("meego entry \(entry.rawValue) disabled, reason = \(reason.description)", customPrefix: loggerPrefix)

            category["disable_reason"] = reason.categoryKey

            if case .payRemoteUnavailable(let bizErrorCode, let bizMsg) = reason {
                category["biz_error_code"] = bizErrorCode
                extra["biz_error_msg"] = bizMsg
            } else if case .fgClosed(let fgName) = reason {
                extra["fg_name"] = fgName
            }
        @unknown default: break
        }

        let slardarEvent = SlardarEvent(
            name: "meego_entry_monitor_v2",
            metric: [:],
            category: category,
            extra: extra
        )
        Tracker.post(slardarEvent)
    }

    // 入口可用时打点（点击时）
    static func hit(apiCallResult: DiagnosisAPICallResult) {
        var category: [AnyHashable: Any] = [
            "scene": "meego_show_api"
        ]
        var extra: [AnyHashable: Any] = [:]
        switch apiCallResult {
        case .success: break
        case .failed(let errorCode, let errorMsg):
            category["error_code"] = errorCode
            extra["error_msg"] = errorMsg
        @unknown default: break
        }

        let slardarEvent = SlardarEvent(
            name: "meego_entry_monitor_v2",
            metric: [:],
            category: category,
            extra: extra
        )
        Tracker.post(slardarEvent)
    }
}
