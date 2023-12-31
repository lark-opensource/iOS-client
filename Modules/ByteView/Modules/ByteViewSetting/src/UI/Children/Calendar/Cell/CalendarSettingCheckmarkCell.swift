//
//  CalendarSettingCheckmarkCell.swift
//  ByteViewSetting
//
//  Created by lutingting on 2023/8/30.
//

import Foundation

final class CalendarSettingCheckmarkCell: SettingCheckmarkCell {
    override var cellHeight: CGFloat { 48 }
}

extension SettingCellType {
    static let calendarCheckmarkCell = SettingCellType("calendarCheckmarkCell", cellType: CalendarSettingCheckmarkCell.self, supportSelection: true)
}
