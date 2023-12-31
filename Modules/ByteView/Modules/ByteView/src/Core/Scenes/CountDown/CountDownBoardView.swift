//
//  CountDownBoardView.swift
//  ByteView
//
//  Created by wulv on 2022/4/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignShadow
import SnapKit
import UIKit
import ByteViewCommon
import UniverseDesignFont

extension CountDown.Stage {

    var suspendTextColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.functionInfoContentDefault
        case .closeTo:
            return UIColor.ud.functionWarningContentDefault
        case .warn:
            return UIColor.ud.functionDangerContentDefault
        case .end:
            return UIColor.ud.textTitle
        }
    }

    var suspendBackColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.functionInfoFillTransparent02
        case .closeTo:
            return UIColor.ud.functionWarningFillTransparent02
        case .warn:
            return UIColor.ud.functionDangerFillTransparent01
        case .end:
            return UIColor.ud.N50
        }
    }
}

class CountDownBoardView: UIView {

    enum Style {
        /// 有设置按钮
        case hasSet
        /// 无设置按钮（沉浸态）
        case normal
    }

    struct Layout {

        // topView
        static let topViewLeft: CGFloat = 7.0
        static let topViewRight: CGFloat = topViewLeft - floatButtonIconGap
        static let titleHeight: CGFloat = 20.0
        static let titleToFloatButton: CGFloat = 8.0
        static let floatButtonHeight: CGFloat = 30.0
        static let floatButtonIconHeight: CGFloat = 16.0
        static var floatButtonIconGap: CGFloat { (Layout.floatButtonHeight - Layout.floatButtonIconHeight) / 2 }

        // middleStack
        static let middleStackLeft: CGFloat = 7.0
        static let middleStackRight: CGFloat = 14.0 - floatButtonIconGap
        static let middleStackHorizontalGap: CGFloat = 8.0
        static let middleStackHeight: CGFloat = 42.0

        // bottomStack -- 水平布局
        static let bottomStackHorizontalGap: CGFloat = 4
        /// 两格时间时，按钮不能都小于它
        static let bottomButtonMinWForTwo: CGFloat = (maxWForTwo - stackLeft - bottomStackHorizontalGap - bottomLineW - bottomStackHorizontalGap - stackRight) / 2.0
        /// 三格时间时，按钮不能都小于它
        static let bottomButtonMinWForThree: CGFloat = (maxWForThree - stackLeft - bottomStackHorizontalGap - bottomLineW - bottomStackHorizontalGap - stackRight) / 2.0
        static let bottomLineW: CGFloat = 1.0

        // bottomStack -- 垂直布局
        static let bottomStackVerticalGap: CGFloat = 6.0

        // contentStack
        static let stackTop: CGFloat = 8.0
        static let stackTopToMiddle: CGFloat = 4.0
        static let stackMiddleToBottom: CGFloat = 6.0
        static let stackBottomNormal: CGFloat = 14.0
        static let stackBottomHasSet: CGFloat = 10.0
        static let stackLeft: CGFloat = 7.0
        static var stackRight: CGFloat { 14.0 - Layout.floatButtonIconGap }

        // self
        static let maxWForTwo: CGFloat = 144.0 // 两格宽度
        static let maxWForThree: CGFloat = 212.0 // 三格宽度
    }

    let titleLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.text = I18n.View_G_Countdown_Button
        label.numberOfLines = 1
        return label
    }()

    let floatButton: UIButton = {
        let button = UIButton(type: .custom)
        button.vc.setBackgroundColor(.clear, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed.withAlphaComponent(0.2), for: .highlighted)
        button.addInteraction(type: .highlight)
        let image = UDIcon.getIconByKey(.vcDockOutlined, iconColor: UIColor.ud.iconN2,
                                        size: CGSize(width: Layout.floatButtonIconHeight, height: Layout.floatButtonIconHeight))
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        return button
    }()

    lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(titleLabel)
        view.addSubview(floatButton)
        return view
    }()

    let hourLabel = timeLabel()
    let hourDot: CountDownBoardDotView = {
        let dot = CountDownBoardDotView(frame: .zero)
        dot.color = CountDown.Stage.normal.suspendDotColor
        return dot
    }()
    let minuteLabel = timeLabel()
    let minuteDot: CountDownBoardDotView = {
        let dot = CountDownBoardDotView(frame: .zero)
        dot.color = CountDown.Stage.normal.suspendDotColor
        return dot
    }()
    let secondsLabel = timeLabel()

    lazy var middelStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [hourLabel, hourDot, minuteLabel, minuteDot, secondsLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        if #available(iOS 14.0, *) {
            stack.distribution = .equalSpacing
        } else {
            stack.spacing = Layout.middleStackHorizontalGap
        }
        return stack
    }()

    let leftButton: CountDownBoardButton = {
        let b = CountDownBoardButton(frame: .zero)
        b.update(.prolong)
        return b
    }()
    let rightButton: CountDownBoardButton = {
        let b = CountDownBoardButton(frame: .zero)
        b.update(.preEnd)
        return b
    }()

    let line: UIView = {
       let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    lazy var bottomStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [leftButton, rightButton])
        stack.alignment = .center
        return stack
    }()

    lazy var contentStack: UIStackView = {
       let stack = UIStackView(arrangedSubviews: [topView, middelStack, bottomStack])
        stack.axis = .vertical
        stack.alignment = .center
        stack.setCustomSpacing(Layout.stackTopToMiddle, after: topView)
        stack.setCustomSpacing(Layout.stackMiddleToBottom, after: middelStack)
        stack.clipsToBounds = true
        stack.layer.cornerRadius = 8.0
        return stack
    }()

    private var style: Style = .hasSet
    private var hasHour: Bool = true
    private var colorStage: CountDown.Stage = .normal
    private var countDownState: CountDown.State = .start

    convenience init(style: Style = .hasSet, hasHour: Bool = true, colorStage: CountDown.Stage = .normal, state: CountDown.State = .start) {
        self.init(frame: .zero)
        update(style)
        update(hasHour)
        update(colorStage)
        update(state: state)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowOpacity = 0.96
        layer.shadowRadius = 36
        layer.ud.setShadow(type: UDShadowType.s5Down)

        addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.left.equalToSuperview().inset(Layout.stackLeft)
            $0.right.equalToSuperview().inset(Layout.stackRight)
            $0.top.equalToSuperview().inset(Layout.stackTop)
            $0.bottom.equalToSuperview().inset(Layout.stackBottomHasSet)
        }

        titleLabel.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
            $0.height.equalTo(Layout.titleHeight)
        }
        floatButton.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: Layout.floatButtonHeight, height: Layout.floatButtonHeight))
            $0.right.top.bottom.equalToSuperview()
            $0.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(Layout.titleToFloatButton - Layout.floatButtonIconGap)
        }
        topView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.left.equalToSuperview().inset(Layout.topViewLeft)
            $0.right.equalToSuperview().inset(Layout.topViewRight)
        }

        middelStack.snp.makeConstraints {
            $0.left.equalToSuperview().inset(Layout.middleStackLeft)
            $0.right.equalToSuperview().inset(Layout.middleStackRight)
        }

        line.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: Layout.bottomLineW, height: 10))
        }

        layoutBottomStackHorizontal()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(hour: Int?, minute: Int, seconds: Int, stage: CountDown.Stage) {
        if let hour = hour {
            let h: String = hour < 10 ? "0\(hour)" : "\(hour)"
            hourLabel.text = h
            update(true)
        } else {
            update(false)
        }

        let m: String = minute < 10 ? "0\(minute)" : "\(minute)"
        minuteLabel.text = m
        let s: String = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        secondsLabel.text = s

        update(stage)
    }

    func update(_ style: Style) {
        guard self.style != style else { return }
        self.style = style
        var bottom: CGFloat = 0
        switch style {
        case .hasSet:
            bottomStack.isHiddenInStackView = false
            bottom = Layout.stackBottomHasSet
        case .normal:
            bottomStack.isHiddenInStackView = true
            bottom = Layout.stackBottomNormal
        }
        contentStack.snp.remakeConstraints {
            $0.left.equalToSuperview().inset(Layout.stackLeft)
            $0.right.equalToSuperview().inset(Layout.stackRight)
            $0.top.equalToSuperview().inset(Layout.stackTop)
            $0.bottom.equalToSuperview().inset(bottom)
        }
    }

    func update(state: CountDown.State) {
        guard countDownState != state else { return }
        countDownState = state
        leftButton.update(state == .start ? .prolong : .reset)
        rightButton.update(state == .start ? .preEnd : .close)
        updateBottomButtonWidthIfNeeded()
    }

    func updateBottomButtonWidthIfNeeded() {
        let leftW = leftButton.size(by: leftButton.style).width
        let rightW = rightButton.size(by: rightButton.style).width
        let minW = hasHour ? Layout.bottomButtonMinWForThree : Layout.bottomButtonMinWForTwo
        let allMaxW = hasHour ? Layout.maxWForThree : Layout.maxWForTwo
        if leftW < minW, rightW < minW {
            // 两个都不够最小宽度，均分
            leftButton.updateWidth(minW)
            rightButton.updateWidth(minW)
            // 左右定宽布局
            layoutBottomStackHorizontal()
        } else if Layout.stackLeft + leftW + Layout.bottomStackHorizontalGap + Layout.bottomLineW + rightW + Layout.bottomStackHorizontalGap + Layout.stackRight > allMaxW {
            // 超出限定宽度, 换成上下定宽布局
            layoutBottomStackVertical()
        } else {
            // 左右定宽布局
            layoutBottomStackHorizontal()
        }
    }
}

extension CountDownBoardView {

    static private func timeLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        let fontName = "DINAlternate-Bold"
        if let aFont = UIFont(name: fontName, size: 26),
           aFont.fontName == fontName || aFont.familyName == fontName {
            label.font = aFont
        } else {
            label.font = UDFont.monospacedDigitSystemFont(ofSize: 26, weight: .medium)
        }
        label.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 48, height: Layout.middleStackHeight))
        }
        label.backgroundColor = CountDown.Stage.normal.suspendBackColor
        label.textColor = CountDown.Stage.normal.suspendTextColor
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    /// 是否展示小时位
    private func update(_ hasHour: Bool) {
        guard self.hasHour != hasHour else { return }
        self.hasHour = hasHour
        hourLabel.isHiddenInStackView = !hasHour
        hourDot.isHiddenInStackView = !hasHour
        if #unavailable(iOS 14.0) {
            if hasHour {
                middelStack.insertArrangedSubview(hourLabel, at: 0)
                middelStack.insertArrangedSubview(hourDot, at: 1)
            } else {
                middelStack.removeArrangedSubview(hourLabel)
                middelStack.removeArrangedSubview(hourDot)
            }
        }
        updateBottomButtonWidthIfNeeded()
    }

    private func update(_ colorStage: CountDown.Stage) {
        guard self.colorStage != colorStage else { return }
        self.colorStage = colorStage

        hourLabel.backgroundColor = colorStage.suspendBackColor
        hourLabel.textColor = colorStage.suspendTextColor
        hourDot.color = colorStage.suspendDotColor

        minuteLabel.backgroundColor = colorStage.suspendBackColor
        minuteLabel.textColor = colorStage.suspendTextColor
        minuteDot.color = colorStage.suspendDotColor

        secondsLabel.backgroundColor = colorStage.suspendBackColor
        secondsLabel.textColor = colorStage.suspendTextColor
    }

    private func layoutBottomStackHorizontal() {
        let allMaxW = hasHour ? Layout.maxWForThree : Layout.maxWForTwo
        bottomStack.insertArrangedSubview(line, belowArrangedSubview: leftButton)
        bottomStack.axis = .horizontal
        bottomStack.spacing = Layout.bottomStackHorizontalGap
        bottomStack.snp.remakeConstraints {
            $0.width.equalTo(allMaxW - Layout.stackLeft - Layout.stackRight)
            $0.left.right.equalToSuperview()
        }
    }

    private func layoutBottomStackVertical() {
        let allMaxW = hasHour ? Layout.maxWForThree : Layout.maxWForTwo
        bottomStack.removeArrangedSubview(line)
        bottomStack.axis = .vertical
        bottomStack.spacing = Layout.bottomStackVerticalGap
        bottomStack.snp.remakeConstraints {
            $0.width.equalTo(allMaxW - Layout.stackLeft - Layout.stackRight)
            $0.left.right.equalToSuperview()
        }
    }
}
