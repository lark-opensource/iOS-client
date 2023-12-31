//
//  DateCell.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/8.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

final class WeekCell: UITableViewCell {

    static let identifier = "WeekCell"

    private static let topMargin: CGFloat = 23.0

    private static let bottomMargin: CGFloat = 5.0

    static let cellHeight: CGFloat = topMargin + bottomMargin + 20

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.layoutLabel(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutLabel(_ label: UILabel) {
        label.font = UIFont.cd.font(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        self.contentView.addSubview(label)
        label.autoresizingMask = [.flexibleWidth]
        label.frame = CGRect(x: 65, y: WeekCell.topMargin, width: self.bounds.size.width - 65 - 20, height: 20)
    }

    func updateContent(_ content: EventListSeparatorItem) {
        self.label.text = content.text
    }

    func updateText(_ text: String) {
        self.label.text = text
    }
}
