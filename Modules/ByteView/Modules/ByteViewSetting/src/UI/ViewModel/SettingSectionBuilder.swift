//
//  SettingSectionBuilder.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import ByteViewCommon

final class SettingSectionBuilder {
    private var sections: [SettingDisplaySection] = []
    private var lastSectionIsValid = false

    @discardableResult
    func section(header: SettingDisplayHeader? = nil,
                 footer: SettingDisplayFooter? = nil,
                 if condition: @autoclosure () -> Bool = true) -> Self {
        if condition() {
            sections.append(SettingDisplaySection(group: .unknown, header: header, footer: footer, rows: []))
            lastSectionIsValid = true
        } else {
            lastSectionIsValid = false
        }
        return self
    }

    @discardableResult
    func row(_ item: SettingDisplayItem, reuseIdentifier: SettingCellType, title: String, subtitle: String? = nil,
             serviceTerms: String? = nil, useLKLabel: Bool = false,
             accessoryText: String? = nil, cellStyle: SettingCellStyle = .insetCorner, isOn: Bool = false, isEnabled: Bool = true,
             showsLeftView: Bool = true, showsRightView: Bool = true, data: [String: Any] = [:],
             action: ((SettingRowActionContext) -> Void)? = nil) -> Self {
        row(SettingDisplayRow(item: item, cellType: reuseIdentifier, title: title, subtitle: subtitle,
                              serviceTerms: serviceTerms, useLKLabel: useLKLabel,
                              accessoryText: accessoryText, cellStyle: cellStyle, isOn: isOn, isEnabled: isEnabled,
                              showsLeftView: showsLeftView, showsRightView: showsRightView,
                              data: data, action: action))
    }

    @discardableResult
    func row(_ row: @autoclosure () -> SettingDisplayRow, if condition: @autoclosure () -> Bool = true) -> Self {
        guard lastSectionIsValid, condition() else { return self }
        sections[sections.count - 1].rows.append(row())
        return self
    }

    func build() -> [SettingDisplaySection] {
        self.sections = sections.filter { !$0.rows.isEmpty }
        return self.sections
    }
}
