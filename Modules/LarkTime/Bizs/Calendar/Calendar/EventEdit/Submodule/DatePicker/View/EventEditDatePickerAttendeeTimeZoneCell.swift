//
//  EventEditDatePickerAttendeeTimeZoneCell.swift
//  Calendar
//
//  Created by 张威 on 2020/2/6.
//

import UIKit
import SnapKit
import LarkUIKit
import CTFoundation
import LarkBizAvatar
import UniverseDesignIcon
import LarkTimeFormatUtils

protocol EventEditDatePickerAttendeeTimeZoneCellDataType {
    var startDate: Date { get }
    var endDate: Date { get }
    var timeZone: TimeZone? { get }
    var is12HourStyle: Bool { get }
    var isSameDay: Bool { get }
    var isLocal: Bool { get }
    var avatars: [Avatar] { get }
}

final class EventEditDatePickerAttendeeTimeZoneCell: UITableViewCell {

    var viewData: EventEditDatePickerAttendeeTimeZoneCellDataType? {
        didSet {
            updateText()
            updateAvatar(viewData?.avatars ?? [])
            localMarkView.isHidden = !(viewData?.isLocal ?? false)
            accessImageView.isHidden = (viewData?.avatars.count ?? 0) == 0
        }
    }

    private var topLabel: UILabel = UILabel()
    private var bottomLabel: UILabel = UILabel()
    private var timeZoneMaskLabel: UILabel = UILabel()
    private var localMarkView: UIImageView = UIImageView()
    private var avatarViews: [UIView] = []
    private var accessImageView: UIImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgFloat

        topLabel.font = UIFont.cd.mediumFont(ofSize: 16)
        topLabel.adjustsFontSizeToFitWidth = true
        topLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(topLabel)
        topLabel.snp.makeConstraints {
            $0.centerY.equalTo(contentView.snp.top).offset(24)
            $0.left.equalToSuperview().offset(16)
        }

        localMarkView.image = UDIcon.getIconByKeyNoLimitSize(.localFilled).renderColor(with: .n3)
        localMarkView.isHidden = true
        contentView.addSubview(localMarkView)
        localMarkView.snp.makeConstraints {
            $0.width.height.equalTo(14)
            $0.centerY.equalTo(topLabel)
            $0.left.equalTo(topLabel.snp.right).offset(6)
        }

        bottomLabel.font = UIFont.cd.regularFont(ofSize: 14)
        bottomLabel.adjustsFontSizeToFitWidth = true
        bottomLabel.textColor = UIColor.ud.textCaption
        contentView.addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints {
            $0.centerY.equalTo(contentView.snp.bottom).offset(-21.5)
            $0.width.equalTo(topLabel)
            $0.left.equalToSuperview().offset(16)
        }

        accessImageView.image = UDIcon.getIconByKeyNoLimitSize(.rightBoldOutlined).renderColor(with: .n3)
        contentView.addSubview(accessImageView)
        accessImageView.snp.makeConstraints {
            $0.width.height.equalTo(12)
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }

        contentView.addSubview(timeZoneMaskLabel)
        timeZoneMaskLabel.adjustsFontSizeToFitWidth = true
        timeZoneMaskLabel.textColor = .ud.textPlaceholder
        timeZoneMaskLabel.font = UIFont.cd.regularFont(ofSize: 16)
        timeZoneMaskLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
        }
        timeZoneMaskLabel.text = I18n.Calendar_G_HideTimeZone
        timeZoneMaskLabel.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateText() {
        guard let viewData = viewData else {
            topLabel.text = nil
            bottomLabel.text = nil
            return
        }

        // 场景: 编辑页参与人不同时区-详情页-查看参与人当地时区
        // 根据制定时区 format 时间

        guard let timeZone = viewData.timeZone else {
            timeZoneMaskLabel.isHidden = false
            topLabel.attributedText = nil
            bottomLabel.attributedText = nil
            topLabel.text = nil
            bottomLabel.text = nil
            return
        }
        timeZoneMaskLabel.isHidden = true
        let customOptions = Options(
            timeZone: timeZone,
            is12HourStyle: viewData.is12HourStyle,
            timeFormatType: .short,
            timePrecisionType: .minute,
            datePrecisionType: .day,
            dateStatusType: .absolute
        )

        if viewData.isSameDay {
            topLabel.attributedText = nil
            bottomLabel.attributedText = nil
            topLabel.text = TimeFormatUtils.formatTimeRange(startFrom: viewData.startDate, endAt: viewData.endDate, with: customOptions)
            bottomLabel.text = TimeFormatUtils.formatFullDate(from: viewData.startDate, with: customOptions)
        } else {
            let setAttrStr = { (label: UILabel, timeStr: String, dateStr: String) in
                label.text = nil
                let mAttrStr = NSMutableAttributedString(string: "\(timeStr) \(dateStr)")
                mAttrStr.addAttributes(
                    [NSAttributedString.Key.font: UIFont.cd.mediumFont(ofSize: 16),
                     NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle],
                    range: NSRange(location: 0, length: timeStr.count)
                )
                mAttrStr.addAttributes(
                    [NSAttributedString.Key.font: UIFont.cd.regularFont(ofSize: 15),
                     NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption],
                    range: NSRange(location: mAttrStr.string.count - dateStr.count, length: dateStr.count)
                )
                label.attributedText = mAttrStr
            }
            setAttrStr(
                topLabel,
                TimeFormatUtils.formatTime(from: viewData.startDate, with: customOptions),
                TimeFormatUtils.formatFullDate(from: viewData.startDate, with: customOptions)
            )
            setAttrStr(
                bottomLabel,
                TimeFormatUtils.formatTime(from: viewData.endDate, with: customOptions),
                TimeFormatUtils.formatFullDate(from: viewData.endDate, with: customOptions)
            )
        }
        setNeedsLayout()
    }

    private func updateAvatar(_ avatars: [Avatar]) {
        let avatarWidth: CGFloat = 32
        avatarViews.forEach { $0.removeFromSuperview() }
        var views: [UIView] = avatars.prefix(3).map {
            let view = AvatarView()
            view.setAvatar($0, with: avatarWidth)
            return view
        }
        if avatars.count > 3 {
            let moreLabel = UILabel()
            moreLabel.backgroundColor = UIColor.ud.bgFloat
            moreLabel.text = "+\(avatars.count - 3)"
            moreLabel.textAlignment = .center
            moreLabel.font = UIFont.cd.regularFont(ofSize: 14)
            moreLabel.adjustsFontSizeToFitWidth = true
            moreLabel.minimumScaleFactor = 8 / 14
            moreLabel.textColor = UIColor.ud.textCaption
            moreLabel.layer.cornerRadius = avatarWidth / 2
            moreLabel.clipsToBounds = true
            views.append(moreLabel)
        }
        let horizontalMargin: CGFloat = 2.0
        let edgeInsets = UIEdgeInsets(top: 2, left: horizontalMargin, bottom: 2, right: horizontalMargin)
        avatarViews = views.reversed().map { avatarView in
            let wrapperView = UIView()
            wrapperView.layer.cornerRadius = avatarWidth / 2 + horizontalMargin
            wrapperView.layer.masksToBounds = true
            wrapperView.backgroundColor = UIColor.ud.bgFloat
            wrapperView.addSubview(avatarView)
            avatarView.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(edgeInsets)
            }
            return wrapperView
        }

        var offset: CGFloat = -37
        for avatarView in avatarViews {
            contentView.addSubview(avatarView)
            contentView.sendSubviewToBack(avatarView)
            avatarView.snp.makeConstraints {
                $0.width.height.equalTo(edgeInsets.left + edgeInsets.right + avatarWidth)
                $0.centerY.equalToSuperview()
                $0.right.equalToSuperview().offset(offset)
            }
            offset -= 28
        }

        avatarViews.last?.snp.remakeConstraints {
            $0.width.height.equalTo(edgeInsets.left + edgeInsets.right + avatarWidth)
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(offset + 28)
            $0.left.greaterThanOrEqualTo(topLabel.snp.right).offset(24)
        }

        setNeedsLayout()
    }

}
