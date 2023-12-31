//
//  BaseTextView.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// textView 内部weak持有Listener，主线程回调
public protocol TextViewListenersProtocol: AnyObject {
    func onSetTextViewAttributedText()
    func onSetTextViewText()
}

public extension TextViewListenersProtocol {
    func onSetTextViewAttributedText() {}
    func onSetTextViewText() {}
}

private struct TextViewListenerUnit {
    weak var obj: TextViewListenersProtocol?
}

open class BaseTextView: UITextView {

    open override var bounds: CGRect {
        didSet {
            var size = self.placeholderTextView.frame.size
            if size.width != frame.width {
                size.width = frame.width
                self.placeholderTextView.frame.size = size
            }
        }
    }

    open var placeholder: String? {
        set {
            placeholderTextView.text = newValue
            self.resizePlaceholder()
        }
        get { return placeholderTextView.text }
    }

    open var attributedPlaceholder: NSAttributedString? {
        set {
            placeholderTextView.attributedText = newValue
            self.resizePlaceholder()
        }
        get { return placeholderTextView.attributedText }
    }

    open var placeholderTextColor: UIColor? {
        set { placeholderTextView.textColor = newValue }
        get { return placeholderTextView.textColor }
    }

    open var placeholderFadeTime: TimeInterval = 0

    /// 占位文字的透明度
    open var placeholderAlpha: CGFloat = 1.0 {
        didSet {
            if placeholderAlpha != oldValue {
                setPlaceholderVisible(currentText: self.text)
            }
        }
    }

    open private(set) var placeholderTextView: UITextView = UITextView()

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.preparePlaceholder()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.preparePlaceholder()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        self.resizePlaceholder()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        TextContainerObserveKey.allCases.forEach { (key) in
            self.textContainer.removeObserver(self, forKeyPath: key.rawValue)
        }
    }

    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        self.setPlaceholderVisible(currentText: self.text)
        return super.becomeFirstResponder()
    }

    @objc
    func observeTextViewTextDidChange(noti: Notification) {
        self.setPlaceholderVisible(currentText: self.text)
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if #available(iOS 13, *), !self.isFirstResponder {
            self.becomeFirstResponder()
        }
    }

    private var listeners: [TextViewListenerUnit] = []

    public func addListener(_ listener: TextViewListenersProtocol) {
        let unit = TextViewListenerUnit(obj: listener)
        listeners.append(unit)
    }

    public func removeListener(listener: TextViewListenersProtocol) {
        listeners.removeAll { unit in
           return unit.obj === listener
        }
    }

    public func removeAllListener() {
        listeners = []
    }
}

// placeholder
extension BaseTextView {

    enum TextContainerObserveKey: String, CaseIterable {
        case exclusionPaths
        case lineFragmentPadding
    }

    open override var font: UIFont? {
        didSet {
            placeholderTextView.font = self.font
        }
    }

    open override var text: String! {
        didSet {
            self.setPlaceholderVisible(currentText: self.text)
            self.listeners.forEach { $0.obj?.onSetTextViewText() }
        }
    }

    open override var attributedText: NSAttributedString! {
        didSet {
            self.setPlaceholderVisible(currentText: self.text)
            self.listeners.forEach { $0.obj?.onSetTextViewAttributedText() }
        }
    }

    open override var textContainerInset: UIEdgeInsets {
        didSet { placeholderTextView.textContainerInset = self.textContainerInset }
    }

    open override var textAlignment: NSTextAlignment {
        didSet { placeholderTextView.textAlignment = self.textAlignment }
    }

    func preparePlaceholder() {
        placeholderTextView.frame = self.bounds
        placeholderTextView.isOpaque = false
        placeholderTextView.backgroundColor = UIColor.clear
        placeholderTextView.textColor = UIColor(white: 0.7, alpha: 0.7)
        placeholderTextView.textAlignment = self.textAlignment
        placeholderTextView.isEditable = false
        placeholderTextView.isScrollEnabled = false
        placeholderTextView.isUserInteractionEnabled = false
        placeholderTextView.font = self.font
        placeholderTextView.isAccessibilityElement = false
        placeholderTextView.contentOffset = self.contentOffset
        placeholderTextView.contentInset = self.contentInset
        placeholderTextView.isSelectable = false
        placeholderTextView.textContainer.exclusionPaths = self.textContainer.exclusionPaths
        placeholderTextView.textContainer.lineFragmentPadding = self.textContainer.lineFragmentPadding
        placeholderTextView.textContainerInset = self.textContainerInset
        self.setPlaceholderVisible(currentText: self.text)
        self.clipsToBounds = true
        self.addTextViewObserver()
    }

    func addTextViewObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(observeTextViewTextDidChange(noti:)),
            name: UITextView.textDidChangeNotification,
            object: self)
        TextContainerObserveKey.allCases.forEach { (key) in
            self.textContainer.addObserver(self, forKeyPath: key.rawValue, options: .new, context: nil)
        }
    }

    func setPlaceholderVisible(currentText: String) {
        if currentText.isEmpty {
            // 当前文本为空 显示placeholder
            if !placeholderTextView.isDescendant(of: self) {
                self.addSubview(placeholderTextView)
                self.sendSubviewToBack(placeholderTextView)
                placeholderTextView.alpha = 0
            }
            if placeholderFadeTime > 0 {
                UIView.animate(withDuration: placeholderFadeTime) { [weak self] in
                    self?.placeholderTextView.alpha = self?.placeholderAlpha ?? 1.0
                }
            } else {
                placeholderTextView.alpha = self.placeholderAlpha
            }
        } else {
            // 隐藏 placeholder
            if placeholderFadeTime > 0 {
                UIView.animate(withDuration: placeholderFadeTime, animations: {
                    self.placeholderTextView.alpha = 0
                }, completion: { _ in
                    self.placeholderTextView.removeFromSuperview()
                })
            } else {
                placeholderTextView.removeFromSuperview()
            }
        }
    }

    // swiftlint:disable:next block_based_kvo
    override open func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case TextContainerObserveKey.exclusionPaths.rawValue:
            placeholderTextView.textContainer.exclusionPaths = self.textContainer.exclusionPaths
            self.resizePlaceholder()
        case TextContainerObserveKey.lineFragmentPadding.rawValue:
            placeholderTextView.textContainer.lineFragmentPadding = self.textContainer.lineFragmentPadding
            self.resizePlaceholder()
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func resizePlaceholder() {
        placeholderTextView.frame.size = frame.size
    }
}
