//
//  ArrangementHeaderViewCell.swift
//  Calendar
//
//  Created by harry zou on 2019/3/19.
//

import UIKit
import SnapKit
import CalendarFoundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon

final class ArrangementHeaderViewCell: UICollectionViewCell {
    static let timeLabelShowedHeight: CGFloat = 125
    static let timeLabelOneLineHeight: CGFloat = 109
    static let timeLabelHideHeight: CGFloat = 90
    static let avatarLength: CGFloat = 40
    static let leftMargin: CGFloat = 8
    private var model: ArrangementHeaderCellProtocol?

    private let avatarView: FreeBusyAvatarView = {
        let length = ArrangementHeaderViewCell.avatarLength
        let avatarView = FreeBusyAvatarView(displaySize: CGSize(width: length, height: length))
        return avatarView
    }()

    private lazy var topMask: TopMask = {
        let mask = TopMask()
        mask.avatarView = self
        mask.touched = { [weak self] in
            self?.isSelected = false
        }
        return mask
    }()

    private let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.numberOfLines = 1
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = getNameFont()
        nameLabel.textAlignment = .left
        nameLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 760),
                                            for: .horizontal)
        return nameLabel
    }()

    private let firstLineView: TimeWithSunStateView = {
        return TimeWithSunStateView()
    }()

    private let secondLineLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.numberOfLines = 1
        timeLabel.textColor = UIColor.ud.textPlaceholder
        timeLabel.font = UIFont.cd.regularFont(ofSize: 11)
        timeLabel.textAlignment = .left
        return timeLabel
    }()

    private var labelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 3
        return stackView
    }()

    private var timeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 3
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layout(avatarView: avatarView)
        contentView.addSubview(labelStackView)

        timeStackView.addArrangedSubview(firstLineView)
        timeStackView.addArrangedSubview(secondLineLabel)

        labelStackView.addArrangedSubview(nameLabel)
        labelStackView.addArrangedSubview(timeStackView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(avatarView: UIView) {
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(ArrangementHeaderViewCell.leftMargin)
        }
    }

    private func add(mask: TopMask) {
        mask.backgroundColor = UIColor.clear
        if let cv = self.viewController()?.view {
            cv.addSubview(mask)
            mask.snp.makeConstraints { (make) in
                make.edges.equalTo(cv)
            }
        }
    }

    private func remove(mask: TopMask) {
        mask.removeFromSuperview()
    }

    func update(with model: ArrangementHeaderCellProtocol, shouldNameInMiddle: Bool, shouldTimeInOneLine: Bool, cellWidth: CGFloat) {
        self.model = model
        avatarView.avatar = model.avatar
        avatarView.setIconStatus(showBusyIcon: model.showBusyIcon,
                                 showNotWorkingIcon: model.showNotWorkingIcon)
        nameLabel.text = model.nameString

        if model.hasNoPermission {
            secondLineLabel.text = I18n.Calendar_UnderUser_PrivateCalendarGreyStatus
            firstLineView.isHidden = true
            secondLineLabel.isHidden = false
        } else if model.timeInfoHidden {
            secondLineLabel.text = I18n.Calendar_G_HideTimeZone
            firstLineView.isHidden = true
            secondLineLabel.isHidden = false
        } else {
            guard let timeStr = model.timeString, !timeStr.isEmpty,
                  let weekStr = model.weekString, !weekStr.isEmpty else {
                firstLineView.isHidden = true
                secondLineLabel.isHidden = true
                layoutLabelStackView(shouldNameInMiddle: shouldNameInMiddle)
                return
            }

            firstLineView.isHidden = false
            firstLineView.updateTime(timeStr: timeStr, atLight: model.atLight)
            secondLineLabel.isHidden = false
            secondLineLabel.text = weekStr

            // 判断time是否可以一行展示
            if shouldTimeInOneLine {
                timeStackView.axis = .horizontal
                timeStackView.spacing = 4
            } else {
                timeStackView.axis = .vertical
                timeStackView.spacing = 3
            }
        }

        layoutLabelStackView(shouldNameInMiddle: shouldNameInMiddle)
    }

    func layoutLabelStackView(shouldNameInMiddle: Bool) {
        labelStackView.alignment = shouldNameInMiddle ? .center : .leading
        labelStackView.snp.remakeConstraints { (make) in
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            if shouldNameInMiddle {
                make.centerX.equalTo(self.avatarView)
            } else {
                make.left.equalToSuperview().offset(ArrangementHeaderViewCell.leftMargin)
                make.right.lessThanOrEqualToSuperview()
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                avatarView.setCover(isHidden: false)
                add(mask: topMask)
            } else {
                avatarView.setCover(isHidden: true)
                remove(mask: topMask)
            }
        }
    }

    func getTimeLable() -> UIView {
        return firstLineView
    }

    class func getNameFont() -> UIFont {
         return UIFont.cd.regularFont(ofSize: 12)
    }

    class func getTimeStringFont() -> UIFont {
        return UIFont.cd.regularFont(ofSize: 11)
    }

    /// 单独考虑星期是因为多语言下单行星期的长度有不确定性
    class func shouldAlignTextInCenter(nameString: String, timeString: String? = nil, weekdayString: String? = nil) -> Bool {
        guard let timeString = timeString, let weekdayString = weekdayString else {
            return nameString.width(with: getNameFont()) < ArrangementHeaderViewCell.avatarLength
        }
        let textMaximumWidth = max(
            nameString.width(with: getNameFont()),
            timeString.width(with: getTimeStringFont()),
            weekdayString.width(with: getTimeStringFont())
        )
        return textMaximumWidth < ArrangementHeaderViewCell.avatarLength
    }

    class func shouldTimeInOneLine(time: String, week: String, cellWidth: CGFloat) -> Bool {
        return Self.leftMargin + 4.5 + 11 + 2.5 + time.width(with: Self.getTimeStringFont()) + 4 + 4 + week.width(with: Self.getTimeStringFont()) < cellWidth
    }
}

private final class TopMask: UIView {
    var touched: (() -> Void)?
    weak var avatarView: UIView?

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let avatarView = avatarView {
            let rect = avatarView.convert(avatarView.bounds, to: self)
            if !rect.contains(point) {
                touched?()
            }
        }
        return nil
    }

}

class TimeWithSunStateView: UIView {
    private let timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.numberOfLines = 1
        timeLabel.textColor = UDColor.udtokenTagNeutralTextNormal
        timeLabel.font = UDFont.caption2
        return timeLabel
    }()

    private let icon: UIImageView = {
        let view = UIImageView()
        return view
    }()

    init() {
        super.init(frame: .zero)
        addSubview(icon)
        addSubview(timeLabel)

        icon.snp.makeConstraints { make in
            make.height.width.equalTo(12)
            make.left.equalToSuperview().offset(4.5)
            make.top.bottom.equalToSuperview().inset(2)
        }

        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(2.5)
            make.centerY.equalTo(icon)
            make.right.equalToSuperview().offset(-4)
        }

        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTime(timeStr: String, atLight: Bool) {
        timeLabel.text = timeStr
        if atLight {
            backgroundColor = UDColor.N200
            icon.image = UDIcon.dayFilled.colorImage(UIColor.ud.calTokenTagColourDay)
            timeLabel.textColor = UDColor.udtokenTagNeutralTextNormal
        } else {
            backgroundColor = UDColor.colorfulIndigo.withAlphaComponent(0.2)
            icon.image = UDIcon.calendarNightFilled.colorImage(UDColor.colorfulIndigo)
            timeLabel.textColor = UDColor.colorfulIndigo
        }
    }
}
