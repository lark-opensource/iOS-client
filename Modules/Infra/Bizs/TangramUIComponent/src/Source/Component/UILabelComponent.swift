//
//  UILabelComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/4/20.
//

import UIKit
import Foundation
import TangramComponent

final public class UILabelComponentProps: Props {
    public typealias UILabelTapped = () -> Void

    public var text: String?
    public var attributedText: EquatableWrapper<NSAttributedString?> = .init(value: nil)
    public var font: UIFont = UIFont.ud.body2
    public var textColor: UIColor = UIColor.ud.N900
    public var shadowColor: UIColor?
    public var shadowOffset: CGSize = CGSize(width: 0, height: -1)
    public var textAlignment: NSTextAlignment = .natural
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail
    public var highlightedTextColor: UIColor?
    public var isHighlighted: Bool = false
    public var isUserInteractionEnabled: Bool = false
    public var isEnabled: Bool = true
    public var numberOfLines: Int = 1
    public var lineSpacing: CGFloat = 4
    public var onTap: EquatableWrapper<UILabelTapped?> = .init(value: nil)

    public init() {}

    public func clone() -> UILabelComponentProps {
        let clone = UILabelComponentProps()
        clone.text = text
        clone.attributedText = attributedText
        clone.font = font.copy() as? UIFont ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        clone.textColor = textColor.copy() as? UIColor ?? UIColor.black
        clone.shadowColor = shadowColor?.copy() as? UIColor
        clone.shadowOffset = shadowOffset
        clone.textAlignment = textAlignment
        clone.lineBreakMode = lineBreakMode
        clone.highlightedTextColor = highlightedTextColor?.copy() as? UIColor
        clone.isHighlighted = isHighlighted
        clone.isUserInteractionEnabled = isUserInteractionEnabled
        clone.isEnabled = isEnabled
        clone.numberOfLines = numberOfLines
        clone.lineSpacing = lineSpacing
        clone.onTap = onTap
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? UILabelComponentProps else { return false }
        return text == old.text &&
            attributedText == old.attributedText &&
            font == old.font &&
            textColor == old.textColor &&
            shadowColor == old.shadowColor &&
            shadowOffset == old.shadowOffset &&
            textAlignment == old.textAlignment &&
            lineBreakMode == old.lineBreakMode &&
            highlightedTextColor == old.highlightedTextColor &&
            isHighlighted == old.isHighlighted &&
            isUserInteractionEnabled == old.isUserInteractionEnabled &&
            isEnabled == old.isEnabled &&
            numberOfLines == old.numberOfLines &&
            lineSpacing == old.lineSpacing &&
            onTap == old.onTap
    }
}

public final class UILabelComponent<C: Context>: RenderComponent<UILabelComponentProps, UILabel, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    private var tapGesture: UITapGestureRecognizer?

    public override func update(_ view: UILabel) {
        super.update(view)
        if view.font != props.font { view.font = props.font }
        if view.textColor != props.textColor { view.textColor = props.textColor }
        if view.shadowColor != props.shadowColor { view.shadowColor = props.shadowColor }
        view.textAlignment = props.textAlignment
        view.lineBreakMode = props.lineBreakMode
        view.highlightedTextColor = props.highlightedTextColor
        view.isHighlighted = props.isHighlighted
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
        view.isEnabled = props.isEnabled
        view.numberOfLines = props.numberOfLines
        // 如果外部使用attributedText，则需要自己配置lineHeight
        if let attr = props.attributedText.value {
            view.attributedText = attr
        } else if let attr = createAttrForText(props: props) { // 如果外部使用text，则需要配置lineHeight
            view.attributedText = attr
        } else {
            view.attributedText = nil
            view.text = nil
        }

        view.gestureRecognizers?.forEach({ view.removeGestureRecognizer($0) })
        if props.onTap.value == nil {
            view.isUserInteractionEnabled = false
            self.tapGesture = nil
        } else if let tap = tapGesture {
            view.addGestureRecognizer(tap)
            view.isUserInteractionEnabled = true
        } else {
            view.isUserInteractionEnabled = true
            tapGesture = view.lu.addTapGestureRecognizer(action: #selector(tapped), target: self)
        }
    }

    @objc
    private func tapped() {
        props.onTap.value?()
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        // 当使用负数计算时会算出来负数，负数size系统也会展示
        // https://bytedance.feishu.cn/docx/HYjKdnX8Zol0n9xOa9rcu98UniO
        if size.width < 0 || size.height < 0 {
            return .zero
        }
        var attr = props.attributedText.value ?? createAttrForText(props: props)
        guard let attrStr = attr else { return .zero }
        var textSize = attrStr.componentTextSize(for: size, limitedToNumberOfLines: props.numberOfLines)
        /// https://bytedance.feishu.cn/wiki/wikcnjS9uVfFopQObxLkB0LwIoe#
        textSize.width += 2 / UIScreen.main.scale
        return textSize
    }

    private func createAttrForText(props: UILabelComponentProps) -> NSAttributedString? {
        guard let text = props.text, !text.isEmpty else {
            return nil
        }
        let shadow = NSShadow()
        shadow.shadowColor = props.shadowColor
        shadow.shadowOffset = props.shadowOffset

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = props.textAlignment
        paragraphStyle.lineBreakMode = props.lineBreakMode
        // 不能通过minimumLineHeight和maximumLineHeight设置行高，否则会导致单行文字靠下展示，使得线上已有样式不对
        paragraphStyle.lineSpacing = props.lineSpacing
//        paragraphStyle.minimumLineHeight = props.font.figmaHeight
//        paragraphStyle.maximumLineHeight = props.font.figmaHeight

        return NSAttributedString(string: text, attributes: [
            .font: props.font,
            .foregroundColor: props.textColor,
            .shadow: shadow,
            .paragraphStyle: paragraphStyle
        ])
    }
}
