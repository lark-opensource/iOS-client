//
//  DayInstanceEditViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/8/12.
//

import RxSwift
import CTFoundation
import LarkContainer

/// DayScene - InstanceEdit - ViewModel

final class DayInstanceEditViewModel: UserResolverWrapper {
    let calendarApi: CalendarRustAPI?
    var userResolver: LarkContainer.UserResolver
    @ScopedProvider var calendarManager: CalendarManager?
    @ScopedInjectedLazy var timeDataService: TimeDataService?
    let blockData: BlockDataProtocol?
    let is12HourStyle: Bool
    private let timeZone: TimeZone
    let disposeBag = DisposeBag()

    var disableEncrypt: Bool {
        guard let blockData = blockData else { return false }
        return blockData.process({
            switch $0 {
            case .event(let instance):
                switch instance {
                case .local:
                    return false
                case .rust(let ins):
                    return ins.disableEncrypt
                }
            case .timeBlock, .none, .instanceEntity:
                return false
            }
        })
    }

    var unableDecrypt: Bool {
        guard let blockData = blockData else { return false }
        return blockData.process({
            switch $0 {
            case .event(let instance):
                switch instance {
                case .local:
                    return false
                case .rust(let ins):
                    return ins.displayType == .undecryptable
                }
            case .timeBlock, .none, .instanceEntity:
                return false
            }
        })
    }

    init(calendarApi: CalendarRustAPI?,
         userResolver: UserResolver,
         timeZone: TimeZone,
         is12HourStyle: Bool,
         instance: BlockDataProtocol?) {
        self.calendarApi = calendarApi
        self.timeZone = timeZone
        self.blockData = instance
        self.is12HourStyle = is12HourStyle
        self.userResolver = userResolver
    }

    func dates(from timeScaleRange: TimeScaleRange, julianDay: JulianDay) -> (startDate: Date, endDate: Date) {
        let (fromTimeScale, toTimeScale) = (timeScaleRange.lowerBound, timeScaleRange.upperBound)
        let (fromHour, fromMinute, fromSecond) = fromTimeScale.components()
        let (toHour, toMinute, toSecond) = toTimeScale.components()
        let (year, month, day) = JulianDayUtil.yearMonthDay(from: julianDay)
        var dateComponents = DateComponents()
        dateComponents.timeZone = timeZone
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = fromHour
        dateComponents.minute = fromMinute
        dateComponents.second = fromSecond
        let startDate: Date
        if let date = Calendar.gregorianCalendar.date(from: dateComponents) {
            startDate = date
        } else {
            DayScene.assertionFailure("startDate should not be nil, from: \(dateComponents)")
            startDate = Date()
        }
        dateComponents.hour = toHour
        dateComponents.minute = toMinute
        dateComponents.second = toSecond
        let endDate: Date
        if let date = Calendar.gregorianCalendar.date(from: dateComponents) {
            endDate = date
        } else {
            DayScene.assertionFailure("endDate should not be nil, from: \(dateComponents)")
            endDate = Date()
        }
        return (startDate, endDate)
    }

    func saveEvent(with timeScaleRange: TimeScaleRange, julianDay: JulianDay, actionType: UpdateTimeBlockActionType) -> Stage<Void> {
        guard let blockData = blockData else { return .complete() }
        trackSave(blockData: blockData, actionType: actionType)
        let dates = self.dates(from: timeScaleRange, julianDay: julianDay)
        return blockData.process({
            switch $0 {
            case .event(let instance):
                switch instance {
                case .rust(let rustInstance):
                    return rxSaveToRust(rustInstance, with: dates)
                        .joinStage { _ -> Stage<Void> in
                            return .complete()
                        }
                case .local(let localInstance):
                    return rxSaveToLocal(localInstance, with: dates)
                }
            case .timeBlock(let model):
                return saveTimeBlock(model: model, with: dates, actionType: actionType, is12HourStyle: is12HourStyle)
            case .none, .instanceEntity:
                return .complete()
            }
        })
    }
    
    private func trackSave(blockData: BlockDataProtocol,
                           actionType: UpdateTimeBlockActionType) {
        
        let click: String
        switch actionType {
        case .move:
            click = "move_event"
        case .drag:
            click = "change_event"
        case .unknown:
            click = ""
        @unknown default:
            click = ""
        }
        blockData.process({
            switch $0 {
            case .event(let instance):
                var commonParamData: CommonParamData?
                if case .rust(let pb) = instance {
                    commonParamData = CommonParamData(instance: pb, event: nil)
                }
                CalendarTracerV2.CalendarMain.traceClick {
                    $0.click(click)
                    $0.type = "event"
                    if let data = commonParamData {
                        $0.mergeEventCommonParams(commonParam: data)
                    }
                }
            case .timeBlock(let model):
                CalendarTracerV2.CalendarMain.normalTrackClick {
                    var map = [String: Any]()
                    map["click"] = click
                    map["type"] = "task"
                    map["task_id"] = model.taskId
                    return map
                }
            case .none, .instanceEntity:
                break
            }
        })
    }
}
