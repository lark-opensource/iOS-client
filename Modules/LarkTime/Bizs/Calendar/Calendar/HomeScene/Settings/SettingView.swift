//
//  SettingView.swift
//  Calendar
//
//  Created by heng zhu on 2019/2/11.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit
import LarkUIKit

final class SettingView: UIView {

    enum CellTailingType {
        case switcher
        case tailLabel
    }

    private let safeAreaLayoutWidth: CGFloat = 12
    private let LeftSideTitleMaximumWidthRatio: CGFloat = 0.6

    var isLocked: Bool = false {
        didSet {
            lockedMaskBtn.isHidden = !isLocked
        }
    }

    private var lockedMsgToastCallBack: (() -> Void)?

    private let titleLable: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private let subTitleLabel: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.numberOfLines = 2
        return label
    }()

    private let innerErrorView: ZoomCommonErrorTipsView = {
        let view = ZoomCommonErrorTipsView()
        view.errorType = .list
        return view
    }()

    private let tailingLable: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let accessIcon = UIImageView(image: NewEventViewUIStyle.Image.access)

    private let wrapper: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private let switchBtn: UISwitch = UISwitch.blueSwitch()
    private let bgButton = UIButton.cd.button(type: .custom)
    private let lockedMaskBtn = UIButton()

    private let checkBox: LKCheckbox = LKCheckbox(boxType: .single, isEnabled: true, iconSize: CGSize(width: 20, height: 20))

    private let badgeID: BadgeID
    private let relatedBadges: [BadgeID]?

    private let hasSwitchExist: Bool
    private let hasTailingLabel: Bool

    //  Title + Subtitle？+ + InnerErrorTips? + Switcher
    init(switchSelector: Selector,
         target: Any,
         title: String,
         subTitle: String? = nil,
         enableNoLimitMultiLine: Bool? = false,
         badgeID: BadgeID = .none,
         relatedBadges: [BadgeID]? = nil,
         lockedMsgToastCallBack: (() -> Void)? = nil) {
        self.badgeID = badgeID
        self.relatedBadges = relatedBadges
        self.hasSwitchExist = true
        self.hasTailingLabel = false
        super.init(frame: .zero)
        self.titleLable.attributedText = NSAttributedString(string: title, attributes: getTitleLabelAttributeds())
        initialize()
        layoutSwitchBtn(switchBtn, in: self)
        if let subTitle = subTitle {
            layoutTitleLabels(titleLabel: titleLable, subTitleLabel: subTitleLabel, type: .switcher, in: self)
            if let enable = enableNoLimitMultiLine, enable { subTitleLabel.numberOfLines = 0 }
            updateSubTitle(text: subTitle)
        } else {
            layout(titleLabel: titleLable, in: self)
        }

        switchBtn.addTarget(target, action: switchSelector, for: .valueChanged)
        self.lockedMsgToastCallBack = lockedMsgToastCallBack
    }

    // Title + Subtitle? + InnerErrorTips? + Tailing? + 》
    init(cellSelector: Selector,
         target: Any,
         title: String,
         subTitle: String? = nil,
         tailingTitle: String? = nil,
         badgeID: BadgeID = .none,
         relatedBadges: [BadgeID]? = nil) {
        self.badgeID = badgeID
        self.relatedBadges = relatedBadges
        self.hasSwitchExist = false
        self.hasTailingLabel = tailingTitle != nil
        super.init(frame: .zero)
        self.titleLable.attributedText = NSAttributedString(string: title, attributes: getTitleLabelAttributeds())
        initialize()
        layout(wrapper: wrapper, in: self)

        tailingLable.text = tailingTitle

        if let subTitle = subTitle {
            layoutTitleLabels(titleLabel: titleLable, subTitleLabel: subTitleLabel, type: .tailLabel, in: self)
            updateSubTitle(text: subTitle)
        } else {
            layout(titleLabel: titleLable, in: self)
        }
        layout(asscessIcon: accessIcon, in: wrapper)
        layout(tailingLable: tailingLable, rightView: accessIcon, in: wrapper)
        layout(bgButton: bgButton, in: self)
        bgButton.isUserInteractionEnabled = true
        bgButton.addTarget(target, action: cellSelector, for: .touchUpInside)
    }

    // Title + tailTitle
    init(title: String,
         tailingTitle: String,
         badgeID: BadgeID = .none,
         relatedBadges: [BadgeID]? = nil) {
        self.badgeID = badgeID
        self.relatedBadges = relatedBadges
        self.hasSwitchExist = false
        self.hasTailingLabel = true
        super.init(frame: .zero)
        self.titleLable.attributedText = NSAttributedString(string: title, attributes: getTitleLabelAttributeds())
        initialize()
        layout(tailingLable: tailingLable, in: self)
        layout(titleLabel: titleLable, rightView: tailingLable, in: self)
        layout(bgButton: bgButton, in: self)
        bgButton.isUserInteractionEnabled = false

        tailingLable.text = tailingTitle
    }

    // checkBox + Title + Subtitle?
    init(cellSelector: Selector,
         target: Any,
         title: String,
         badgeID: BadgeID = .none,
         relatedBadges: [BadgeID]? = nil,
         subTitle: String? = nil,
         enableNoLimitMultiLine: Bool? = false,
         isSelected: Bool) {
        self.badgeID = badgeID
        self.relatedBadges = relatedBadges
        self.hasSwitchExist = false
        self.hasTailingLabel = false
        super.init(frame: .zero)
        self.titleLable.attributedText = NSAttributedString(string: title, attributes: getTitleLabelAttributeds())
        initialize()
        layout(wrapper: wrapper, in: self)
        checkBox.isUserInteractionEnabled = false

        if let subTitle = subTitle {
            layout(isSelected: isSelected, titleLabel: titleLable, subTitleLabel: subTitleLabel, in: self)
            if let enable = enableNoLimitMultiLine, enable { subTitleLabel.numberOfLines = 0 }
            updateSubTitle(text: subTitle)
        } else {
            layout(isSelected: isSelected, titleLabel: titleLable, in: self)
        }

        layout(bgButton: bgButton, in: self)
        bgButton.isUserInteractionEnabled = true
        bgButton.addTarget(target, action: cellSelector, for: .touchUpInside)
    }

    func update(switchIsOn: Bool) {
        switchBtn.isOn = switchIsOn
    }

    func update(switchIsEditable: Bool) {
        switchBtn.isEnabled = switchIsEditable
    }

    func update(tailingTitle: String) {
        tailingLable.text = tailingTitle
    }

    func updateSubTitle(text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.maximumLineHeight = 22
        self.subTitleLabel.attributedText = NSAttributedString(string: text, attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                                          .font: UIFont.systemFont(ofSize: 14),
                                                                                          .paragraphStyle: paragraphStyle])
    }

    func update(checkBoxIsSelected: Bool) {
        checkBox.isSelected = checkBoxIsSelected
    }

    private func getTitleLabelAttributeds() -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = 24
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        // 高度变大后要设置offset才能处于垂直方向的中间位置
        let offset = (lineHeight - titleLable.font.lineHeight) / 4.0

        return [.paragraphStyle: style, .baselineOffset: offset]
    }

    func update(titleText: String) {
        let attr = NSAttributedString(string: titleText, attributes: getTitleLabelAttributeds())
        titleLable.attributedText = attr
    }

    func update(errorTitles: [String]) {
        innerErrorView.configErrorsList(titles: errorTitles)
    }

    private func initialize() {
        self.backgroundColor = UIColor.ud.bgFloat
        LarkBadgeManager.configRedDot(badgeID: badgeID,
                                      view: titleLable,
                                      relatedBadges: relatedBadges,
                                      topRightPoint: CGPoint(x: 12, y: 0),
                                      isEqualCenterY: true)

        self.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(52)
        }
    }

    private func layout(bgButton: UIButton, in superV: UIView) {
        bgButton.setHighlitedImageWithColor(UIColor.ud.fillHover)
        superV.addSubview(bgButton)
        bgButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func layoutSwitchBtn(_ switchBtn: UIView, in superV: UIView) {
        superV.addSubview(switchBtn)
        superV.addSubview(lockedMaskBtn)

        switchBtn.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(NewEventViewUIStyle.Margin.rightMargin)
        }

        lockedMaskBtn.isHidden = true
        lockedMaskBtn.backgroundColor = .clear
        lockedMaskBtn.addTarget(self, action: #selector(tapLocked), for: .touchUpInside)
        lockedMaskBtn.snp.makeConstraints { make in
            make.edges.equalTo(switchBtn)
        }
    }

    private func layout(asscessIcon: UIView, in superV: UIView) {
        superV.addSubview(asscessIcon)
        accessIcon.snp.makeConstraints { (make) in
            make.right.centerY.equalToSuperview()
            make.size.equalTo(EventBasicCellLikeView.Style.iconSize)
        }
    }

    private func layout(titleLabel: UIView, rightView: UIView, in superV: UIView) {
        superV.addSubview(titleLable)
        titleLable.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(12).priority(.low)
            make.bottom.equalToSuperview().offset(-12).priority(.low)
            make.left.equalTo(NewEventViewUIStyle.Margin.leftMargin)
            make.right.lessThanOrEqualTo(rightView.snp.left).offset(-6)
        }
    }

    private func layout(titleLabel: UIView, in superV: UIView) {
        superV.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12).priority(.high)
            make.centerY.greaterThanOrEqualTo(superV.snp.top).offset(26)
            make.bottom.equalToSuperview().offset(-12).priority(.high)
            make.left.equalTo(NewEventViewUIStyle.Margin.leftMargin)
            if hasSwitchExist {
                make.right.equalToSuperview().offset(-(switchBtn.frame.size.width + safeAreaLayoutWidth))
            } else if hasTailingLabel {
                make.right.lessThanOrEqualToSuperview().multipliedBy(LeftSideTitleMaximumWidthRatio)
            }
        }
    }

    private func layoutTitleLabels(titleLabel: UILabel, subTitleLabel: UILabel, type: CellTailingType, in superV: UIView) {
        superV.addSubview(titleLabel)
        superV.addSubview(subTitleLabel)
        superV.addSubview(innerErrorView)

        let rightOffset: CGFloat = getRightOffset(type)

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(NewEventViewUIStyle.Margin.leftMargin)
            make.right.lessThanOrEqualToSuperview().offset(rightOffset)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(titleLabel)
            make.right.lessThanOrEqualToSuperview().offset(rightOffset)
        }

        innerErrorView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(subTitleLabel.snp.bottom)
            make.right.equalToSuperview().offset(rightOffset)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func layout(tailingLable: UIView, in superV: UIView) {
        superV.addSubview(tailingLable)
        tailingLable.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.equalToSuperview().offset(NewEventViewUIStyle.Margin.rightMargin)
        }
    }

    private func layout(tailingLable: UIView, rightView: UIView, in superV: UIView) {
        superV.addSubview(tailingLable)
        tailingLable.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(titleLable.snp.right).offset(12)
            make.right.equalTo(rightView.snp.left).offset(-8)
        }
    }

    private func layout(wrapper: UIView, in superV: UIView) {
        superV.addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(NewEventViewUIStyle.Margin.rightMargin)
        }
    }

    // 带副标题 checkbox Cell
    private func layout(isSelected: Bool, titleLabel: UILabel, subTitleLabel: UILabel, in superV: UIView) {
        superV.addSubview(checkBox)
        superV.addSubview(titleLabel)
        superV.addSubview(subTitleLabel)

        checkBox.isSelected = isSelected
        checkBox.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(20)
            make.left.equalTo(NewEventViewUIStyle.Margin.leftMargin)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(checkBox)
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.right.equalToSuperview().offset(-safeAreaLayoutWidth)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-safeAreaLayoutWidth)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // 单标题 checkbox Cell
    private func layout(isSelected: Bool, titleLabel: UILabel, in superV: UIView) {
        superV.addSubview(checkBox)
        superV.addSubview(titleLabel)

        checkBox.isSelected = isSelected
        checkBox.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(20)
            make.left.equalTo(NewEventViewUIStyle.Margin.leftMargin)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(checkBox)
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.right.equalToSuperview().offset(-safeAreaLayoutWidth)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tapLocked() {
        self.lockedMsgToastCallBack?()
    }

    private func getRightOffset(_ type: CellTailingType) -> CGFloat {
        switch type {
        case .switcher:
            return -(switchBtn.frame.size.width + safeAreaLayoutWidth)
        case .tailLabel:
            return -((tailingLable.text?.getWidth(font: UIFont.systemFont(ofSize: 14)) ?? 0)
                     + safeAreaLayoutWidth + EventBasicCellLikeView.Style.iconSize.width + 8 + 16)
        }
    }
}
