//
//  CalendarSettingHeaderCell.swift
//  ByteViewSetting
//
//  Created by lutingting on 2023/8/30.
//

import Foundation

extension SettingCellType {
    static let calendarHeaderCell = SettingCellType("calendarHeaderCell", cellType: CalendarSettingHeaderCell.self)
}

final class CalendarSettingHeaderCell: BaseSettingCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override func setupViews() {
        super.setupViews()
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        titleLabel.numberOfLines = 0
        titleLabel.textColor = .ud.textTitle
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textColor = .ud.textPlaceholder

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().inset(16)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
        }
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        titleLabel.attributedText = NSAttributedString(string: row.title, config: cellStyle.titleStyleConfig, lineBreakMode: .byTruncatingTail)
        if let subtitle = row.subtitle {
            subtitleLabel.attributedText = NSAttributedString(string: subtitle, config: cellStyle.subtitleStyleConfig, lineBreakMode: .byTruncatingTail)
        } else {
            subtitleLabel.attributedText = .none
        }
    }
}
