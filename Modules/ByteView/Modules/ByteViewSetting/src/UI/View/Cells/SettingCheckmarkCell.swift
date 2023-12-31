//
//  SettingCheckmarkCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/2.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

extension SettingCellType {
    static let checkmarkCell = SettingCellType("checkmarkCell", cellType: SettingCheckmarkCell.self, supportSelection: true)
}

extension SettingSectionBuilder {
    @discardableResult
    func checkmark(_ item: SettingDisplayItem, title: String, subtitle: String? = nil, cellStyle: SettingCellStyle = .insetCorner, isOn: Bool, data: [String: Any] = [:],
                   if condition: @autoclosure () -> Bool = true,
                   action: ((SettingRowActionContext) -> Void)? = nil) -> Self {
        row(SettingDisplayRow(
            item: item, cellType: cellStyle == .blankPaper ? .calendarCheckmarkCell : .checkmarkCell, title: title, subtitle: subtitle, cellStyle: cellStyle,
            isOn: isOn, showsRightView: true, data: data, action: action
        ), if: condition())
    }
}

class SettingCheckmarkCell: SettingCell {
    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .default
        let iconSize = CGSize(width: 16, height: 16)
        let checkmarkView = UIImageView()
        checkmarkView.image = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: .ud.primaryContentDefault, size: iconSize)
        self.rightView.addSubview(checkmarkView)
        checkmarkView.snp.makeConstraints { make in
            make.size.equalTo(iconSize)
            make.edges.equalToSuperview()
        }
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        // checkmark异化，不管rightview是否显示，都保持对rightview的约束条件
        rightView.isHidden = !row.isOn
    }
}
