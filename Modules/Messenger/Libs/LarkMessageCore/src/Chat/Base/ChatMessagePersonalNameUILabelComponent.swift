//
//  ChatMessagePersonalNameUILabelComponent.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/5/11.
//

import Foundation
import UIKit
import EEFlexiable
import AsyncComponent
import LKCommonsLogging

final public class ChatMessagePersonalNameUILabelComponentProps: ASComponentProps {
    public var text: String?
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
    public var oneLineHeight: CGFloat = 0
    public var contentPreferMaxWidth: CGFloat = 0
    public var textAlignment: NSTextAlignment = .natural
    private var _highlightedTextColor = Atomic<UIColor>()
    public var highlightedTextColor: UIColor? {
        get { return _highlightedTextColor.wrappedValue }
        set { _highlightedTextColor.wrappedValue = newValue }
    }
    public var isHighlighted: Bool = false
    public var isUserInteractionEnabled: Bool = false
    public var isEnabled: Bool = true
    public var onTap: (() -> Void)?
    public var chatterId: String = ""
}

private final class ChatMessagePersonalNameUILabelComponentLogger {
    static let logger = Logger.log(ChatMessagePersonalNameUILabelComponentLogger.self, category: "ChatMessagePersonalNameUILabelComponent")
}

final public class ChatMessagePersonalNameUILabelComponent<C: Context>: ASComponent<ChatMessagePersonalNameUILabelComponentProps, EmptyState, UILabel, C> {
    private var tapGesture: UITapGestureRecognizer?
    private var resultWidth: CGFloat = 0

    public override func update(view: UILabel) {
        super.update(view: view)
        view.font = props.font
        view.textColor = props.textColor
        view.textAlignment = props.textAlignment
        view.highlightedTextColor = props.highlightedTextColor
        view.isHighlighted = props.isHighlighted
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
        view.isEnabled = props.isEnabled
        view.text = props.text
        if props.onTap != nil {
           tapGesture = view.lu.addTapGestureRecognizer(action: #selector(tapped), target: self)
        } else if let tapGesture = self.tapGesture {
            self.tapGesture = nil
            view.isUserInteractionEnabled = false
            view.removeGestureRecognizer(tapGesture)
        }

        if self.resultWidth > props.contentPreferMaxWidth {
            view.lineBreakMode = .byTruncatingTail
        } else {
            view.lineBreakMode = .byClipping
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
        guard let text = props.text else { return .zero }

        var textWidth = self.width(for: text, availableWidth: CGFloat.greatestFiniteMagnitude, contentHeight: props.oneLineHeight, contentFont: props.font)
        textWidth = ceil(textWidth)
        self.resultWidth = textWidth + 2 / UIScreen.main.scale
        ChatMessagePersonalNameUILabelComponentLogger.logger.info(" message cell fromChatterId: \(self.props.chatterId) width: \(self.resultWidth) system width: \(textWidth)")
        return CGSize(width: self.resultWidth, height: props.oneLineHeight)
    }

    private func width(for string: String, availableWidth: CGFloat, contentHeight: CGFloat, contentFont: UIFont) -> CGFloat {
        return NSString(string: string).boundingRect(
            with: CGSize(width: availableWidth, height: contentHeight),
            options: .usesLineFragmentOrigin,
            attributes: [.font: contentFont],
            context: nil).size.width
    }
}
