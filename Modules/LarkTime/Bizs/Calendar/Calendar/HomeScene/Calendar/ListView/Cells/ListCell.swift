//
//  ListCell.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/8.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
final class ListCell: UITableViewCell {

    static let identifier = "ListCell"

    static let topMargin: CGFloat = 23.0

    private static let bottomMargin: CGFloat = 5.0

    private static let eventHeight: CGFloat = 50.0

    static let cellHeight: CGFloat = topMargin + bottomMargin + eventHeight

    static func eventViewFrame() -> CGRect {
        return CGRect(x: 57,
                      y: topMargin,
                      width: 0,
                      height: eventHeight)
    }

    private let weekDayLabel = UILabel()
    private let monthDayLabel = UILabel()
    private let emptyLabel = ActiveLabel()
    private let eventView = ListBlockView()
    weak var delegate: EventInstanceViewDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.layoutWeekDayLabel(weekDayLabel)
        self.layoutDateLabel(monthDayLabel)
        self.layoutEventView(eventView)
        self.layoutEmptyLabel(emptyLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var content: BlockListEventItem?
    func update(content: BlockListEventItem) {
        self.content = content
        self.weekDayLabel.text = content.weekDay
        self.monthDayLabel.text = content.monthDay
        self.updateLabelColor(label: weekDayLabel, isLaterThanToday: content.isLaterThanToday)
        self.updateLabelColor(label: monthDayLabel, isLaterThanToday: content.isLaterThanToday)
        if let eventContent = content.content {
            self.eventView.isHidden = false
            self.emptyLabel.isHidden = true
            self.eventView.updateContent(content: eventContent)
        } else {
            self.eventView.isHidden = true
            self.emptyLabel.isHidden = false
        }
        self.eventView.delegate = delegate
    }

    private func layoutEventView(_ eventView: ListBlockView) {
        self.contentView.addSubview(eventView)
        eventView.frame = CGRect(x: 57, y: ListCell.topMargin, width: self.bounds.width - 57 - 5, height: ListCell.eventHeight)
        eventView.autoresizingMask = [.flexibleWidth]
    }

    private func layoutWeekDayLabel(_ label: UILabel) {
        label.isHidden = true
        self.contentView.addSubview(label)
        label.font = UIFont.cd.semiboldFont(ofSize: 12)
        self.contentView.addSubview(label)
        label.textColor = UIColor.ud.N800
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: ListCell.topMargin, width: 57, height: 17.0)
    }

    private func layoutDateLabel(_ label: UILabel) {
        label.isHidden = true
        self.contentView.addSubview(label)
        label.font = UIFont.cd.dinBoldFont(ofSize: 26)
        self.contentView.addSubview(label)
        label.textColor = UIColor.ud.N800
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: ListCell.topMargin + 17, width: 57, height: 31.0)
    }

    var newEventCallBack: (() -> Void)?

    private func layoutEmptyLabel(_ label: ActiveLabel) {
        label.font = UIFont.cd.font(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        self.addSubview(label)
        label.autoresizingMask = [.flexibleWidth]
        label.frame = CGRect(x: 65, y: ListCell.topMargin + 11, width: self.bounds.size.width - 65 - 20, height: 20)

        let customType = ActiveType.custom(pattern: BundleI18n.Calendar.Calendar_Common_TipToCreate)
        label.enabledTypes = [customType]
        label.text = BundleI18n.Calendar.Calendar_Common_NoEvents + BundleI18n.Calendar.Calendar_Common_TipToCreate
        label.customColor[customType] = UIColor.ud.primaryContentDefault
        label.handleCustomTap(for: customType) { [weak self] _ in
            self?.newEventCallBack?()
        }
    }

    private func updateLabelColor(label: UILabel, isLaterThanToday: Bool?) {
        // nil 表示今天
        guard let isLater = isLaterThanToday else {
            label.textColor = UIColor.ud.primaryContentDefault
            return
        }
        label.textColor = isLater ? UIColor.ud.N800 : UIColor.ud.textDisabled
    }
}
