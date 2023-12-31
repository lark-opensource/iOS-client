//
//  CountDownTagView.swift
//  ByteView
//
//  Created by wulv on 2022/4/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import UIKit
import ByteViewCommon

extension CountDown.Stage {

    /// topbar tag
    var tagTopBarBGColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.udtokenTagBgBlue.withAlphaComponent(0.2)
        case .closeTo:
            return UIColor.ud.udtokenTagBgOrange.withAlphaComponent(0.2)
        case .warn:
            return UIColor.ud.udtokenTagBgRed.withAlphaComponent(0.2)
        case .end:
            return UIColor.ud.udtokenTagNeutralBgNormal.withAlphaComponent(0.1)
        }
    }

    /// 沉浸态tag
    var tagGridBGColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.udtokenTagBgBlueSolid
        case .closeTo:
            return UIColor.ud.udtokenTagBgOrangeSolid
        case .warn:
            return UIColor.ud.udtokenTagBgRedSolid
        case .end:
            return UIColor.ud.N400.withAlphaComponent(0.7)
        }
    }

    var tagIconColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.udtokenTagTextSBlue
        case .closeTo:
            return UIColor.ud.udtokenTagTextSOrange
        case .warn:
            return UIColor.ud.udtokenTagTextSRed
        case .end:
            return UIColor.ud.iconN1
        }
    }

    var tagTextColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.udtokenTagTextSBlue
        case .closeTo:
            return UIColor.ud.udtokenTagTextSOrange
        case .warn:
            return UIColor.ud.udtokenTagTextSRed
        case .end:
            return UIColor.ud.textTitle
        }
    }
}

class CountDownTagView: UIView {

    enum Scene {
        /// 状态条
        case inTopBar
        /// 沉浸态
        case inGrid
    }

    private var colorStage: CountDown.Stage = .normal
    private var scene: Scene = .inTopBar

    var intrinsicContentWidth: CGFloat {
        timeLabel.intrinsicContentSize.width + leftAndRightTotalInset + iconToTime + iconSize
    }
    private var lastStringCount: Int = 0
    var isTimeStringWidthChanged: Bool = false

    let gridTextStyleConfig = VCFontConfig(fontSize: 12, fontStyle: .monospacedDigit, lineHeight: 15, fontWeight: .medium)
    let topBarTextStyleConfig = VCFontConfig(fontSize: 12, fontStyle: .monospacedDigit, lineHeight: 18, fontWeight: .medium)

    convenience init(scene: Scene) {
        self.init(frame: .zero)
        self.scene = scene

        layer.cornerRadius = 4
        layer.masksToBounds = true

        addSubview(tagIcon)
        addSubview(timeLabel)

        tagIcon.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview().inset((viewHeight - iconSize) / 2).priority(.high)
            maker.left.equalToSuperview().offset(iconLeft)
            maker.size.equalTo(CGSize(width: iconSize, height: iconSize))
        }

        timeLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(tagIcon.snp.right).offset(iconToTime)
            maker.right.equalToSuperview().inset(timeRight)
        }

        snp.makeConstraints {
            $0.height.equalTo(viewHeight).priority(.required)
        }

        update(stage: colorStage)
    }

    private let iconLeft: CGFloat = 4.0
    private let timeRight: CGFloat = 4.0
    private let iconSize: CGFloat = 12.0
    private let leftAndRightTotalInset: CGFloat = 8.0

    private let iconToTime: CGFloat = 4.0
    var viewHeight: CGFloat {
        scene == .inTopBar ? 18 : 15
    }


    private let tagIcon: UIImageView = {
        let icon = UIImageView()
        return icon
    }()

    private var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
}

extension CountDownTagView {

    func update(hour: Int, minute: Int, seconds: Int, stage: CountDown.Stage) {
        let h: String = "\(hour)"
        let m: String = minute < 10 ? "0\(minute)" : "\(minute)"
        let s: String = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        let text: String
        if hour > 0 {
            text = "\(h):\(m):\(s)"
        } else {
            text = "\(m):\(s)"
        }
        timeLabel.attributedText = NSAttributedString(string: text, config: scene == .inGrid ? self.gridTextStyleConfig : self.topBarTextStyleConfig)
        let newCount = text.count
        isTimeStringWidthChanged = (newCount != lastStringCount)
        lastStringCount = newCount
        if stage != colorStage {
            colorStage = stage
            update(stage: stage)
        }
    }

    func update(stage: CountDown.Stage) {
        backgroundColor = stage.tagGridBGColor
        tagIcon.image = UDIcon.getIconByKey(.burnlifeNotimeOutlined, iconColor: stage.tagIconColor, size: CGSize(width: iconSize, height: iconSize))
        timeLabel.textColor = stage.tagTextColor
    }

    func setLabel(_ text: String) {
        timeLabel.attributedText = NSAttributedString(string: text, config: scene == .inGrid ? self.gridTextStyleConfig : self.topBarTextStyleConfig)
    }

    func setColorStage(_ color: CountDown.Stage) {
        colorStage = color
        update(stage: color)
    }
}
