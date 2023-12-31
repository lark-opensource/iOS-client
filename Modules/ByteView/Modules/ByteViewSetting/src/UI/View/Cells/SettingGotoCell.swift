//
//  SettingGotoCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import UniverseDesignColor
import UniverseDesignIcon

extension SettingCellType {
    static let gotoCell = SettingCellType("gotoCell", cellType: SettingGotoCell.self, supportSelection: true)
}

extension SettingSectionBuilder {
    @discardableResult
    func gotoCell(_ item: SettingDisplayItem, title: String, subtitle: String? = nil, accessoryText: String? = nil,
                  isEnabled: Bool = true, cellStyle: SettingCellStyle = .insetCorner, data: [String: Any] = [:], if condition: @autoclosure () -> Bool = true,
                  action: ((SettingRowActionContext) -> Void)? = nil) -> Self {
        row(SettingDisplayRow(
            item: item, cellType: cellStyle == .insetCorner ? .gotoCell : .calendarSettingGotoCell, title: title, subtitle: subtitle, accessoryText: accessoryText, cellStyle: cellStyle, isEnabled: isEnabled, showsRightView: isEnabled, data: data, action: action
        ), if: condition())
    }
}

class SettingGotoCell: SettingCell {
    private let accessoryLabel = UILabel()
    private let disclosureIconView = UIImageView()

    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .default
        self.rightView.addSubview(accessoryLabel)
        self.rightView.addSubview(disclosureIconView)
        accessoryLabel.numberOfLines = 0
        accessoryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        accessoryLabel.setContentHuggingPriority(.required, for: .horizontal)
        accessoryLabel.lineBreakMode = .byWordWrapping
        disclosureIconView.image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12))
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        self.selectionStyle = row.isEnabled ? .default : .none
        if let text = row.accessoryText, !text.isEmpty {
            accessoryLabel.isHidden = false
            let attributedString = NSAttributedString(string: text, config: .bodyAssist, textColor: .ud.textPlaceholder)
            accessoryLabel.attributedText = attributedString
            let size = attributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 28.0),
                                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                     context: nil).size
            let width = ceil(size.width) < 138 ? ceil(size.width) : 138
            accessoryLabel.snp.remakeConstraints { make in
                make.left.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
                make.width.equalTo(width)
            }
            disclosureIconView.snp.remakeConstraints { make in
                make.width.height.equalTo(12)
                make.left.equalTo(accessoryLabel.snp.right).offset(12)
                make.right.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
            }
        } else {
            accessoryLabel.isHidden = true
            accessoryLabel.snp.remakeConstraints { make in
                make.left.centerY.equalToSuperview()
            }
            disclosureIconView.snp.remakeConstraints { make in
                make.width.height.equalTo(12)
                make.edges.equalToSuperview()
            }
        }
        super.config(for: row, indexPath: indexPath)
    }
}
