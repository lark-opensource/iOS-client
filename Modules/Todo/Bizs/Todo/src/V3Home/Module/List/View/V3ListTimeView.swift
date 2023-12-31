//
//  V3ListTimeView.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/22.
//

import Foundation
import UIKit

// MARK: - List Time View

struct V3ListTimeInfo {

    var text: String

    var color: UIColor

    var reminderIcon: UIImage?

    var repeatRuleIcon: UIImage?

    var textWidth: CGFloat

    var totalWidth: CGFloat = 0

}

final class V3ListTimeView: UIView {

    var viewData: V3ListTimeInfo? {
        didSet {
            if let timeInfo = viewData {
                timeLabel.isHidden = false
                timeLabel.text = timeInfo.text
                timeLabel.textColor = timeInfo.color
                if let reminder = timeInfo.reminderIcon {
                    reminderIcon.isHidden = false
                    reminderIcon.image = reminder.ud.withTintColor(timeInfo.color)
                } else {
                    reminderIcon.isHidden = true
                }
                if let repeatRule = timeInfo.repeatRuleIcon {
                    repeatIcon.isHidden = false
                    repeatIcon.image = repeatRule.ud.withTintColor(timeInfo.color)
                } else {
                    repeatIcon.isHidden = true
                }
            } else {
                timeLabel.isHidden = true
                reminderIcon.isHidden = true
                repeatIcon.isHidden = true
            }
            setNeedsLayout()
        }
    }

    private lazy var reminderIcon = UIImageView()
    private lazy var repeatIcon = UIImageView()
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.font = ListConfig.Cell.detailFont
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(timeLabel)
        addSubview(reminderIcon)
        addSubview(repeatIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let viewData = viewData else { return }
        // centerY
        let iconY = (ListConfig.Cell.timeHeight - ListConfig.Cell.timeIconSize.height) * 0.5
        timeLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: min(viewData.textWidth, bounds.width),
            height: ListConfig.Cell.timeHeight
        )
        // icon width: icon + space
        var iconWidth: CGFloat = 0

        switch (reminderIcon.isHidden, repeatIcon.isHidden) {
        case (true, true):
            reminderIcon.frame = .zero
            repeatIcon.frame = .zero
        case (false, true):
            iconWidth += ListConfig.Cell.timeIconSize.width + ListConfig.Cell.timeIconTextSpace
            timeLabel.frame.size.width = min(viewData.textWidth, bounds.width - iconWidth)
            reminderIcon.frame = CGRect(
                origin: CGPoint(
                    x: timeLabel.frame.maxX + ListConfig.Cell.timeIconTextSpace,
                    y: iconY
                ),
                size: ListConfig.Cell.timeIconSize
            )
        case (true, false):
            iconWidth += ListConfig.Cell.timeIconSize.width + ListConfig.Cell.timeIconTextSpace
            timeLabel.frame.size.width = min(viewData.textWidth, bounds.width - iconWidth)
            repeatIcon.frame = CGRect(
                origin: CGPoint(
                    x: timeLabel.frame.maxX + ListConfig.Cell.timeIconTextSpace,
                    y: iconY
                ),
                size: ListConfig.Cell.timeIconSize
            )
        case (false, false):
            iconWidth += (ListConfig.Cell.timeIconSize.width + ListConfig.Cell.timeIconTextSpace) * 2
            timeLabel.frame.size.width = min(viewData.textWidth, bounds.width - iconWidth)
            reminderIcon.frame = CGRect(
                origin: CGPoint(
                    x: timeLabel.frame.maxX + ListConfig.Cell.timeIconTextSpace,
                    y: iconY
                ),
                size: ListConfig.Cell.timeIconSize
            )
            repeatIcon.frame = CGRect(
                origin: CGPoint(
                    x: reminderIcon.frame.maxX + ListConfig.Cell.timeIconTextSpace,
                    y: iconY
                ),
                size: ListConfig.Cell.timeIconSize
            )
        }
    }
}
