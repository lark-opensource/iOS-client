//
//  ReminderModel.swift
//  SpaceKit
//
//  Created by nine on 2019/3/18.
//

import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignDatePicker

public struct ReminderModel: Equatable {
    
    // Common
    public var id: String? // docs 里面指的是 reminder block id，sheet 里面指的是 sheet 子表的 id
    public var expireTime: TimeInterval? //
    public var shouldSetTime: Bool?
    public var notifyStrategy: ReminderNoticeStrategy? // 策略的枚举描述，doc 用 desc，sheet 用 rawValue
    
    // Docx
    public var mentions: [String]? //被提醒人姓名
    public var isCreateTaskSwitchOn: Bool = false //是否创建任务项
    // Sheets
    public var notifyUsers: [ReminderUserModel]? // 提醒人
    public var notifyText: String? // 提醒备注文字

    public init() {} // all nil

    /// Docs & DocX
    public init(reminderBlockID: String?, expireTime: TimeInterval?, isWholeDay: Bool?, notifyTime: String?, mentions: [String]? = nil) {
        
        self.id = reminderBlockID
        self.expireTime = expireTime
        self.mentions = mentions
        if let isWholeDay = isWholeDay {
            self.shouldSetTime = !isWholeDay
        }
        if let notifyTime = notifyTime {
            self.notifyStrategy = ReminderNoticeStrategy(desc: notifyTime)
        }
    }

    /// Sheets
    /// Calling this method ensures `self.notifyUsers` and `self.notifyText` are nonnull.
    public init(sheetID: String?, expireTime: TimeInterval?, isSetTime: Bool?, notifyStrategy: Int?, notifyUsers: [[String: String]], notifyText: String?) {
        self.id = sheetID
        self.expireTime = expireTime
        if let isSetTime = isSetTime {
            self.shouldSetTime = isSetTime
        }
        if let notifyStrategy = notifyStrategy {
            self.notifyStrategy = ReminderNoticeStrategy(rawValue: notifyStrategy) ?? .noAlert
        }
        self.notifyUsers = []
        for user in notifyUsers {
            if let id = user["id"],
               let name = user["name"],
               let enName = user["enName"],
               let avatarURL = user["avatarUrl"] {
                self.notifyUsers?.append(ReminderUserModel(id: id, name: name, enName: enName, avatarURL: avatarURL))
            }
        }
        self.notifyText = notifyText ?? ""
    }
}

public struct ReminderUserModel: Equatable, Encodable {
    public var id: String
    public var name: String
    public var enName: String
    public var avatarURL: String

    public var asSTModel: BTCapsuleModel {
        BTCapsuleModel(id: id,                 // dummy
                       text: DocsSDK.currentLanguage == .en_US ? (enName.isEmpty ? name : enName) : name,
                       color: BTColorModel(),  // dummy
                       isSelected: true,       // dummy
                       avatarUrl: avatarURL,
                       userID: id,
                       name: name,
                       enName: enName)
    }
}

public enum ReminderNoticeStrategy: Int {
    // 纯 Docs 的
    case noAlert = -1
    // 通用具体时间
    case atTimeOfEvent = 0
    case fiveMinutesBefore = 1
    case aQuarterBefore = 2
    case halfAnHourBefore = 3
    case anHourBefore = 4
    case twoHoursBefore = 5
    // 通用整日提醒 (默认当天九点)
    case onDayOfEventAt9am = 6
    case aDayBeforeAt9am = 7
    case twoDaysBeforeAt9am = 8
    case aWeekBeforeAt9am = 9
    // 通用整日提醒（没有九点）
    case aDayBefore = 10
    case twoDaysBefore = 11
    case aWeekBefore = 12

    // doc 用 desc 和前端通信，sheet 用 rawValue 和前端通信
    public var desc: String {
        switch self {
        case .noAlert: return "noAlert"
        case .atTimeOfEvent: return "atTimeOfEvent"
        case .fiveMinutesBefore: return "before5Mins"
        case .aQuarterBefore: return "before15Mins"
        case .halfAnHourBefore: return "before30Mins"
        case .anHourBefore: return "before1Hour"
        case .twoHoursBefore: return "before2Hours"
        case .onDayOfEventAt9am: return "onDayOfEvent"
        case .aDayBeforeAt9am: return "oneDayBefore"
        case .twoDaysBeforeAt9am: return "twoDaysBefore"
        case .aWeekBeforeAt9am: return "oneWeekBefore"
        case .aDayBefore: return "before1Day"
        case .twoDaysBefore: return "before2Days"
        case .aWeekBefore: return "before1Week"
        }
    }

    public init(desc: String) {
        switch desc {
        case "noAlert": self = .noAlert
        case "atTimeOfEvent": self = .atTimeOfEvent
        case "before5Mins": self = .fiveMinutesBefore
        case "before15Mins": self = .aQuarterBefore
        case "before30Mins": self = .halfAnHourBefore
        case "before1Hour": self = .anHourBefore
        case "before2Hours": self = .twoHoursBefore
        case "onDayOfEvent": self = .onDayOfEventAt9am
        case "oneDayBefore": self = .aDayBeforeAt9am
        case "twoDaysBefore": self = .twoDaysBeforeAt9am
        case "oneWeekBefore": self = .aWeekBeforeAt9am
        case "before1Day": self = .aDayBefore
        case "before2Days": self = .twoDaysBefore
        case "before1Week": self = .aWeekBefore
        default: self = .noAlert
        }
    }
}

public struct ReminderVCConfig {
    public let selectColor: SelectColor
    public let titleColor: TitleColor
    public var datePickerConfig: DatePickerConfig
    public let noticePickerConfig: NoticePickerConfig
    public var showWholeDaySwitch: Bool = false
    public var deadlineText: String? //到期时间自定义文案
    public var showDeadlineTips: Bool { deadlineText != nil }
    public var showPickTimeSwitch: Bool = true //是否显示设置时间项
    public var showNoticeItem: Bool = true //是否显示提醒项
    public var isShowCreateTaskSwitch: Bool = false //是否显示创建任务
    public var autoCorrectExpireTimeBlock: ((Date) -> Date?)? //自动修正过期时间Block
    
    

    public struct SelectColor {
        let pastDay: UIColor
        let rencent6Day: UIColor
        let lasterDay: UIColor
        let today: UIColor
    }

    public struct TitleColor {
        let currentMonth: UIColor
        let otherMonth: UIColor
        let isSeleted: UIColor
    }

    public struct DatePickerConfig {
        let minuteInterval: Int
        let datePickerMode: UDWheelsStyleConfig.WheelModel
        public init(minuteInterval: Int, datePickerMode: UDWheelsStyleConfig.WheelModel) {
            self.minuteInterval = minuteInterval
            self.datePickerMode = datePickerMode
        }
    }

    public struct NoticePickerConfig {
        let noticeOnADay:    [(key: ReminderNoticeStrategy, value: String)]
        let noticeAtAMoment: [(key: ReminderNoticeStrategy, value: String)]
    }

    public static var `default`: ReminderVCConfig {
        let selectColor = SelectColor(pastDay: UDColor.colorfulRed,
                                      rencent6Day: UDColor.colorfulOrange,
                                      lasterDay: UDColor.colorfulBlue,
                                      today: UDColor.N400)
        let titleColor = TitleColor(currentMonth: UDColor.N900,
                                    otherMonth: UDColor.N500,
                                    isSeleted: UDColor.primaryOnPrimaryFill)
        let datePickerConfig = DatePickerConfig(minuteInterval: 5, datePickerMode: .hourMinuteCenter)
        let noticePickerConfig = NoticePickerConfig(
            noticeOnADay: [(.noAlert, BundleI18n.SKResource.Doc_Reminder_NoAlert),
                           (.onDayOfEventAt9am, BundleI18n.SKResource.Doc_Reminder_OnDayOfEvent9am),
                           (.aDayBeforeAt9am, BundleI18n.SKResource.Doc_Reminder_OneDayBefore9am),
                           (.twoDaysBeforeAt9am, BundleI18n.SKResource.Doc_Reminder_TwoDaysBefore9am),
                           (.aWeekBeforeAt9am, BundleI18n.SKResource.Doc_Reminder_OneWeekBefore9am)],
            noticeAtAMoment: [(.noAlert, BundleI18n.SKResource.Doc_Reminder_NoAlert),
                              (.atTimeOfEvent, BundleI18n.SKResource.Doc_Reminder_AtTimeOfEvent),
                              (.fiveMinutesBefore, BundleI18n.SKResource.Doc_Reminder_5MinsBefore),
                              (.aQuarterBefore, BundleI18n.SKResource.Doc_Reminder_15MinsBefore),
                              (.halfAnHourBefore, BundleI18n.SKResource.Doc_Reminder_30MinsBefore),
                              (.anHourBefore, BundleI18n.SKResource.Doc_Reminder_1HourBefore),
                              (.twoHoursBefore, BundleI18n.SKResource.Doc_Reminder_2HoursBefore),
                              (.aDayBefore, BundleI18n.SKResource.Doc_Reminder_1DayBefore),
                              (.twoDaysBefore, BundleI18n.SKResource.Doc_Reminder_2DaysBefore),
                              (.aWeekBefore, BundleI18n.SKResource.Doc_Reminder_1WeekBefore)]
        )
        return ReminderVCConfig(selectColor: selectColor,
                                titleColor: titleColor,
                                datePickerConfig: datePickerConfig,
                                noticePickerConfig: noticePickerConfig,
                                showWholeDaySwitch: false)
    }

    // sheet 对于颜色和提醒策略和 docs 都不一样
    public static var sheet: ReminderVCConfig {
        let selectColor = SelectColor(pastDay: UDColor.colorfulBlue,
                                      rencent6Day: UDColor.colorfulBlue,
                                      lasterDay: UDColor.colorfulBlue,
                                      today: UDColor.N400)
        let titleColor = TitleColor(currentMonth: UDColor.N900,
                                    otherMonth: UDColor.N500,
                                    isSeleted: UDColor.primaryOnPrimaryFill)
        let datePickerConfig = DatePickerConfig(minuteInterval: 5, datePickerMode: .hourMinuteCenter)
        let noticePickerConfig = NoticePickerConfig(
            noticeOnADay: [(.noAlert, BundleI18n.SKResource.Doc_Reminder_NoAlert),
                           (.onDayOfEventAt9am, BundleI18n.SKResource.Doc_Reminder_OnDayOfEvent9am),
                           (.aDayBeforeAt9am, BundleI18n.SKResource.Doc_Reminder_OneDayBefore9am),
                           (.twoDaysBeforeAt9am, BundleI18n.SKResource.Doc_Reminder_TwoDaysBefore9am),
                           (.aWeekBeforeAt9am, BundleI18n.SKResource.Doc_Reminder_OneWeekBefore9am)],
            noticeAtAMoment: [(.noAlert, BundleI18n.SKResource.Doc_Reminder_NoAlert),
                              (.atTimeOfEvent, BundleI18n.SKResource.Doc_Reminder_AtTimeOfEvent),
                              (.fiveMinutesBefore, BundleI18n.SKResource.Doc_Reminder_5MinsBefore),
                              (.aQuarterBefore, BundleI18n.SKResource.Doc_Reminder_15MinsBefore),
                              (.halfAnHourBefore, BundleI18n.SKResource.Doc_Reminder_30MinsBefore),
                              (.anHourBefore, BundleI18n.SKResource.Doc_Reminder_1HourBefore),
                              (.twoHoursBefore, BundleI18n.SKResource.Doc_Reminder_2HoursBefore),
                              (.aDayBefore, BundleI18n.SKResource.Doc_Reminder_1DayBefore),
                              (.twoDaysBefore, BundleI18n.SKResource.Doc_Reminder_2DaysBefore),
                              (.aWeekBefore, BundleI18n.SKResource.Doc_Reminder_1WeekBefore)]
        )
        return ReminderVCConfig(selectColor: selectColor,
                                titleColor: titleColor,
                                datePickerConfig: datePickerConfig,
                                noticePickerConfig: noticePickerConfig,
                                showWholeDaySwitch: false)
    }
}
