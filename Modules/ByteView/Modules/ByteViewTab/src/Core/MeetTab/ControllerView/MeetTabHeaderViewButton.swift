//
//  MeetTabHeaderViewButton.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUDColor
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewUI
import FigmaKit

enum MeetTabHeaderButtonType: CaseIterable {
    case newMeeting
    case joinMeeting
    case minutes
    case localShare
    case schedule
    case webinarSchedule
    case phoneCall

    var title: String {
        switch self {
        case .newMeeting:
            return I18n.View_T_NewMeeting
        case .joinMeeting:
            return I18n.View_T_JoinMeeting
        case .schedule:
            return I18n.View_MV_ScheduleMeeting
        case .localShare:
            return I18n.View_T_ShareScreen
        case .minutes:
            return I18n.View_G_FeishuMinutes
        case .phoneCall:
            return I18n.View_MV_Phone_MeetingButton
        case .webinarSchedule:
            return I18n.View_G_ScheduleWebinarButton
        }
    }

    var icon: UDIconType {
        switch self {
        case .newMeeting:
            return .videoFilled
        case .joinMeeting:
            return .newJoinMeetingFilled
        case .schedule:
            return .calendarFilled
        case .localShare:
            return .shareScreenFilled
        case .minutes:
            return .minutesLogoFilled
        case .phoneCall:
            return .officephoneFilled
        case .webinarSchedule:
            return .webinarFilled
        }
    }

    var iconBtnColor: UIColor {
        switch self {
        case .newMeeting:
            return .ud.colorfulBlue
        case .joinMeeting:
            return .ud.colorfulBlue
        case .schedule:
            return .ud.colorfulOrange
        case .localShare:
            return .ud.colorfulGreen
        case .minutes:
            return .ud.I500
        case .phoneCall:
            return .ud.colorfulBlue
        case .webinarSchedule:
            return .ud.colorfulOrange
        }
    }

    var iconImageBgColor: UIColor {
        switch self {
        case .newMeeting:
            return .ud.colorfulBlue.withAlphaComponent(0.15)
        case .joinMeeting:
            return .ud.colorfulBlue.withAlphaComponent(0.15)
        case .schedule:
            return .ud.colorfulOrange.withAlphaComponent(0.15)
        case .localShare:
            return .ud.colorfulGreen.withAlphaComponent(0.15)
        case .minutes:
            return .ud.I500.withAlphaComponent(0.15)
        case .phoneCall:
            return .ud.colorfulBlue.withAlphaComponent(0.15)
        case .webinarSchedule:
            return .ud.colorfulOrange.withAlphaComponent(0.15)
        }
    }

    var iconImageBgHighlightedColor: UIColor {
        switch self {
        case .newMeeting:
            return .ud.colorfulBlue.withAlphaComponent(0.3)
        case .joinMeeting:
            return .ud.colorfulBlue.withAlphaComponent(0.3)
        case .schedule:
            return .ud.colorfulOrange.withAlphaComponent(0.3)
        case .localShare:
            return .ud.colorfulGreen.withAlphaComponent(0.3)
        case .minutes:
            return .ud.I500.withAlphaComponent(0.3)
        case .phoneCall:
            return .ud.colorfulBlue.withAlphaComponent(0.3)
        case .webinarSchedule:
            return .ud.colorfulOrange.withAlphaComponent(0.3)
        }
    }

    var iconPadBtnColor: UIColor {
        switch self {
        case .newMeeting:
            return .ud.vcTokenMeetingBtnIconNewMeeting
        case .joinMeeting:
            return .ud.vcTokenMeetingBtnIconNewMeeting
        case .schedule:
            return .ud.vcTokenMeetingBtnIconSchedule
        case .localShare:
            return .ud.vcTokenMeetingBtnIconShareScreen
        case .minutes:
            return UDColor.I500 & UDColor.N950
        case .phoneCall:
            return .ud.vcTokenMeetingBtnIconNewMeeting
        case .webinarSchedule:
            return .ud.vcTokenMeetingBtnIconSchedule
        }
    }
    /// 按钮背景色
    var iconPadBgColor: UIColor {
        switch self {
        case .newMeeting:
            return .ud.vcTokenMeetingBtnBgNewMeetingS
        case .joinMeeting:
            return .ud.vcTokenMeetingBtnBgNewMeetingS
        case .schedule:
            return .ud.vcTokenMeetingBtnBgScheduleS
        case .localShare:
            return .ud.vcTokenMeetingBtnBgShareScreenS
        case .minutes:
            return .ud.N00 & .ud.I200
        case .phoneCall:
            return .ud.vcTokenMeetingBtnBgNewMeetingS
        case .webinarSchedule:
            return .ud.vcTokenMeetingBtnBgScheduleS
        }
    }
    ///  背景色
    var iconPadImageBgColor: UIColor {
        switch self {
        case .newMeeting:
            return .ud.vcTokenMeetingBtnBgNewMeetingM
        case .joinMeeting:
            return .ud.vcTokenMeetingBtnBgNewMeetingM
        case .schedule:
            return .ud.vcTokenMeetingBtnBgScheduleM
        case .localShare:
            return .ud.vcTokenMeetingBtnBgShareScreenM
        case .minutes:
            return .ud.I100 & .ud.I100.withAlphaComponent(0.6)
        case .phoneCall:
            return .ud.vcTokenMeetingBtnBgNewMeetingM
        case .webinarSchedule:
            return .ud.vcTokenMeetingBtnBgScheduleM
        }
    }
}

class MeetTabHeaderButton: UICollectionViewCell {

    lazy var button: VisualButton = {
        let button = VisualButton()
        button.isExclusiveTouch = true
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        return titleLabel
    }()

    lazy var squircleView: SquircleView = {
        let squircleView = SquircleView()
        squircleView.cornerRadius = 10.0
        return squircleView
    }()

    lazy var squircleHighlightedView: SquircleView = {
        let squircleHighlightedView = SquircleView()
        squircleHighlightedView.cornerRadius = 10.0
        return squircleHighlightedView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)

        contentView.addSubview(button)
        contentView.addSubview(titleLabel)

        let verticalMarin: CGFloat = 6.0
        let horizontalMargin: CGFloat = 2.0

        button.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(48.0)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(button.snp.bottom).offset(verticalMarin)
            make.left.right.equalToSuperview().inset(horizontalMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(to headerType: MeetTabHeaderButtonType) {
        let btnSize = CGSize(width: 24, height: 24)
        button.setImage(UDIcon.getIconByKey(headerType.icon, iconColor: headerType.iconBtnColor, size: btnSize), for: .normal)
        button.setImage(UDIcon.getIconByKey(headerType.icon, iconColor: headerType.iconBtnColor, size: btnSize), for: .highlighted)

        squircleView.backgroundColor = headerType.iconImageBgColor
        squircleHighlightedView.backgroundColor = headerType.iconImageBgHighlightedColor

        titleLabel.attributedText = .init(string: headerType.title, config: .assist, alignment: .center, textColor: .ud.textCaption)

        squircleView.bounds = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        squircleHighlightedView.bounds = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        button.setBackgroundImage(squircleView.toImage(), for: .normal)
        button.setBackgroundImage(squircleHighlightedView.toImage(), for: .highlighted)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        button.extendEdge = .init(top: -button.bounds.minY,
                                  left: -button.bounds.minX,
                                  bottom: button.bounds.minY + button.bounds.height - bounds.height,
                                  right: button.bounds.minX + button.bounds.width - bounds.width)
    }
}

class MeetTabHeaderPadButton: UICollectionViewCell {

    lazy var button: VisualButton = {
        let button = VisualButton()
        button.isExclusiveTouch = true
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        return button
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.ud.setShadowColor(UIColor.ud.N900.dynamicColor.withAlphaComponent(0.08), bindTo: self)
        layer.shadowOpacity = 0.0
        layer.shadowRadius = 24.0
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.masksToBounds = false

        addInteraction(type: .lift)

        contentView.addSubview(button)
        contentView.addSubview(titleLabel)

        let innerMarin = 20.0

        button.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().inset(innerMarin)
            make.size.equalTo(44)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(button.snp.bottom).offset(innerMarin)
            make.left.equalToSuperview().inset(innerMarin)
            make.right.bottom.lessThanOrEqualToSuperview().inset(innerMarin)
        }

        button.addTarget(self, action: #selector(pressed), for: [.touchDown])
        button.addTarget(self, action: #selector(released), for: [.touchDragExit, .touchUpInside, .touchUpOutside, .touchCancel])
    }

    func bind(to headerType: MeetTabHeaderButtonType) {
        contentView.backgroundColor = headerType.iconPadImageBgColor
        let btnSize = CGSize(width: 24, height: 24)
        button.setImage(UDIcon.getIconByKey(headerType.icon, iconColor: headerType.iconPadBtnColor, size: btnSize), for: .normal)
        button.setImage(UDIcon.getIconByKey(headerType.icon, iconColor: headerType.iconPadBtnColor, size: btnSize), for: .highlighted)
        button.setBGColor(headerType.iconPadBgColor, for: .normal)
        button.setBGColor(headerType.iconPadBgColor, for: .highlighted)
        titleLabel.attributedText = .init(string: headerType.title, config: .hAssist, textColor: UIColor.ud.textTitle)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = 10
        button.extendEdge = .init(top: -button.bounds.minY,
                                  left: -button.bounds.minX,
                                  bottom: button.bounds.minY + button.bounds.height - bounds.height,
                                  right: button.bounds.minX + button.bounds.width - bounds.width)
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
    }

    @objc
    func pressed() {
        layer.shadowOpacity = 1.0
    }

    @objc
    func released() {
        layer.shadowOpacity = 0.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
