//
//  CalendarSettingGotoCell.swift
//  ByteViewSetting
//
//  Created by lutingting on 2023/9/11.
//

import Foundation

extension SettingCellType {
    static let calendarSettingGotoCell = SettingCellType("calendarSettingGotoCell", cellType: CalendarSettingGotoCell.self, supportSelection: true)
}

final class CalendarSettingGotoCell: SettingGotoCell {
    override var cellHeight: CGFloat { 48 }
}
