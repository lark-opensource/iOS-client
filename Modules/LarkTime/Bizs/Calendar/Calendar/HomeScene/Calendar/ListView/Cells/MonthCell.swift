//
//  MonthCell.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/9.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

final class MonthCell: UITableViewCell {

    static let identifier = "MonthCell"

    private static let topMargin: CGFloat = 23.0

    private static let bottomMargin: CGFloat = 5.0

    static let cellHeight: CGFloat = topMargin + bottomMargin + 36.5

    let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.layoutLabel(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutLabel(_ label: UILabel) {
        label.font = UIFont.cd.mediumFont(ofSize: 20)
        label.textColor = UIColor.ud.N800
        self.contentView.addSubview(label)
        label.frame = CGRect(x: 16, y: MonthCell.topMargin, width: self.bounds.size.width - 16 - 20, height: 37)
    }

    func updateContent(_ content: EventListSeparatorItem) {
        self.label.attributedText = content.text.attributedMonthString()
    }

    func updateText(_ text: String) {
        self.label.attributedText = text.attributedMonthString()
    }
}
