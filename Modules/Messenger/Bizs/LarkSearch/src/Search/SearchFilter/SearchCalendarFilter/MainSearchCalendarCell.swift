//
//  MainSearchCalendarCell.swift
//  LarkSearchFilter
//
//  Created by ByteDance on 2023/8/31.
//

import Foundation
import UIKit
import LarkUIKit
import LarkSearchFilter

final class MainSearchCalendarCell: UITableViewCell {
    static var cellHeight: CGFloat = 54
    private let checkbox = Checkbox()
    private let titleLabel = UILabel()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.ud.body0

        checkbox.isUserInteractionEnabled = false

        contentView.addSubview(checkbox)
        contentView.addSubview(titleLabel)

        checkbox.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkbox.snp.trailing).offset(13)
            make.trailing.equalToSuperview().offset(-21)
            make.centerY.equalToSuperview()
        }
    }

    func updateCellContent(cellContent: MainSearchCalendarItem) {
        titleLabel.text = cellContent.title
        checkbox.onFillColor = cellContent.color
        checkbox.onTintColor = cellContent.color
        checkbox.strokeColor = cellContent.color
        checkbox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.lineWidth = 1.5
        checkbox.setOn(on: cellContent.isSelected, animated: false)
    }
}
