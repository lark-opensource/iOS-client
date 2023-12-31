//
//  FG.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/21.
//

import Foundation
import LarkSetting
import LarkContainer
import LarkReleaseConfig
import LarkFeatureGating
import LarkKAFeatureSwitch
import LKCommonsLogging
import LarkUIKit

@propertyWrapper
struct CalFG {
    private let key: String
    private let debugValue: Bool?
    public init(_ key: String, debugValue: Bool? = nil) {
        self.key = key
        self.debugValue = debugValue
    }

    /// Projecting the key from property wrapper, can use directly with $ prefix
    /// e.g. FG.$eventNoteDocsAutoAuth
    var projectedValue: String { return key }

    public var wrappedValue: Bool {
        mutating get {
            #if DEBUG
            if let debugValue = debugValue {
                return debugValue
            }
            #endif
            return LarkFeatureGating.shared.getStaticBoolValue(for: self.key)
        }
    }
}

@propertyWrapper
struct CalFG2 {
    private let key: String
    private let realTime: Bool
    private let debugValue: Bool?
    public init(_ key: String, realTime: Bool = false, debugValue: Bool? = nil) {
        self.key = key
        self.realTime = realTime
        self.debugValue = debugValue
    }

    /// Projecting the key from property wrapper, can use directly with $ prefix
    /// e.g. FG.$eventNoteDocsAutoAuth
    var projectedValue: String { return key }

    public var wrappedValue: Bool {
        mutating get {
            #if DEBUG
            if let debugValue = debugValue {
                return debugValue
            }
            #endif
            // LarkFeatureGating 升级为 FeatureGatingManager
            let manager = realTime ? FeatureGatingManager.realTimeManager : FeatureGatingManager.shared
            return manager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: self.key))
        }
    }
}

// 此 FG 方式不建议再继续使用，应迁移到 FeatureGating
enum FG {
    @CalFG("calendar.close.google", debugValue: false) static var isTurnoffGoogleCalendarImport: Bool

    @CalFG("feishu.report", debugValue: true) static var isReportEnabled: Bool

    @CalFG("calendar.multi.time.zone.v2", debugValue: true) static var isMultiTimeZone: Bool

    @CalFG("calendar.ipad.multi.time.zone.v2", debugValue: true) static var isMultiTimeZoneOnPad: Bool

    // 支持Exchange导入 + 账号过期逻辑
    @CalFG("calendar.exchange.import", debugValue: true) static var enableImportExchange: Bool

    /// 支持别名
    @CalFG("lark.chatter.name_with_another_name_p2", debugValue: true) static var useChatterAnotherName: Bool

    /// 新版日历视图
    @CalFG("calendar.externalsharing.dot", debugValue: true) static var optimizeCalendar: Bool

    /// client参与者权限设置开关
    @CalFG("calendar_guests_permission", debugValue: true) static var guestPermission: Bool

    /// admin参与者权限设置开关
    @CalFG("admin_calendar_guests_permission", debugValue: false) static var adminGuestPermission: Bool

    /// 日程预约取消不发送通知选项
    @CalFG("calendar.rsvp.notice", debugValue: true) static var rsvpNoticeOffline: Bool

    /// 日程签到开关
    @CalFG("calendar_client_signing", debugValue: true) static var eventCheckIn: Bool

    /// 邮箱搬家 三方日历去重
    @CalFG("calendar_sync_deduplication", debugValue: true) static var syncDeduplicationOpen: Bool

    /// zoom视频会议
    @CalFG("calendar.integrate.zoom", debugValue: true) static var shouldEnableZoom: Bool

    /// webinar 创建入口
    @CalFG("vc.webinar.mobile.calendar.entrance", debugValue: true) static var enableWebinar: Bool
   
    /// 创建日程同步拉群
    @CalFG("calendar.client.create_group_optional", debugValue: true) static var clientCreateGroupOption: Bool

    /// rsvp 卡片拉群优化
    @CalFG2("calendar.client.bot_optional", realTime: true, debugValue: true) static var rsvpBotOptional: Bool

    /// 有效会议（创建日程页面使用）
    @CalFG("calendar.client.meetingnotes", debugValue: true) static var meetingNotes: Bool

    /// 是否启用AI, 下线时记得删掉 GuideService.isGuideNeedShow(key:)
    static var myAI: Bool {
        @CalFG("lark.my_ai.main_switch") var mainSwitch: Bool
        @CalFG("ccm.docx.mobile.docx_ai_1.0") var docAI: Bool
        return mainSwitch && docAI && !GuideService.isGuideNeedShow(key: .globalMyAIInitGuide)
    }
    
    /// 忙闲架构优化一期
    @CalFG2("calendar.freebusy.optv1", realTime: true, debugValue: true) static var freebusyOpt: Bool
    
    /// rsvp 卡片极光样式优化
    @CalFG2("calendar_client_new_rsvpcard", realTime: true, debugValue: true) static var rsvpStyleOpt: Bool

    /// 分享卡片样式优化
    @CalFG("calendar_client_new_sharecard", debugValue: true) static var shareCardStyleOpt: Bool

    /// 会议室灵活层级置顶
    @CalFG2("calendar_rooms_top_client", debugValue: true) static var supportLevelPinTop: Bool
    
    /// 会议室预定优化
    @CalFG2("calendar.rooms.reservation.time", debugValue: true) static var calendarRoomsReservationTime: Bool

    /// 会议室灵活层级支持用户级灰度
    @CalFG2("calendar_roomslevel_byuser", debugValue: true) static var multiLevel: Bool

    /// 日历订阅人数外露
    @CalFG2("calendar_subscribers_view") static var showSubscribers: Bool

    /// 转让退出日程优化
    @CalFG2("calendar.remove.offline", realTime: true, debugValue: true) static var eventRemoveOffline: Bool
}

enum CalConfig {
    static var isMultiTimeZone: Bool = {
        return ReleaseConfig.kaDeployMode == .saas && (Display.pad ? FG.isMultiTimeZoneOnPad : FG.isMultiTimeZone)
    }()
}


public struct FeatureGating {
    static let logger = Logger.log(FeatureGating.self, category: "calendar.feature_gating")

    static func viewPageLogChore(userID: String) -> Bool {
        getStaticFgValue("calendar.view_page.log_chore", userID: userID)
    }

    static func isTurnoffGoogleCalendarImport(userID: String) -> Bool {
        getStaticFgValue("calendar.close.google", userID: userID)
    }

    static func isMultiTimeZone(userID: String) -> Bool {
        getStaticFgValue("calendar.multi.time.zone.v2", userID: userID)
    }

    /// myAI 蓝牙扫描会议室
    static func bluetoothScanRooms(userID: String) -> Bool {
        getDynamicFgValue("calendar.myai.bluetooth_scan_rooms", userID: userID)
    }

    /// rsvp 卡片极光样式优化 ，样式优化fg在view中较多，暂不修改
    static func rsvpStyleOpt(userID: String) -> Bool {
        getDynamicFgValue("calendar_client_new_rsvpcard", userID: userID)
    }

    /// 创建日程同步拉群
    static func clientCreateGroupOption(userID: String) -> Bool {
        getDynamicFgValue("calendar.client.create_group_optional", userID: userID)
    }

    /// 辅助时区calendar.client.additional_time_zone
    static func additionalTimeZoneOption(userID: String) -> Bool {
        let showAdditionalTimeZone = getStaticFgValue("calendar.client.additional_time_zone", userID: userID)
        if Display.pad {
            return showAdditionalTimeZone && CalConfig.isMultiTimeZone
        } else {
            return showAdditionalTimeZone
        }
    }

    /// zoom视频会议
    static func shouldEnableZoom(userID: String) -> Bool {
        getDynamicFgValue("calendar.integrate.zoom", userID: userID)
    }

    /// feed临时置顶事件
    static func feedTopEvent(userID: String) -> Bool {
        getStaticFgValue("lark.im.feed.event", userID: userID)
    }
    
    /// 下掉留言功能
    static func shouldDeleteReply(userID: String) -> Bool {
        getDynamicFgValue("calendar.rsvp.no_reply", userID: userID)
    }
    
    /// 创建页接入MyAI 浮窗模式
    static func canCreateEventInline(userID: String) -> Bool {
        return getStaticFgValue("calendar.myai.create_event_inline", userID: userID) && !GuideService.isGuideNeedShow(key: .globalMyAIInitGuide)
    }
    
    /// 时间容器
    static func taskInCalendar(userID: String) -> Bool {
        return getStaticFgValue("calendar.intergration.taskincalendar", userID: userID)
    }
    
    /// 支持用户可选日历助手，没有记忆功能
    static func assistantNoMemory(userID: String) -> Bool {
        getStaticFgValue("calendar.rsvp.no_memory", userID: userID)
    }
}

public extension FeatureGating {

    static func getFSValue(fsKey: FeatureSwitch.SwitchKey, userID: String, debugValue: Bool = true) -> Bool {
        #if DEBUG
        return debugValue
        #endif
        guard let service = getFGService(userID: userID) else {
            logger.error("get fg service failed")
            return false
        }
        // 获取 fs 的值
        let key = FeatureGatingManager.Key(switch: fsKey)
        let value = service.staticFeatureGatingValue(with: key)
        logger.info("get static fs \(fsKey): \(value)")
        return value
    }

    static func getStaticFgValue(_ fgKey: String, userID: String, debugValue: Bool = true) -> Bool {
        #if DEBUG
        return debugValue
        #endif
        guard let service = getFGService(userID: userID),
              let key = FeatureGatingManager.Key(rawValue: fgKey) else {
            logger.error("get static fg '\(fgKey)' failed")
            return false
        }
        // 使用容器服务获取生命周期内不变的FG
        let value = service.staticFeatureGatingValue(with: key)
        logger.info("get static fg \(fgKey): \(value)")
        return value
    }

    static func getDynamicFgValue(_ fgKey: String, userID: String, debugValue: Bool = true) -> Bool {
        #if DEBUG
        return debugValue
        #endif
        guard let service = getFGService(userID: userID),
              let key = FeatureGatingManager.Key(rawValue: fgKey) else {
            logger.error("get dynamic fg '\(fgKey)' failed")
            return false
        }
        // 使用容器服务获取生命周期内可变的FG
        let value = service.dynamicFeatureGatingValue(with: key)
        logger.info("get dynamic fg \(fgKey): \(value)")
        return value
    }

    static func getFGService(userID: String) -> FeatureGatingService? {
        return try? Container
            .shared
            .getUserResolver(userID: userID, compatibleMode: false)
            .resolve(assert: FeatureGatingService.self)
    }
}
