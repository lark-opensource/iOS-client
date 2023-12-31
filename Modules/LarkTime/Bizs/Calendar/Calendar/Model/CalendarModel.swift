//
//  EventModel.swift
//  CalendarEvent
//
//  Created by zhuchao on 13/12/2017.
//  Copyright © 2017 EE. All rights reserved.
//

import UIKit
import RustPB
import CalendarFoundation
import LKCommonsLogging
public enum CalendarAccess: Int {
    case privacy = 0
    case freeBusy = 1
    case publicCalendar = 2
}

public protocol CalendarModel {
    typealias CalendarType = RustPB.Calendar_V1_Calendar.TypeEnum
    typealias AccessRole = RustPB.Calendar_V1_Calendar.AccessRole
    typealias Status = RustPB.Calendar_V1_Calendar.Status
    typealias EditAuthInfo = RustPB.Calendar_V1_Calendar.CalendarEditAuthInfo
    typealias ShareOptions = RustPB.Calendar_V1_Calendar.CalendarShareOptions

    /// is calendarID
    var serverId: String { get set }
    var userId: String { get set }
    var type: CalendarType { get }
    // 仅用于齿轮版本日历，可随其下线删除代码
    var backgroundColor: Int32 { get set }
    var isVisible: Bool { get set }

    /// 日历是否同步过
    var isActive: Bool { get }

    /// 会议室是否被禁用
    var isDisabled: Bool { get }

    /// 会议室是否需要审批
    var needApproval: Bool { get }

    /// 是否是主日历 包括lark主日历 和 google主日历 和 exchange主日历
    var isPrimary: Bool { get }
    var selfAccessRole: AccessRole { get }
    var selfStatus: Status { get }
    var weight: Int32 { get }
    var description: String? { get set }
    var parentCalendarPB: RustPB.Calendar_V1_Calendar? { get set }
    var colorIndex: ColorIndex { get set }
    var calendarAccess: CalendarAccess { get set }
    var localizedSummary: String { get }
    var note: String { get set }
    var summary: String { get set }
    var externalAccountName: String { get }
    var avatarKey: String { get set }
    var avatar: UIImage? { get set }
    var shareOptions: ShareOptions { get set }
    func isLarkPrimaryCalendar() -> Bool
    func isLarkMainCalendar() -> Bool
    func isAvailablePrimaryCalendar() -> Bool
    func isOwnerOrWriter() -> Bool
    func canRead() -> Bool
    func displayName() -> String
    func parentDisplayName() -> String
    func isGoogleCalendar() -> Bool
    func isExchangeCalendar() -> Bool
    func getCalendarPB() -> RustPB.Calendar_V1_Calendar
    func isLocalCalendar() -> Bool
    func isLoading(eventViewStartTime: Int64, eventViewEndTime: Int64) -> Bool
    mutating func upgradeCalendarSyncInfo(info: Rust.CalendarSyncInfo)

    /// 日历编辑权限信息
    var editAuthInfo: EditAuthInfo { get }

    /// 三方日历账户是否有效
    var externalAccountValid: Bool { get }

    /// 是否已经订阅
    var hasSubscribed: Bool { get }
}

extension CalendarModel {
    func getCalendarPB() -> RustPB.Calendar_V1_Calendar {
        return RustPB.Calendar_V1_Calendar()
    }

    func isMyOrOthersPrimaryCalendar() -> Bool {
        return self.type == .primary && self.type != .google && self.type != .exchange
    }

    /// 是否是只有freeBusyReader日历
    func isFreeBusyOnlyCalendar() -> Bool {
        return self.selfAccessRole == .freeBusyReader
    }

    // 编辑页日历数据转化
    func toEventEditCalendar() -> EventEditCalendar {
        if let parentPb = self.parentCalendarPB {
            return EventEditCalendar(from: self.getCalendarPB(), parentPb: parentPb)
        } else {
            return EventEditCalendar(from: self.getCalendarPB())
        }
    }
}

struct CalendarModelFromPb: CalendarModel {
    let logger = Logger.log(CalendarModelFromPb.self, category: "CalendarModelFromPb")
    var resourceRequisitions: [Rust.ResourceRequisition] {
        var temp: [Rust.ResourceRequisition] = [Rust.ResourceRequisition]()
        let bizDatas = self.calendarPB.schemaExtraData.bizData
        for data in bizDatas where data.type == .resourceRequisition {
                temp.append(data.resourceRequisition)
        }
        return temp
    }

    var isDisabled: Bool {
        return self.calendarPB.isDisabled
    }

    var needApproval: Bool {
        return self.calendarPB.calendarSchema.hasApprovalKey
    }

    var summary: String {
        get {
            return calendarPB.summary
        }
        set {
            calendarPB.summary = newValue
        }
    }

    var avatarKey: String {
        get {
            return calendarPB.coverImageSet.origin.key
        }
        set {
            calendarPB.coverImageSet.origin.key = newValue
        }
    }

    var avatar: UIImage?

    var calendarAccess: CalendarAccess {
        get {
            if calendarPB.isPublic, calendarPB.defaultAccessRole == .freeBusyReader {
                return .freeBusy
            } else if calendarPB.isPublic, calendarPB.defaultAccessRole == .reader {
                return .publicCalendar
            } else {
                return .privacy
            }
        }
        set {
            switch newValue {
            case .freeBusy:
                calendarPB.isPublic = true
                calendarPB.defaultAccessRole = .freeBusyReader
            case .privacy:
                calendarPB.isPublic = false
                calendarPB.defaultAccessRole = .freeBusyReader
            case .publicCalendar:
                calendarPB.isPublic = true
                calendarPB.defaultAccessRole = .reader
            }
        }
    }

    var externalAccountName: String {
        return self.calendarPB.externalAccountEmail
    }

    var hasSubscribed: Bool {
        get { return self.calendarPB.isSubscriber }
        set { self.calendarPB.isSubscriber = newValue }
    }

    var isActive: Bool {
        return self.calendarPB.isActive
    }

    var externalAccountValid: Bool {
        return !self.calendarPB.externalPasswordInvalid
    }

    var colorIndex: ColorIndex {
        get {
            return self.calendarPB.personalizationSettings.colorIndex
        }
        set {
            self.calendarPB.personalizationSettings.colorIndex = newValue
        }
    }

    var serverId: String {
        get {
            return self.calendarPB.serverID
        }
        set {
            self.calendarPB.serverID = newValue
        }
    }

    var userId: String {
        get { return self.calendarPB.userID }
        set { self.calendarPB.userID = newValue }
    }

    // 日历类型
    var type: CalendarType {
        return self.calendarPB.type
    }

    var backgroundColor: Int32 {
        get {
            return self.calendarPB.backgroundColor
        }
        set {
            self.calendarPB.backgroundColor = newValue
        }
    }

    var isVisible: Bool {
        get { return self.calendarPB.isVisible }
        set { self.calendarPB.isVisible = newValue }
    }

    var isPrimary: Bool {
        return self.calendarPB.isPrimary
    }

    var selfAccessRole: AccessRole {
        return self.calendarPB.selfAccessRole
    }
    var selfStatus: Status {
        return self.calendarPB.selfStatus
    }

    var weight: Int32 {
        return self.calendarPB.weight
    }

    var description: String? {
        get {
            return self.calendarPB.description_p
        }
        set {
            if let description = newValue {
                self.calendarPB.description_p = description
            } else {
                self.calendarPB.clearDescription_p()
            }
        }
    }

    var localizedSummary: String {
        return calendarPB.localizedSummary
    }

    var note: String {
        get { return self.calendarPB.note }
        set { self.calendarPB.note = newValue }
    }

    var editAuthInfo: EditAuthInfo {
        return calendarPB.authInfo.editAuthInfo
    }

    var shareOptions: ShareOptions {
        get { calendarPB.shareOptions }
        set { calendarPB.shareOptions = newValue }
    }

    private var calendarPB: RustPB.Calendar_V1_Calendar

    var parentCalendarPB: RustPB.Calendar_V1_Calendar?
    init(pb: RustPB.Calendar_V1_Calendar) {
        self.calendarPB = pb
    }

    func getCalendarPB() -> RustPB.Calendar_V1_Calendar {
        return self.calendarPB
    }

    func isOwnerOrWriter() -> Bool {
        return self.selfAccessRole == .owner || self.selfAccessRole == .writer
    }

    func canRead() -> Bool {
        return self.selfAccessRole == .owner || self.selfAccessRole == .writer || self.selfAccessRole == .reader
    }

    // 是否是lark的主日历, isPrimary的逻辑与用户有关，用户自己看自己的主日历 isPrimary == true，其他人看不是
    func isLarkPrimaryCalendar() -> Bool {
        // isPrimary包含goole主日历和lark主日历
        return self.isPrimary && self.type != .google && self.type != .exchange
    }

    // 是否是Lark的默认日历。默认日历是type == .primary，以后SDK会换个名字
    func isLarkMainCalendar() -> Bool {
        return self.type == .primary
    }

    // 默认日历是否是主日历
    func isAvailablePrimaryCalendar() -> Bool {
        return self.isPrimary && self.type == .primary
    }

    func displayName() -> String {
        // 日历名称和备注
        let summary = calendarPB.localizedSummary.isEmpty ? calendarPB.summary : calendarPB.localizedSummary
        let note = calendarPB.note.isEmpty ? summary : calendarPB.note
        return summary
    }

    func parentDisplayName() -> String {
        guard let parentCalendarPB = parentCalendarPB else {
            return displayName()
        }
        if parentCalendarPB.note.isEmpty {
            return parentCalendarPB.localizedSummary
        }
        return parentCalendarPB.note
    }

    func isGoogleCalendar() -> Bool {
        return type == .google
    }

    func isExchangeCalendar() -> Bool {
        return type == .exchange
    }

    func isLocalCalendar() -> Bool {
        return false
    }

    // 为防止时序问题，syncInfo 仅做数据升级用来取消 loading 状态
    mutating func upgradeCalendarSyncInfo(info: Rust.CalendarSyncInfo) {
        let isSyncDoneOld = !calendarPB.calendarSyncInfo.isSyncing
        let isSyncDoneNew = !info.isSyncing
        calendarPB.calendarSyncInfo.isSyncing = !(isSyncDoneOld || isSyncDoneNew)

        let oldMinInstanceCacheTime = calendarPB.calendarSyncInfo.minInstanceCacheTime
        let newMinInstanceCacheTime = info.minInstanceCacheTime

        let oldMaxInstanceCacheTime = calendarPB.calendarSyncInfo.maxInstanceCacheTime
        let newMaxInstanceCacheTime = info.maxInstanceCacheTime

        if oldMinInstanceCacheTime == 0 || oldMaxInstanceCacheTime == 0 {
            calendarPB.calendarSyncInfo.minInstanceCacheTime = newMinInstanceCacheTime
            calendarPB.calendarSyncInfo.maxInstanceCacheTime = newMaxInstanceCacheTime
        } else {
            calendarPB.calendarSyncInfo.minInstanceCacheTime = min(oldMinInstanceCacheTime, newMinInstanceCacheTime)
            calendarPB.calendarSyncInfo.maxInstanceCacheTime = max(oldMaxInstanceCacheTime, newMaxInstanceCacheTime)
        }
        logger.info("upgradeCalendar calendarID \(info.calendarID) isSyncing \(calendarPB.calendarSyncInfo.isSyncing), \(calendarPB.calendarSyncInfo.minInstanceCacheTime)-\(calendarPB.calendarSyncInfo.maxInstanceCacheTime), \(info.minInstanceCacheTime)-\(info.maxInstanceCacheTime)")
    }

    func isLoading(eventViewStartTime: Int64, eventViewEndTime: Int64) -> Bool {
        var isLoading = false

        if !calendarPB.calendarSyncInfo.isSyncing {
            isLoading = false
        } else if eventViewStartTime >= calendarPB.calendarSyncInfo.minInstanceCacheTime
            && eventViewEndTime <= calendarPB.calendarSyncInfo.maxInstanceCacheTime {
            isLoading = false
        } else {
            isLoading = true
        }

        logger.info("get isLoading calendarID \(calendarPB.serverID) \(eventViewStartTime))-\(eventViewEndTime), \(calendarPB.calendarSyncInfo.minInstanceCacheTime)-\(calendarPB.calendarSyncInfo.maxInstanceCacheTime) - isVisiable \(calendarPB.isVisible) isLoading \(isLoading)")

        return isLoading
    }

    static func defaultCalendar(skinType: CalendarSkinType) -> CalendarModel {
        var pb = Calendar_V1_Calendar()
        pb.isPublic = false
        pb.defaultAccessRole = .freeBusyReader
        pb.selfAccessRole = .owner
        pb.type = .other
        pb.id = ""
        pb.serverID = ""
        pb.note = ""
        let defaultColor: ColorIndex = .carmine
        pb.personalizationSettings.colorIndex = defaultColor
        // for 齿轮版
        pb.backgroundColor = colorToRGB(color: SkinColorHelper.pickerColor(of: defaultColor.rawValue))
        var defaultShareOpts = Rust.CalendarShareOptions()
        defaultShareOpts.crossTopShareOption = .shareOptReader
        defaultShareOpts.defaultShareOption = .shareOptFreeBusyReader
        defaultShareOpts.crossDefaultShareOption = .shareOptFreeBusyReader
        pb.shareOptions = defaultShareOpts
        return CalendarModelFromPb(pb: pb)
    }
}

func == (lhs: CalendarModel, rhs: CalendarModel) -> Bool {
    return lhs.summary == rhs.summary &&
        lhs.note == rhs.note &&
        lhs.calendarAccess == rhs.calendarAccess &&
        lhs.colorIndex == rhs.colorIndex &&
        lhs.description == rhs.description &&
        lhs.avatarKey == rhs.avatarKey
}

extension CalendarAccess {
    func toLocalString() -> String {
        switch self {
        case .freeBusy:
            return BundleI18n.Calendar.Calendar_Setting_ShowOnlyFreeBusy
        case .privacy:
            return BundleI18n.Calendar.Calendar_SubscribeCalendar_Private
        case .publicCalendar:
            return BundleI18n.Calendar.Calendar_Edit_Public
        }
    }
}
