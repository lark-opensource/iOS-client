
//
//  TimeDataModel.swift
//  Calendar
//
//  Created by JackZhao on 2023/12/15.
//

import RxSwift
import RxRelay
import Foundation
import CTFoundation
import LKCommonsLogging
import CalendarFoundation
import UniverseDesignIcon
import LarkTimeFormatUtils

// 用来排序的视图块类型兼容协议
struct BlockSortModel {
    var startTime: Int64
    var endTime: Int64
    var startDay: Int32
    var endDay: Int32
    var isAllDay: Bool
    var title: String
    var sortKey: String
}

extension MonthItem {
    func transfromToSortModel() -> BlockSortModel {
        return BlockSortModel(startTime: startTime, endTime: endTime, startDay: startDay, endDay: endDay, isAllDay: isAllDay, title: title, sortKey: sortKey)
    }
}

extension BlockDataProtocol {
    func transfromToSortModel() -> BlockSortModel {
        return BlockSortModel(startTime: startTime, endTime: endTime, startDay: startDay, endDay: endDay, isAllDay: isAllDay, title: title, sortKey: sortKey)
    }
}

extension MonthBlockViewCellProtocol {
    func transfromToSortModel() -> BlockSortModel {
        return BlockSortModel(startTime: startTime, endTime: endTime, startDay: startDay, endDay: endDay, isAllDay: isAllDay, title: titleText, sortKey: id)
    }
}

class TimeBlockUtils {
    struct Resource {
        static let normalIcon = UDIcon.ellipseOutlined
        static let finishIcon = UDIcon.yesFilled
        // 里程碑
        static let milestoneNormalIcon = UDIcon.milestoneCalendarOutlined
        static let milestoneFinishIcon = UDIcon.milestoneCalendarFilled
    }
    struct Config {
        static let tapIconLimitWidth: CGFloat = 48
        static let tapIconTapSize: CGSize = .init(width: 24, height: 24)
        static let darkSceneBlockIconColor = UIColor.ud.staticWhite
    }
    
    static func getTitleColor(helper: SkinColorHelper,
                              model: TimeBlockModel) -> UIColor {
        let textColor = helper.eventTextColor
        let isCompleted = model.taskBlockModel?.isCompleted == true
        let isLight = helper.skinType == .light
        if isLight, isCompleted {
            return textColor.withAlphaComponent(0.7)
        }
        if !isLight, isCompleted {
            return textColor.withAlphaComponent(0.8)
        }
        return textColor
    }

    
    static func getMaskOpacity(helper: SkinColorHelper,
                               model: TimeBlockModel) -> Float {
        let isCompleted = model.taskBlockModel?.isCompleted == true
        let isLight = helper.skinType == .light
        if isCompleted, isLight { return 0.5 }
        if !isCompleted, isLight { return 0.55 }
        if !isLight { return 0.5 }
        return 0
    }
    
    // 视图块排序逻辑（只有日视图非全天不用）
    /// 排序策略：
    /// 1. 按照开始天排（越早越靠前面）
    /// 2. 按照持续天数排（越长越靠前面）
    /// 3. 全天优先于跨天
    /// 4. 开始时间（越早越靠前面）
    /// 5. 时长（越长越靠前）
    /// 6. 根据 title 排序: 根据编码大小排序，例如1在2前面、a在b前面
    /// 7. 当标题相同时，使用key进行兜底
    static func sortBlock(lhs: BlockSortModel, rhs: BlockSortModel) -> Bool {
        if lhs.startDay != rhs.startDay {
            return lhs.startDay < rhs.startDay
        }
        if lhs.endDay != rhs.endDay {
            return lhs.endDay > rhs.endDay
        }
        let lhsIsAllDay = lhs.isAllDay
        let rhsIsAllDay = rhs.isAllDay
        // 开始截止天一样的，优先把全天日程放前面
        if lhsIsAllDay, !rhsIsAllDay {
            return true
        }
        if !lhsIsAllDay, rhsIsAllDay {
            return false
        }
        if lhs.startTime != rhs.startTime {
            return  lhs.startTime < rhs.startTime
        }
        if lhs.endTime != rhs.endTime {
            return lhs.endTime > rhs.endTime
        }
        if lhs.title != rhs.title {
            return lhs.title < rhs.title
        }
        return lhs.sortKey < rhs.sortKey
    }
    
    static func getIcon(model: TimeBlockModel,
                        isLight: Bool,
                        color: UIColor,
                        selectedColor: UIColor) -> UIImage {
        switch model.source {
        case .task:
            let isCompleted = model.taskBlockModel?.isCompleted == true
            let isMilestone = model.taskBlockModel?.isMilestone == true
            let alpha = isLight ? 1 : 0.6
            // 里程碑任务
            if isMilestone {
                let image = isCompleted ? Resource.milestoneFinishIcon.ud.withTintColor(selectedColor.withAlphaComponent(alpha)) : Resource.milestoneNormalIcon.ud.withTintColor(color.withAlphaComponent(alpha))
                return image
            }
            let image = isCompleted ? Resource.finishIcon.ud.withTintColor(selectedColor.withAlphaComponent(alpha)) : Resource.normalIcon.ud.withTintColor(color.withAlphaComponent(alpha))
            return image
        case .other:
            assertionFailure("not support")
            return UIImage()
        }
    }
    
    // 日程和月视图时间描述
    static func getTimeDescription(model: TimeBlockModel,
                                   currentDate: Date,
                                   is12HourStyle: Bool) -> String {
        // 有开始时间，有截止时间
        if model.hasStartTimeForTask, model.hasEndTimeForTask {
            return TimeUtils.timeDescription(isOverOneDay: model.isOverOneDay,
                                             endDay: model.endDay,
                                             startDay: model.startDay,
                                             isAllDay: model.isAllDay,
                                             startDate: model.startDate,
                                             endDate: model.endDate,
                                             currentDate: currentDate,
                                             calendar: .gregorianCalendar,
                                             is12HourStyle: is12HourStyle).1
        }
        // 全天日程
        if model.isAllDay {
            return BundleI18n.Calendar.Calendar_Edit_Allday
        }
        // 无开始时间，无截止时间 => 当做全天日程处理
        if !model.hasStartTimeForTask, !model.hasEndTimeForTask {
            return BundleI18n.Calendar.Calendar_Edit_Allday
        }
        // 仅有开始日期  => 当作全天日程处理
        if model.startDay != 0, model.endDay == 0 {
            return BundleI18n.Calendar.Calendar_Edit_Allday
        }
        // 仅有结束日期  => 当作全天日程处理
        if model.startDay == 0, model.endDay != 0 {
            return BundleI18n.Calendar.Calendar_Edit_Allday
        }
        // 有开始时间，无截止时间
        if model.hasStartTimeForTask, !model.hasEndTimeForTask {
            return getTimeDesc(date: model.startDate, hasStartTime: true)
        }
        // 无开始时间，有截止时间
        if !model.hasStartTimeForTask, model.hasEndTimeForTask {
            return getTimeDesc(date: model.endDate, hasStartTime: false)
        }
        return ""
        func getTimeDesc(date: Date, hasStartTime: Bool) -> String {
            var customOptions = Options(
                is12HourStyle: is12HourStyle,
                timeFormatType: .short,
                timePrecisionType: .minute,
                shouldRemoveTrailingZeros: true
            )
            let timeDesc = TimeFormatUtils.formatTime(from: date, with: customOptions)
            let formatteredTime = formatterTime(timeDesc)
            // 非跨天场景：12:00开始
            if !model.isOverOneDay {
                return formatteredTime
            }
            // 跨天场景
            let dateDay = date.day
            let dateYear = date.year
            let currentDateDay = currentDate.day
            let currentDateYear = currentDate.year
            // 当前天：12:00开始
            if dateDay == currentDateDay {
                return formatteredTime
            }
            // 非当前天:
            // 跨年: 2022年1月3日(明天) 00:15 开始
            if dateYear != currentDateYear {
                customOptions.timeFormatType = .long
                customOptions.dateStatusType = .relative
                customOptions.relativeDate = currentDate
                let dateTimeDesc = TimeFormatUtils.formatFullDateTime(from: date, with: customOptions)
                return formatterTime(dateTimeDesc)
            } else {
                // 不跨年: 1月3日(昨天) 00:15 开始
                customOptions.timeFormatType = .short
                customOptions.datePrecisionType = .day
                let dateDesc = TimeFormatUtils.formatDate(from: date, with: customOptions)
                // 明天/昨天
                let relativeDay = hasStartTime ? I18n.Calendar_StandardTime_RelativeDayYesterday : I18n.Calendar_StandardTime_RelativeDayTomorrow
                customOptions.timeFormatType = .short
                let relativeDateDesc = I18n.Calendar_StandardTime_DateRelativeDayCombineFormat(relativeDay: relativeDay, date: dateDesc)
                let timeDesc = TimeFormatUtils.formatTime(from: date, with: customOptions)
                let relativeDateTimeDesc = I18n.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: relativeDateDesc, time: timeDesc)
                return formatterTime(relativeDateTimeDesc)
            }
            func formatterTime(_ time: String) -> String {
                if hasStartTime {
                    return I18n.Calendar_G_StartFromThisDay_Desc(date: time)
                }
                return I18n.Calendar_G_EndOnThisDay_Desc(date: time)
            }
        }
    }

    static func getOverDaySummary(model: TimeBlockModel,
                                  currentDate: Date,
                                  is12HourStyle: Bool) -> String {
        // 跨天
        if model.isOverOneDay {
            let dayNumber = model.endDay - model.startDay + 1
            let appearTimes = Calendar.gregorianCalendar.dateComponents([.day],
                                                                        from: model.startDate.dayStart(),
                                                                        to: currentDate.dayStart()).day ?? 0
            let overDayInfo = BundleI18n.Calendar.Calendar_View_AlldayInfo(day: appearTimes + 1, total: dayNumber)
            return overDayInfo
        }
        return ""
    }
}

enum TimeBlockSource: String {
    case task
    case other
}

// 客户端定义的任务块模型
struct TaskBlockModel {
    var taskGuid: String
    // 是否完成任务
    var isCompleted: Bool
    // 是否是里程碑任务
    var isMilestone: Bool
    // 创建时间
    var createMilliTime: Int64
    // 更新时间
    var updateMilliTime: Int64
}

// 客户端定义的时间块模型
struct TimeBlockModel {
    var id: String
    var customId: String
    var source: TimeBlockSource = .other
    var title: String
    var hasStartTimeForTask: Bool
    var hasEndTimeForTask: Bool
    var startTime: Int64 = 0
    var endTime: Int64 = 0
    var startDate: Date
    var endDate: Date
    var startDay: Int32 = 0
    var endDay: Int32 = 0
    var sortTime: Int64
    var startMinute: Int32 = 0
    var endMinute: Int32 = 0
    var isAllDay = false
    var timezone: String
    let containerIDOnDisplay: String
    // 暂时都支持
    var canMove = true
    var canDrag = true
    var taskBlockModel: TaskBlockModel?
    var colorIndex: ColorIndex?
    // 是否跨天
    var isOverOneDay: Bool {
        return !Calendar.gregorianCalendar.isDate(startDate, inSameDayAs: endDate - 1)
    }

    // 通过RustPB的模型初始化
    init(pbModel: TimeBlock, container: TimeContainer? = nil) {
        self.id = pbModel.blockID
        self.containerIDOnDisplay = pbModel.containerIDOnDisplay
        self.source = TimeBlockSource(rawValue: pbModel.appID) ?? .other
        self.startTime = pbModel.startTime
        self.endTime = pbModel.endTime
        let startDate = Date(timeIntervalSince1970: TimeInterval(pbModel.startTime))
        let endDate = Date(timeIntervalSince1970: TimeInterval(pbModel.endTime))
        if pbModel.isAllDay {
            self.startDate = startDate.utcToLocalDate()
            self.endDate = endDate.utcToLocalDate()
        } else {
            self.startDate = startDate
            self.endDate = endDate
        }
        self.startDay = pbModel.startDay
        self.endDay = pbModel.endDay
        self.startMinute = pbModel.startMinute
        self.endMinute = pbModel.endMinute
        self.isAllDay = pbModel.isAllDay
        self.customId = pbModel.customID
        self.timezone = pbModel.timezone
        self.colorIndex = container?.colorIndex
        let taskData = pbModel.data.taskAttribute
        let taskBlockModel = TaskBlockModel(taskGuid: taskData.taskGuid, isCompleted: taskData.displayIsCompleted, isMilestone: taskData.isMilestone, createMilliTime: taskData.createMilliTime, updateMilliTime: taskData.updateMilliTime)
        self.sortTime = taskData.createMilliTime
        self.taskBlockModel = taskBlockModel
        self.title = taskData.richSummary.richText.lc.summerize()
        self.sortTime = taskData.createMilliTime
        self.hasStartTimeForTask = pbModel.data.taskAttribute.hasStartTime_p
        self.hasEndTimeForTask = pbModel.data.taskAttribute.hasEndTime_p
    }
}

// MARK: 业务扩展
extension TimeBlockModel {
    var taskId: String {
        return taskBlockModel?.taskGuid ?? ""
    }

    // 是否当做全天日程
    func shouldTreatedAsAllDay() -> Bool {
        if isAllDay { return true }
        if endTime - startTime >= ViewPageInfo.secondOfOneDay { return true }
        guard endTime - startTime >= ViewPageInfo.secondOf23Hours else { return false }
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTime))
        return startTime == Int64(startDate.dayStart().timeIntervalSince1970)
    }

    func dayRange(in timeZone: TimeZone = .current) -> JulianDayRange {
        return Int(startDay)..<Int(endDay) + 1
    }
}

// 客户端时间容器模型
struct TimeContainerModel {
    
    var displayName: String {
        if pb.type == "my_task" && pb.appID == "task" {
            return I18n.Calendar_G_MyTasks_Desc
        } else {
            return ""
        }
    }
    
    var serverID: String { pb.serverID }
    
    var colorIndex: ColorIndex {
        get { pb.colorIndex }
        set { pb.colorIndex = newValue }
    }
    
    var isVisible: Bool {
        get { pb.isVisible }
        set { pb.isVisible = newValue }
    }
    
    private var pb: Rust.TimeContainer
    
    init(pb: Rust.TimeContainer) {
        self.pb = pb
    }
}
