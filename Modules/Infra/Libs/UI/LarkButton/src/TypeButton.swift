//
//  TypeButton.swift
//  LarkUIKitDemo
//
//  Created by KongKaikai on 2018/12/10.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor

public final class TypeButton: UIButton {
    /// 按钮样式，内部没有约束宽和高
    /// large是：高固定48px，宽度距离屏幕左右两侧固定16px。
    /// normal: 高固定28px，宽度取决于文字内容宽度，最小60px
    /// text: 高固定22px，宽度取决于文字内容宽度，宽度自适应。
    public enum Style {

        /// 一级常态按钮
        case largeA

        /// 二级常态按钮
        case largeB

        /// 三级常态按钮
        case largeC

        /// 正常按钮
        case normalA

        /// 正常按钮
        case normalB

        /// 正常按钮
        case normalC

        /// 正常按钮
        case normalD

        /// 文本按钮
        case textA

        /// 文本按钮
        case textB
    }
    /// 默认的高度值，这个值不会影响Button的实际高度，但是为了风格统一，你可以使用这个值来设置按钮的高度
    public var defaultHeight: CGFloat {
        switch style {
        case .largeA, .largeB, .largeC: return 48
        case .normalA, .normalB, .normalC, .normalD: return 28
        case .textA, .textB: return 22
        }
    }

    public var style: Style = .normalA {
        didSet {
            formatStyle()
        }
    }

    override public var isEnabled: Bool {
        didSet {
            formart(isEnabled: isEnabled)
        }
    }

    override public var isHighlighted: Bool {
        didSet {
            // 按钮按下会自动变高亮，以此设置按下时的状态
            guard isEnabled else { return }
            formart(highlighted: isHighlighted)
        }
    }

    private var normalBackgroundColor: UIColor?
    private var highlightedBackgroundColor: UIColor?
    private var disabledBackgroundColor: UIColor?

    private var hasBorder: Bool = false

    private static let highlightedCoverColor = UIColor.ud.N900.withAlphaComponent(0.05)
    private static let disabledCoverColor = UIColor.ud.N00.withAlphaComponent(0.5)

    public convenience init(style: Style) {
        self.init(type: .custom)
        self.style = style
        formatStyle()

        adjustsImageWhenDisabled = false
        adjustsImageWhenHighlighted = false
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func defaultMinWidth(with maxAvailableWidth: CGFloat) -> CGFloat {
        switch style {
        case .largeA, .largeB, .largeC: return maxAvailableWidth - 32
        case .normalA, .normalB, .normalC, .normalD, .textA, .textB: return 60
        }
    }

    private func formatStyle() {

        self.clipsToBounds = true
        self.layer.cornerRadius = 4

        let inset: (_ verticalContentInset: CGFloat, _ horizontalContentInset: CGFloat) -> UIEdgeInsets = {
            UIEdgeInsets(top: $0, left: $1, bottom: $0, right: $1)
        }

        switch style {
        case .largeA:
            set(titleColor: UIColor.ud.primaryOnPrimaryFill,
                titleFontSize: 17,
                backgroundColor: UIColor.ud.colorfulBlue,
                contentEdgeInsets: inset(12, 24))

        case .largeB:
            set(titleColor: UIColor.ud.N700,
                titleFontSize: 17,
                backgroundColor: UIColor.ud.N00,
                contentEdgeInsets: inset(12, 24),
                borderColor: UIColor.ud.N300)

        case .largeC:
            set(titleColor: UIColor.ud.N600,
                titleFontSize: 17,
                backgroundColor: UIColor.ud.N00,
                contentEdgeInsets: inset(12, 24),
                borderColor: UIColor.ud.N300)

        case .normalA:
            set(titleColor: UIColor.ud.primaryOnPrimaryFill,
                titleFontSize: 14,
                backgroundColor: UIColor.ud.colorfulBlue,
                contentEdgeInsets: inset(3, 16))

        case .normalB:
            set(titleColor: UIColor.ud.colorfulBlue,
                titleFontSize: 14,
                backgroundColor: UIColor.ud.N00,
                contentEdgeInsets: inset(3, 16),
                borderColor: UIColor.ud.colorfulBlue,
                disabledTitleColor: UIColor.ud.N00,
                disabledbackgroundColor: UIColor.ud.N300)

        case .normalC:
            set(titleColor: UIColor.ud.colorfulBlue,
                titleFontSize: 14,
                backgroundColor: UIColor.ud.N00,
                contentEdgeInsets: inset(3, 16),
                borderColor: UIColor.ud.N300,
                disabledTitleColor: UIColor.ud.N00,
                disabledbackgroundColor: UIColor.ud.N300)

        case .normalD:
            set(titleColor: UIColor.ud.N700,
                titleFontSize: 14,
                backgroundColor: UIColor.ud.N00,
                contentEdgeInsets: inset(3, 16),
                borderColor: UIColor.ud.N300,
                disabledTitleColor: UIColor.ud.N00,
                disabledbackgroundColor: UIColor.ud.N300)

        case .textA:
            set(titleColor: UIColor.ud.rgb(0x007aFF),
                titleFontSize: 14,
                backgroundColor: UIColor.ud.N00,
                contentEdgeInsets: inset(2, 2),
                onlyAdjustText: true)

        case .textB:
            set(titleColor: UIColor.ud.N700,
                titleFontSize: 14,
                backgroundColor: UIColor.ud.N00,
                contentEdgeInsets: inset(2, 2),
                onlyAdjustText: true)
        }
    }

    fileprivate func set(
        titleColor: UIColor,
        titleFontSize: CGFloat,
        backgroundColor: UIColor,
        contentEdgeInsets: UIEdgeInsets,
        onlyAdjustText: Bool = false,
        borderColor: UIColor? = nil,
        disabledTitleColor: UIColor? = nil,
        disabledbackgroundColor: UIColor? = nil
    ) {

        let highlighted: (UIColor) -> UIColor = { $0.ud.withOver(TypeButton.highlightedCoverColor) }
        let disabled: (UIColor) -> UIColor = { $0.ud.withOver(TypeButton.disabledCoverColor) }

        self.titleLabel?.font = UIFont.systemFont(ofSize: titleFontSize)

        self.setTitleColor(titleColor, for: .normal)
        self.setTitleColor(highlighted(titleColor), for: .highlighted)
        self.setTitleColor(disabled(disabledTitleColor ?? titleColor), for: .disabled)

        self.backgroundColor = backgroundColor
        if !onlyAdjustText {
            self.normalBackgroundColor = backgroundColor
            self.highlightedBackgroundColor = highlighted(backgroundColor)
            self.disabledBackgroundColor = disabled(disabledbackgroundColor ?? backgroundColor)
        } else {
            self.normalBackgroundColor = nil
            self.highlightedBackgroundColor = nil
            self.disabledBackgroundColor = nil
        }

        self.contentEdgeInsets = contentEdgeInsets

        if let color = borderColor {
            self.layer.borderWidth = 1
            self.layer.ud.setBorderColor(color)
            self.hasBorder = true
        } else {
            self.layer.borderWidth = 0
            self.hasBorder = false
        }
    }

    fileprivate func formart(isEnabled: Bool) {
        self.backgroundColor = isEnabled ?
            normalBackgroundColor ?? self.backgroundColor :
            disabledBackgroundColor ?? self.backgroundColor
        self.layer.borderWidth = isEnabled && hasBorder ? 1 : 0
    }

    fileprivate func formart(highlighted: Bool) {
        self.backgroundColor = highlighted ?
            highlightedBackgroundColor ?? self.backgroundColor :
            normalBackgroundColor ?? self.backgroundColor
    }
}
