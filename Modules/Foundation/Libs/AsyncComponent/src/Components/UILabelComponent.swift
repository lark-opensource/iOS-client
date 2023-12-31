//
//  UILabelComponent.swift
//  LarkThread
//
//  Created by qihongye on 2019/2/14.
//

import UIKit
import Foundation

public final class UILabelComponentProps: ASComponentProps {
    public var text: String?
    private var _attributedText = Atomic<NSAttributedString>()
    public var attributedText: NSAttributedString? {
        get { return _attributedText.wrappedValue }
        set { _attributedText.wrappedValue = newValue }
    }
    private var _font = Atomic<UIFont>(UIFont.systemFont(ofSize: UIFont.systemFontSize))
    public var font: UIFont {
        get { return _font.wrappedValue ?? UIFont.systemFont(ofSize: UIFont.systemFontSize) }
        set { _font.wrappedValue = newValue }
    }
    private var _textColor = Atomic<UIColor>(.black)
    public var textColor: UIColor {
        get { return _textColor.wrappedValue ?? .black }
        set { _textColor.wrappedValue = newValue }
    }
    private var _shadowColor = Atomic<UIColor>()
    public var shadowColor: UIColor? {
        get { return _shadowColor.wrappedValue }
        set { _shadowColor.wrappedValue = newValue }
    }
    public var shadowOffset: CGSize = CGSize(width: 0, height: -1)
    public var textAlignment: NSTextAlignment = .natural
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail
    private var _highlightedTextColor = Atomic<UIColor>()
    public var highlightedTextColor: UIColor? {
        get { return _highlightedTextColor.wrappedValue }
        set { _highlightedTextColor.wrappedValue = newValue }
    }
    public var isHighlighted: Bool = false
    public var isUserInteractionEnabled: Bool = false
    public var isEnabled: Bool = true
    public var numberOfLines: Int = 1
    public var onTap: (() -> Void)?

    /**
     * 下面这些UILabel自有的影响布局的属性不再对外暴露了
     * 因为内部使用flex通过sizeToFit计算
     * 底层实现使用boundingRect方法模拟系统UILabel的textRect(forBounds:limitedToNumberOfLines:)方法
     *
     * public var adjustsFontSizeToFitWidth: Bool = false
     * public var baselineAdjustment: UIBaselineAdjustment = .alignBaselines
     * public var preferredMaxLayoutWidth: CGFloat = 0
     */
}

public final class UILabelComponent<C: Context>: ASComponent<UILabelComponentProps, EmptyState, UILabel, C> {
    private var tapGesture: UITapGestureRecognizer?

    public override func update(view: UILabel) {
        super.update(view: view)
        view.font = props.font
        view.textColor = props.textColor
        view.shadowColor = props.shadowColor
        view.textAlignment = props.textAlignment
        view.lineBreakMode = props.lineBreakMode
        view.highlightedTextColor = props.highlightedTextColor
        view.isHighlighted = props.isHighlighted
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
        view.isEnabled = props.isEnabled
        view.numberOfLines = props.numberOfLines
        if let attrStr = props.attributedText {
            view.attributedText = attrStr
        } else {
            view.attributedText = nil
            view.text = props.text
        }
        if props.onTap != nil {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            tap.numberOfTapsRequired = 1
            tap.numberOfTouchesRequired = 1
            view.isUserInteractionEnabled = true
            view.addGestureRecognizer(tap)
            tapGesture = tap
        } else if let tapGesture = self.tapGesture {
            self.tapGesture = nil
            view.isUserInteractionEnabled = false
            view.removeGestureRecognizer(tapGesture)
        }
    }

    @objc
    private func tapped() {
        props.onTap?()
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        var _attrStr = props.attributedText
        if _attrStr == nil, let text = props.text {
            let shadow = NSShadow()
            shadow.shadowColor = props.shadowColor
            shadow.shadowOffset = props.shadowOffset

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = props.textAlignment
            paragraphStyle.lineBreakMode = props.lineBreakMode

            _attrStr = NSAttributedString(string: text, attributes: [
                .font: props.font,
                .foregroundColor: props.textColor,
                .shadow: shadow,
                .paragraphStyle: paragraphStyle
            ])
        }
        guard let attrStr = _attrStr else { return .zero }
        var textSize = attrStr.componentTextSize(for: size, limitedToNumberOfLines: props.numberOfLines)
        /// https://bytedance.feishu.cn/wiki/wikcnjS9uVfFopQObxLkB0LwIoe#
        textSize.width += 2 / UIScreen.main.scale
        return textSize
    }
}
