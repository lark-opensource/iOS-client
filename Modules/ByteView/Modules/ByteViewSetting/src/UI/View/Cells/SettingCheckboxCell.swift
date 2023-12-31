//
//  SettingCheckboxCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import UniverseDesignCheckBox

extension SettingCellType {
    static let checkboxCell = SettingCellType("checkboxCell", cellType: SettingCheckboxCell.self, supportSelection: true)
}

extension SettingSectionBuilder {
    @discardableResult
    func checkbox(_ item: SettingDisplayItem, title: String, subtitle: String? = nil, accessoryText: String? = nil,
                  isOn: Bool, isEnabled: Bool = true, showsRightView: Bool = false, data: [String: Any] = [:],
                  if condition: @autoclosure () -> Bool = true,
                  action: ((SettingRowActionContext) -> Void)? = nil) -> Self {
        row(SettingDisplayRow(
            item: item, cellType: .checkboxCell, title: title, subtitle: subtitle, accessoryText: accessoryText,
            isOn: isOn, isEnabled: isEnabled, showsRightView: showsRightView, data: data, action: action
        ), if: condition())
    }
}

final class SettingCheckboxCell: SettingGotoCell {
    private let checkbox = UDCheckBox()

    override func setupViews() {
        super.setupViews()
        self.checkbox.isUserInteractionEnabled = false
        self.selectionStyle = .default
        self.adjustsTitleColorWhenDisabled = true
        leftView.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.edges.equalToSuperview()
        }
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        checkbox.isEnabled = row.isEnabled
        checkbox.isSelected = row.isOn
    }
}
