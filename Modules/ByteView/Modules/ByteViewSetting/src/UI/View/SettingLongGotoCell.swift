//
//  SettingLongGotoCell.swift
//  ByteViewSetting
//
//  Created by wpr on 2023/11/15.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import UniverseDesignColor
import UniverseDesignIcon

extension SettingCellType {
    static let longGotoCell = SettingCellType("longGotoCell", cellType: SettingLongGotoCell.self, supportSelection: true)
}

extension SettingSectionBuilder {
    @discardableResult
    func longGotoCell(_ item: SettingDisplayItem, title: String, subtitle: String? = nil, accessoryText: String? = nil,
                      isEnabled: Bool = true, cellStyle: SettingCellStyle = .insetCorner, data: [String: Any] = [:], if condition: @autoclosure () -> Bool = true,
                      action: ((SettingRowActionContext) -> Void)? = nil) -> Self {
        row(SettingDisplayRow(
            item: item, cellType: cellStyle == .insetCorner ? .longGotoCell : .calendarSettingGotoCell, title: title, subtitle: subtitle, accessoryText: accessoryText, cellStyle: cellStyle, isEnabled: isEnabled, showsRightView: isEnabled, data: data, action: action
        ), if: condition())
    }
}

class SettingLongGotoCell: BaseSettingCell {

    struct Layout {
        static let leftRightMargin: CGFloat = 16
        static let titleRightMargin: CGFloat = 12
        static let iconSize: CGFloat = 12
        static let iconLeftMargin: CGFloat = 12
    }

    private let accessoryLabel = UILabel()
    private let disclosureIconView = UIImageView()
    private let rightView = UIView()

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override func setupViews() {
        super.setupViews()

        self.selectionStyle = .default

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(rightView)
        self.rightView.addSubview(accessoryLabel)
        self.rightView.addSubview(disclosureIconView)

        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0

        accessoryLabel.numberOfLines = 0
        disclosureIconView.image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12))

        rightView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-Layout.leftRightMargin)
            make.height.width.equalTo(0).priority(1)
        }
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)

        var titleWidth: CGFloat = 0

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
                make.width.height.equalTo(Layout.iconSize)
                make.left.equalTo(accessoryLabel.snp.right).offset(Layout.iconLeftMargin)
                make.right.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
            }
            titleWidth = contentView.bounds.width - Layout.leftRightMargin * 2 - Layout.iconSize - Layout.iconLeftMargin - width - Layout.titleRightMargin
        } else {
            accessoryLabel.isHidden = true
            accessoryLabel.snp.remakeConstraints { make in
                make.left.centerY.equalToSuperview()
            }
            disclosureIconView.snp.remakeConstraints { make in
                make.width.height.equalTo(Layout.iconSize)
                make.edges.equalToSuperview()
            }
            titleWidth = contentView.bounds.width - Layout.leftRightMargin * 2 - Layout.iconSize - Layout.titleRightMargin
        }

        if let subtitle = row.subtitle, !subtitle.isEmpty {
            subtitleLabel.textColor = .ud.textPlaceholder
            let subtitleAttributedString = NSAttributedString(string: subtitle, config: cellStyle.subtitleStyleConfig, lineBreakMode: .byTruncatingTail)
            subtitleLabel.attributedText = subtitleAttributedString

            let subtitleSize = subtitleLabel.sizeThatFits(CGSize(width: titleWidth, height: .greatestFiniteMagnitude))
            subtitleLabel.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(Layout.leftRightMargin)
                make.bottom.equalToSuperview().offset(-12)
                make.height.equalTo(subtitleSize.height)
                make.right.equalTo(rightView.snp.left).offset(-Layout.titleRightMargin)
            }
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.isHidden = true
        }

        titleLabel.textColor =  .ud.textTitle
        if let attributedTitle = row.attributedTitle?() {
            titleLabel.attributedText = attributedTitle
        } else {
            titleLabel.attributedText = NSAttributedString(string: row.title, config: cellStyle.titleStyleConfig, lineBreakMode: .byTruncatingTail)
        }

        let titleSize = titleLabel.sizeThatFits(CGSize(width: titleWidth, height: .greatestFiniteMagnitude))
        titleLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(Layout.leftRightMargin)
            make.top.equalToSuperview().offset(12)
            if subtitleLabel.isHidden {
                make.centerY.equalToSuperview()
                make.bottom.equalToSuperview().offset(-12)
                make.centerY.greaterThanOrEqualTo(contentView.snp.top).offset(52 / 2) // 只有标题时，保证contentView's height >= 52
            } else {
                make.height.equalTo(titleSize.height)
                make.bottom.equalTo(subtitleLabel.snp.top).offset(-4)
            }
            make.right.equalTo(rightView.snp.left).offset(-Layout.titleRightMargin)
        }
    }
}
