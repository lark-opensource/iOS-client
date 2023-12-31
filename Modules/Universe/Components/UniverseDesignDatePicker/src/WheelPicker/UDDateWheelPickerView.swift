//
//  UDDateWheelPickerView.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/3/17.
//

import UIKit
import Foundation
import LarkTimeFormatUtils
import LarkLocalizations

public final class UDDateWheelPickerView: UIView {
    private var wheelModel: DateWheelContentModelType
    private let wheelPicker: UDWheelPickerView
    private let wheelStyle: UDWheelsStyleConfig

    private var initialDateComp: DateComponents
    // 日期改变回调
    public var dateChanged: ((Date) -> Void)?
    public var dateChangedOnCompleted: (([UDWheelPickerCell]) -> Void)?
    public init(date: Date = Date(),
                timeZone: TimeZone = .current,
                maximumDate: Date = UDWheelsStyleConfig.defaultMaxDate,
                minimumDate: Date = UDWheelsStyleConfig.defaultMinDate,
                wheelConfig: UDWheelsStyleConfig = UDWheelsStyleConfig(maxDisplayRows: 3)) {
        wheelStyle = wheelConfig
        let dateClamped = min(max(date, minimumDate), maximumDate)
        let dateType = UDDateWheelPickerView.wheelDateType(model: wheelStyle.mode,
                                                           date: dateClamped,
                                                           timeZone: timeZone,
                                                           maximumDate: maximumDate,
                                                           minimumDate: minimumDate)
        let rows = Int(ceil((wheelConfig.pickerHeight - 48) / (2.0 * 48)) * 2 + 1)
        // 根据mode初始化 wheelPicker
        wheelModel = DateWheelContentModel(type: dateType,
                                           rows: rows,
                                           timeZone: timeZone,
                                           minDate: minimumDate,
                                           maxDate: maximumDate,
                                           config: wheelStyle)
        wheelPicker = UDWheelPickerView(pickerHeight: wheelConfig.pickerHeight,
                                        wheelAnimation: true,
                                        hasMask: true,
                                        showSepLine: wheelStyle.showSepeLine,
                                        gradientColor: wheelStyle.pickerBackgroundColor)
        initialDateComp = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day, .hour, .minute], from: dateClamped)
        super.init(frame: .zero)
        self.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        backgroundColor = UDDatePickerTheme.wheelPickerBackgroundColor
        addSubview(wheelPicker)
        wheelPicker.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        wheelPicker.dataSource = self
        wheelPicker.delegate = self
        self.select(date: dateClamped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 实际高度
    public var intrinsicHeight: CGFloat {
        wheelPicker.intrinsicHeight
    }

    /// 选中参数 date 对应时刻
    public func select(date: Date = Date()) {
        select(date: date, animated: false)
    }
    
    /// 选中参数 date 对应时刻
    public func select(date: Date = Date(),
                       animated: Bool = false) {
        let dateClamped = min(max(date, wheelModel.minDate), wheelModel.maxDate)
        let dateType = UDDateWheelPickerView.wheelDateType(model: wheelStyle.mode,
                                                           date: dateClamped, timeZone: wheelModel.timeZone,
                                                           maximumDate: wheelModel.maxDate,
                                                           minimumDate: wheelModel.minDate)
        // 更新 wheelModel
        wheelModel = DateWheelContentModel(type: dateType,
                                           rows: wheelModel.offset * 2,
                                           timeZone: wheelModel.timeZone,
                                           minDate: wheelModel.minDate,
                                           maxDate: wheelModel.maxDate,
                                           config: wheelStyle)
        wheelModel.data.enumerated().forEach { (columnIndex, column) in
            let rowIndex = column.initialIndex
            let selectedIndex = wheelPicker.select(in: columnIndex, at: rowIndex, animated: animated)
            wheelModel.updateSelectedIndex(in: columnIndex, selectedIndex: selectedIndex)
        }
        dateChanged?(dateClamped)
    }

    /// 动态切换「滚轮类型」
    /// - Parameters:
    ///   - mode: 滚轮类型
    ///   - date: 滚轮展示时间
    public func switchTo(mode: UDWheelsStyleConfig.WheelModel, with date: Date) {
        let dateClamped = min(max(date, wheelModel.minDate), wheelModel.maxDate)
        let dateType = UDDateWheelPickerView.wheelDateType(model: mode,
                                                           date: dateClamped,
                                                           timeZone: wheelModel.timeZone,
                                                           maximumDate: wheelModel.maxDate,
                                                           minimumDate: wheelModel.minDate)
        wheelModel = DateWheelContentModel(type: dateType,
                                           rows: wheelModel.offset * 2,
                                           timeZone: wheelModel.timeZone,
                                           minDate: wheelModel.minDate,
                                           maxDate: wheelModel.maxDate,
                                           config: wheelStyle)
        wheelPicker.dataSource = self
        wheelModel.data.enumerated().forEach { (columnIndex, column) in
            let rowIndex = column.initialIndex
            let selectedIndex = wheelPicker.select(in: columnIndex, at: rowIndex, animated: false)
            wheelModel.updateSelectedIndex(in: columnIndex, selectedIndex: selectedIndex)
        }
        dateChanged?(dateClamped)
    }

    private func chainReaction(_ wheelPicker: UDWheelPickerView, didSelectIndex index: Int, at column: Int) {
        guard column >= 0 && column < wheelModel.data.count,
              wheelModel.data[column].selectedIndex != index else {
            return
        }
        switch wheelModel.dataType {
        // 1、day 联动 year\month
        case .yearMonthDay, .yearMonthDayWeek, .yearMonthDayHour:
            let content = wheelModel.data[column]
            let columnType = content.type
            let dayType = wheelModel.data[2].type
            switch columnType {
            case .year:
                wheelModel.updateYearMonthDay(changedColumn: 0, selectedIndex: index, columnType: dayType)
                wheelPicker.reload(columnIndex: 2)
                let newDayIndex = wheelModel.data[2].initialIndex
                let selectedIndex = wheelPicker.select(in: 2, at: newDayIndex, animated: false)
                wheelModel.updateSelectedIndex(in: 2, selectedIndex: selectedIndex)
            case .month:
                wheelModel.updateYearMonthDay(changedColumn: 1, selectedIndex: index, columnType: dayType)
                wheelPicker.reload(columnIndex: 2)
                let newDay = wheelModel.data[2].initialIndex
                let selectedIndex = wheelPicker.select(in: 2, at: newDay, animated: false)
                wheelModel.updateSelectedIndex(in: 2, selectedIndex: selectedIndex)
            default:
                break
            }
        // 2、ampm 联动小时
        case .dayHourMinute, .hourMinute:
            if wheelStyle.is12Hour {
                let content = wheelModel.data[column]
                let columnType = content.type
                switch columnType {
                case .hour12:
                    guard let ampmIndex = wheelModel.data.firstIndex(where: { (pickerContent) in
                        return pickerContent.type == .ampm
                    }) else { return }
                    let deltaHour = index - content.selectedIndex
                    let lastHour = (content.selectedIndex + wheelModel.offset) % 12 + 1
                    // 判断是否切ampm，120 用来规避初始化滚动
                    let isAmpmChange = lastHour < 12 && lastHour + deltaHour >= 12 && deltaHour < 120
                        || lastHour + deltaHour < 0
                        || lastHour == 12 && deltaHour < 0
                    if isAmpmChange {
                        // selectedIndex 实际下标
                        let rowIndex = 1 - wheelModel.data[ampmIndex].selectedIndex + wheelModel.offset
                        let selectedIndex = wheelPicker.select(in: ampmIndex, at: rowIndex, animated: true)
                        wheelModel.updateSelectedIndex(in: ampmIndex, selectedIndex: selectedIndex)
                    }
                default:
                    break
                }
            }
        default:
            break
        }
    }

    private func selectedChanged(column: Int) {
        // 处理返回值类型及映射关系
        let data = wheelModel.data
        switch wheelModel.dataType {
        case .dayHourMinute:
            if wheelStyle.is12Hour {
                guard data.count == 4 else {
                    assertionFailure("data 列数不符")
                    return
                }
                let julianDay = data[0].selectedIndex + wheelModel.startDay
                let YMD = JulianDayUtil.yearMonthDay(from: julianDay)
                let isAheadOfTime = TimeFormatUtils.languagesListForAheadMeridiemIndicator
                    .contains(LanguageManager.currentLanguage)
                let ampmSelected: Int
                let hourShow: Int
                if isAheadOfTime {
                    ampmSelected = data[1].selectedIndex
                    hourShow = (data[2].selectedIndex + wheelModel.offset) % 12 + 1
                } else {
                    ampmSelected = data[3].selectedIndex
                    hourShow = (data[1].selectedIndex + wheelModel.offset) % 12 + 1
                }
                let minSelected = isAheadOfTime ? data[3].selectedIndex : data[2].selectedIndex
                // (0,1)/(1,2)
                var hour = 12 * ampmSelected + hourShow
                if hourShow == 12 { hour -= 12 }
                let min = (minSelected + wheelModel.offset) % (60 / wheelModel.minInterval) * wheelModel.minInterval
                initialDateComp.year = YMD.year
                initialDateComp.month = YMD.month
                initialDateComp.day = YMD.day
                initialDateComp.hour = hour
                initialDateComp.minute = min
            } else {
                guard data.count == 3 else {
                    assertionFailure("data 列数不符")
                    return
                }
                let julianDay = data[0].selectedIndex + wheelModel.startDay
                let YMD = JulianDayUtil.yearMonthDay(from: julianDay)
                let hour = (data[1].selectedIndex + wheelModel.offset) % 24
                let min = (data[2].selectedIndex + wheelModel.offset) %
                    (60 / wheelModel.minInterval) * wheelModel.minInterval
                initialDateComp.year = YMD.year
                initialDateComp.month = YMD.month
                initialDateComp.day = YMD.day
                initialDateComp.hour = hour
                initialDateComp.minute = min
            }
        case .hourMinute, .hourMinuteCenter:
            if wheelStyle.is12Hour {
                guard data.count == 3 else {
                    assertionFailure("data 列数不符")
                    return
                }
                let isAheadOfTime = TimeFormatUtils.languagesListForAheadMeridiemIndicator
                    .contains(LanguageManager.currentLanguage)
                let ampmSelected: Int
                let hourShow: Int
                if isAheadOfTime {
                    ampmSelected = data[0].selectedIndex
                    hourShow = (data[1].selectedIndex + wheelModel.offset) % 12 + 1
                } else {
                    ampmSelected = data[2].selectedIndex
                    hourShow = (data[0].selectedIndex + wheelModel.offset) % 12 + 1
                }
                let minSelected = isAheadOfTime ? data[2].selectedIndex : data[1].selectedIndex
                // (0,1)/(1,2)
                let hour = 12 * ampmSelected + hourShow
                let min = (minSelected + wheelModel.offset) % (60 / wheelModel.minInterval) * wheelModel.minInterval
                initialDateComp.hour = hour
                initialDateComp.minute = min
            } else {
                guard data.count == 2 else {
                    assertionFailure("data 列数不符")
                    return
                }
                let hour = (data[0].selectedIndex + wheelModel.offset) % 24
                let min = (data[1].selectedIndex + wheelModel.offset) %
                    (60 / wheelModel.minInterval) * wheelModel.minInterval
                initialDateComp.hour = hour
                initialDateComp.minute = min
            }
        case .year:
            guard data.count == 1 else {
                assertionFailure("data 列数不符")
                return
            }
            let firstYMD = JulianDayUtil.yearMonthDay(from: wheelModel.startDay)
            initialDateComp.year = data[0].selectedIndex + firstYMD.year
        case .yearMonthDay, .yearMonthDayWeek:
            guard data.count == 3 else {
                assertionFailure("data 列数不符")
                return
            }
            let firstYMD = JulianDayUtil.yearMonthDay(from: wheelModel.startDay)
            initialDateComp.year = data[0].selectedIndex + firstYMD.year
            initialDateComp.month = (data[1].selectedIndex + wheelModel.offset) % 12 + firstYMD.month
            initialDateComp.day = (data[2].selectedIndex + wheelModel.offset) % data[2].content.count + 1
        case .yearMonthDayHour:
            guard data.count == 4 else {
                assertionFailure("data 列数不符")
                return
            }
            let firstYMD = JulianDayUtil.yearMonthDay(from: wheelModel.startDay)
            initialDateComp.year = data[0].selectedIndex + firstYMD.year
            initialDateComp.month = (data[1].selectedIndex + wheelModel.offset) % 12 + firstYMD.month
            initialDateComp.day = (data[2].selectedIndex + wheelModel.offset) % data[2].content.count + 1
            initialDateComp.hour = (data[3].selectedIndex + wheelModel.offset) % 24
        }
        guard let date = Calendar(identifier: .gregorian).date(from: initialDateComp) else { return }
        dateChanged?(date)
    }

    private func getAttributedString(text: String) -> NSAttributedString {
        let attributeds = [NSAttributedString.Key.foregroundColor: wheelStyle.textColor,
                           NSAttributedString.Key.font: wheelStyle.textFont]
        return NSAttributedString(string: text, attributes: attributeds)
    }

    private static func wheelDateType(model: UDWheelsStyleConfig.WheelModel, date: Date,
                                      timeZone: TimeZone = TimeZone.current,
                                      maximumDate: Date,
                                      minimumDate: Date) -> DateWheelDataType {
        let calendar = Calendar(identifier: .gregorian)
        let initComp = calendar.dateComponents(in: timeZone, from: date)

        let minComp = calendar.dateComponents(in: timeZone, from: minimumDate)
        let maxComp = calendar.dateComponents(in: timeZone, from: maximumDate)
        switch model {
        case .dayHourMinute(_, _):
            guard let minYear = minComp.year, let minMonth = minComp.month,
                  let minDay = minComp.day, let minHour = minComp.hour,
                  let minMin = minComp.minute else { break }
            guard let maxYear = maxComp.year, let maxMonth = maxComp.month,
                  let maxDay = maxComp.day, let maxHour = maxComp.hour,
                  let maxMin = maxComp.minute else { break }
            guard let year = initComp.year, let month = initComp.month,
                  let day = initComp.day, let hour = initComp.hour,
                  let min = initComp.minute else { break }

            let initParam = DayHourMinuteData(year: year, month: month, day: day, hour: hour, min: min)
            let minParam = DayHourMinuteData(year: minYear, month: minMonth, day: minDay, hour: minHour, min: minMin)
            let maxParam = DayHourMinuteData(year: maxYear, month: maxMonth, day: maxDay, hour: maxHour, min: maxMin)

            return DateWheelDataType.dayHourMinute(initDateTime: initParam, start: minParam, end: maxParam)
        case .hourMinute:
            guard let initHour = initComp.hour, let initMin = initComp.minute else { break }

            let initParam = HourMinuteData(hour: initHour, min: initMin)

            return DateWheelDataType.hourMinute(initTime: initParam)
        case .hourMinuteCenter:
            guard let initHour = initComp.hour, let initMin = initComp.minute else { break }

            let initParam = HourMinuteData(hour: initHour, min: initMin)

            return DateWheelDataType.hourMinuteCenter(initTime: initParam)
        case .year:
            guard let minYear = minComp.year, let minMonth = minComp.month,
                  let minDay = minComp.day else { break }
            guard let maxYear = maxComp.year, let maxMonth = maxComp.month,
                  let maxDay = maxComp.day else { break }
            guard let year = initComp.year, let month = initComp.month,
                  let day = initComp.day else { break }

            let initParam = YearMonthDayData(year: year, month: month, day: day)
            let minParam = YearMonthDayData(year: minYear, month: minMonth, day: minDay)
            let maxParam = YearMonthDayData(year: maxYear, month: maxMonth, day: maxDay)

            return DateWheelDataType.year(initDate: initParam, start: minParam, end: maxParam)
        case .yearMonthDay:
            guard let minYear = minComp.year, let minMonth = minComp.month,
                  let minDay = minComp.day else { break }
            guard let maxYear = maxComp.year, let maxMonth = maxComp.month,
                  let maxDay = maxComp.day else { break }
            guard let year = initComp.year, let month = initComp.month,
                  let day = initComp.day else { break }

            let initParam = YearMonthDayData(year: year, month: month, day: day)
            let minParam = YearMonthDayData(year: minYear, month: minMonth, day: minDay)
            let maxParam = YearMonthDayData(year: maxYear, month: maxMonth, day: maxDay)

            return DateWheelDataType.yearMonthDay(initDate: initParam, start: minParam, end: maxParam)
        case .yearMonthDayWeek:
            guard let minYear = minComp.year, let minMonth = minComp.month,
                  let minDay = minComp.day else { break }
            guard let maxYear = maxComp.year, let maxMonth = maxComp.month,
                  let maxDay = maxComp.day else { break }
            guard let year = initComp.year, let month = initComp.month,
                  let day = initComp.day else { break }

            let initParam = YearMonthDayData(year: year, month: month, day: day)
            let minParam = YearMonthDayData(year: minYear, month: minMonth, day: minDay)
            let maxParam = YearMonthDayData(year: maxYear, month: maxMonth, day: maxDay)

            return DateWheelDataType.yearMonthDayWeek(initData: initParam, start: minParam, end: maxParam)
        case .yearMonthDayHour:
            guard let minYear = minComp.year, let minMonth = minComp.month,
                  let minDay = minComp.day, let minHour = minComp.hour,
                  let minMin = minComp.minute else { break }
            guard let maxYear = maxComp.year, let maxMonth = maxComp.month,
                  let maxDay = maxComp.day, let maxHour = maxComp.hour,
                  let maxMin = maxComp.minute else { break }
            guard let year = initComp.year, let month = initComp.month,
                  let day = initComp.day, let hour = initComp.hour,
                  let min = initComp.minute else { break }

            let initParam = DayHourMinuteData(year: year, month: month, day: day, hour: hour, min: min)
            let minParam = DayHourMinuteData(year: minYear, month: minMonth, day: minDay, hour: minHour, min: minMin)
            let maxParam = DayHourMinuteData(year: maxYear, month: maxMonth, day: maxDay, hour: maxHour, min: maxMin)

            return DateWheelDataType.yearMonthDayHour(initDateTime: initParam, start: minParam, end: maxParam)
        }
        assertionFailure("")
        let initParam = HourMinuteData(hour: 0, min: 0)
        return DateWheelDataType.hourMinute(initTime: initParam)
    }
}

// MARK: UDWheelPickerViewDataSource
extension UDDateWheelPickerView: UDWheelPickerViewDataSource {
    // 本质只是给一个比例关系，这里会对wheelPicker的caculateScale验证
    public func wheelPickerView(_ wheelPicker: UDWheelPickerView, widthForColumn column: Int) -> CGFloat {
        guard column < wheelModel.uiConfig.count else {
            return 1
        }
        return CGFloat(wheelModel.uiConfig[column].width)
    }

    public func wheelPickerView(_ wheelPicker: UDWheelPickerView, modeOfColumn column: Int) -> UDWheelCircelMode {
        let columnNum = wheelModel.data.count
        // Todo：报错返回值待定
        guard -1 < columnNum && column < columnNum else { assertionFailure("column Index error"); return .circular }
        let columnType = wheelModel.data[column].type
        switch columnType {
        case .year, .ampm, .monthDayWeek, .week:
            return .limited
        default:
            return .circular
        }
    }

    public func wheelPickerView(_ wheelPicker: UDWheelPickerView,
                                viewForRow row: Int,
                                atColumn column: Int) -> UDWheelPickerCell {
        let cell: UDDefaultWheelPickerCell
        // setting horizontal 有特殊文字对齐方式
        guard column < wheelModel.uiConfig.count else {
            assertionFailure("columnIndex 越界")
            return UDDefaultWheelPickerCell()
        }
        let textAlignment = wheelModel.uiConfig[column].textAlignment
        if textAlignment == .right {
            cell = UDDefaultWheelPickerCell(trailingOffsetMin: -32,
                                            textAlignment: .right)
        } else if textAlignment == .left {
            cell = UDDefaultWheelPickerCell(leadingOffsetMin: 32,
                                            textAlignment: .left)
        } else {
            cell = UDDefaultWheelPickerCell()
        }

        let columnNum = wheelModel.data.count
        guard -1 < columnNum && column < columnNum else {
            assertionFailure("column Index error")
            return cell
        }

        let rowNum = wheelModel.data[column].content.count
        guard -1 < row && row < rowNum else {
            assertionFailure("row Index error")
            return cell
        }

        let labelText = wheelModel.data[column].content[row].displayString()
        cell.labelAttributedString = getAttributedString(text: labelText)
        return cell
    }

    public func wheelPickerView(_ wheelPicker: UDWheelPickerView, numberOfRowsInColumn column: Int) -> Int {
        let content = wheelModel.data[column].content
        return content.count
    }

    public func numberOfCloumn(in wheelPicker: UDWheelPickerView) -> Int {
        return wheelModel.data.count
    }
}

// MARK: UDWheelPickerViewDelegate
extension UDDateWheelPickerView: UDWheelPickerViewDelegate {
    // 由于 12 小时制联动ampm需要， row == pageIndex
    public func wheelPickerView(_ wheelPicker: UDWheelPickerView, didSelectIndex index: Int, atColumn column: Int) {
        // 根据 columnType 处理联动逻辑，两种场景
        chainReaction(wheelPicker, didSelectIndex: index, at: column)
        // 更新选中值
        wheelModel.updateSelectedIndex(in: column, selectedIndex: index)
        // 传出结果
        selectedChanged(column: column)
        // 选中完成，抛出选中 cell 供业务方自定义操作
        if let onCompleted = dateChangedOnCompleted {
            let cells = wheelModel.data.enumerated().map { (index, value) in
                wheelPicker.getWheelPickerCell(ofColumn: index,
                                               atRow: value.selectedIndex + wheelModel.offset)
            }
            onCompleted(cells)
        }
    }
}
