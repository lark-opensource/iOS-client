//
//  UDMultilineTextField.swift
//  UniverseDesignInput
//
//  Created by 姚启灏 on 2020/9/23.
//

import Foundation
import UIKit

public protocol UDMultilineTextFieldDelegate: UDInput, UITextViewDelegate {
    func calculateText(_ text: String) -> NSAttributedString?
}

public extension UDMultilineTextFieldDelegate {
    func calculateText(_ text: String) -> NSAttributedString? {
        return nil
    }
}

open class UDMultilineTextField: UIView {
    
    private var textViewType: UDBaseTextView.Type = UDBaseTextView.self
    
    public lazy var input: UDBaseTextView = {
        let input = textViewType.init()
        input.backgroundColor = .clear
        return input
    }()

    private var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.isHidden = true
        countLabel.textColor = UDInputColorTheme.inputCharactercounterNormalColor
        countLabel.font = UIFont.ud.caption1
        return countLabel
    }()

    private var inputWrapperView: UIView = {
        let inputWrapperView = UIView()
        inputWrapperView.layer.borderWidth = 1
        inputWrapperView.layer.cornerRadius = 6
        return inputWrapperView
    }()

    lazy var errorLabel: UILabel = {
        let errorLabel = UILabel()
        errorLabel.font = UIFont.ud.body2
        errorLabel.textColor = UDInputColorTheme.inputErrorHelperValidationTextColor
        errorLabel.isHidden = true
        return errorLabel
    }()

    private var customView: UIView?

    public var config: UDMultilineTextFieldUIConfig {
        didSet {
            update()
            layoutViewsByConfig(config, oldValue: oldValue)
        }
    }

    var status: UDInputStatus = .normal {
        didSet {
            self.updateStatus()
            self.layoutViewsByStatus(status, oldValue: oldValue)
        }
    }

    public weak var delegate: UDMultilineTextFieldDelegate?

    public var text: String! {
        get {
            return self.input.text
        }
        set {
            self.input.text = newValue
        }
    }

    public var placeholder: String? {
        get {
            return self.input.placeholder
        }
        set {
            self.input.placeholder = newValue
        }
    }

    public var attributedPlaceholder: NSAttributedString? {
        get {
            return self.input.attributedPlaceholder
        }
        set {
            self.input.attributedPlaceholder = newValue
        }
    }

    public override var isFirstResponder: Bool {
        return self.input.isFirstResponder
    }

    public var selectedRange: NSRange! {
        get {
            return self.input.selectedRange
        }
        set {
            self.input.selectedRange = newValue
        }
    }

    public var isEditable: Bool {
        get {
            return self.input.isEditable
        }
        set {
            self.input.isEditable = newValue
            if isEditable {
                self.status = .normal
            } else {
                self.status = .disable
            }
        }
    }

    public var isSelectable: Bool {
        get {
            return self.input.isSelectable
        }
        set {
            self.input.isSelectable = newValue
        }
    }

    public var dataDetectorTypes: UIDataDetectorTypes {
        get {
            return self.input.dataDetectorTypes
        }
        set {
            self.input.dataDetectorTypes = newValue
        }
    }

    public var allowsEditingTextAttributes: Bool {
        get {
            return self.input.allowsEditingTextAttributes
        }
        set {
            self.input.allowsEditingTextAttributes = newValue
        }
    }

    public var attributedText: NSAttributedString! {
        get {
            return self.input.attributedText
        }
        set {
            self.input.attributedText = newValue
        }
    }

    public var typingAttributes: [NSAttributedString.Key: Any] {
        get {
            return self.input.typingAttributes
        }
        set {
            self.input.typingAttributes = newValue
        }
    }

    public var clearsOnInsertion: Bool {
        get {
            return self.input.clearsOnInsertion
        }
        set {
            self.input.clearsOnInsertion = newValue
        }
    }

    public var linkTextAttributes: [NSAttributedString.Key: Any]! {
        get {
            return self.input.linkTextAttributes
        }
        set {
            self.input.linkTextAttributes = newValue
        }
    }

    public var textContainerInset: UIEdgeInsets {
        get {
            return self.input.textContainerInset
        }
        set {
            self.input.textContainerInset = newValue
        }
    }

    @available(iOS 13.0, *)
    public var usesStandardTextScaling: Bool {
        get {
            return self.input.usesStandardTextScaling
        }
        set {
            self.input.usesStandardTextScaling = newValue
        }
    }
    public init(config: UDMultilineTextFieldUIConfig = UDMultilineTextFieldUIConfig(), textViewType: UDBaseTextView.Type = UDBaseTextView.self) {
        self.textViewType = textViewType
        self.config = config

        super.init(frame: .zero)

        self.addSubview(inputWrapperView)
        self.addSubview(errorLabel)

        inputWrapperView.addSubview(countLabel)
        inputWrapperView.addSubview(input)
        input.delegate = self

        inputWrapperView.snp.remakeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }

        input.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(config.minHeight)
            make.top.left.right.equalToSuperview()
            if config.isShowWordCount {
                make.bottom.lessThanOrEqualToSuperview()
            } else {
                make.bottom.equalToSuperview()
            }
        }

        if config.isShowWordCount {
            countLabel.snp.remakeConstraints { (make) in
                make.left.greaterThanOrEqualToSuperview()
                make.top.equalTo(input.snp.bottom).offset(2)
                make.right.equalToSuperview().offset(-12)
                make.bottom.equalToSuperview().offset(-8)
            }
        }

        update()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func resignFirstResponder() -> Bool {
        return self.input.resignFirstResponder()
    }

    /// Set UDTextField Status
    /// - Parameter status: UDTextField.Status
    public func setStatus(_ status: UDInputStatus) {
        if !isEditable {
            self.status = .disable
            return
        }

        self.status = status
    }

    public override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return self.input.becomeFirstResponder()
    }

    private func update() {
        updateStatus()
        self.setCount()

        self.input.font = config.font
        self.input.textAlignment = config.textAlignment
        self.input.textContainerInset = config.textMargins
        self.input.placeholderTextColor = config.placeholderColor
        self.input.textColor = config.textColor

        self.errorLabel.text = config.errorMessege

        setNeedsLayout()
    }

    private func updateStatus() {
        var borderColor: UIColor?
        var backgroundColor = config.backgroundColor

        switch self.status {
        case .normal:
            borderColor = config.borderColor
        case .activated:
            borderColor = UDInputColorTheme.inputActivatedBorderColor
        case .disable:
            borderColor = UDInputColorTheme.inputDisableBorderColor
            backgroundColor = UDInputColorTheme.inputDisableBgColor
        case .error:
            borderColor = UDInputColorTheme.inputErrorBorderColor
        }

        self.inputWrapperView.backgroundColor = backgroundColor

        if config.isShowBorder, let borderColor = borderColor {
            self.inputWrapperView.layer.ud.setBorderColor(borderColor, bindTo: self)
        } else {
            self.inputWrapperView.layer.ud.setBorderColor(.clear, bindTo: self)
        }
    }

    private func layoutViewsByConfig(_ config: UDMultilineTextFieldUIConfig,
                                     oldValue: UDMultilineTextFieldUIConfig) {
        if oldValue.isShowWordCount != config.isShowWordCount {
            if config.isShowWordCount {
                input.snp.remakeConstraints { (make) in
                    make.height.greaterThanOrEqualTo(config.minHeight)
                    make.top.left.right.equalToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                }
                countLabel.snp.remakeConstraints { (make) in
                    make.left.greaterThanOrEqualToSuperview()
                    make.top.equalTo(input.snp.bottom).offset(2)
                    make.right.equalToSuperview().offset(-12)
                    make.bottom.equalToSuperview().offset(-8)
                }
            } else {
                countLabel.snp.removeConstraints()
            }
            countLabel.isHidden = !config.isShowWordCount
        }

        if oldValue.minHeight != config.minHeight {
            input.snp.remakeConstraints { (make) in
                make.height.greaterThanOrEqualTo(config.minHeight)
                make.top.left.right.equalToSuperview()
                if config.isShowWordCount {
                    make.bottom.lessThanOrEqualToSuperview()
                } else {
                    make.bottom.equalToSuperview()
                }
            }
        }
    }

    private func layoutViewsByStatus(_ status: UDInputStatus, oldValue: UDInputStatus) {
        if oldValue != self.status {
            if self.status != .error {
                self.errorLabel.snp.removeConstraints()
                inputWrapperView.snp.remakeConstraints { (make) in
                    make.top.left.right.bottom.equalToSuperview()
                }
            } else {
                inputWrapperView.snp.remakeConstraints { (make) in
                    make.top.left.right.equalToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                }

                self.errorLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(inputWrapperView.snp.bottom).offset(8)
                    make.left.equalToSuperview()
                    make.right.lessThanOrEqualToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                }
            }
            self.errorLabel.isHidden = self.status != .error
        }
    }

    private func setCount() {
        if let customText = self.delegate?.calculateText(input.text) {
            self.countLabel.attributedText = customText
            return
        }

        var text = "\(input.text.count)"
        if let maximumTextLength = config.maximumTextLength {
            text += "/\(maximumTextLength)"
        }
        self.countLabel.text = text
    }
}

extension UDMultilineTextField: UITextViewDelegate {
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let function = self.delegate?.textViewShouldBeginEditing {
            return function(textView)
        } else {
            return true
        }
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if let function = self.delegate?.textViewShouldEndEditing {
            return function(textView)
        } else {
            return true
        }
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.textViewDidBeginEditing?(textView)
        self.setStatus(.activated)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.delegate?.textViewDidEndEditing?(textView)
        self.setStatus(.normal)
    }

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
        if let function = self.delegate?.textView?(textView,
                                                   shouldChangeTextIn: range,
                                            replacementText: text) {
            return function
        } else {
            return true
        }
    }

    public func textViewDidChange(_ textView: UITextView) {
        if let text = input.text,
            let maximumTextLength = config.maximumTextLength,
            text.count >= maximumTextLength {
            let index = text.index(text.startIndex, offsetBy: maximumTextLength)
            self.text = String(text[..<index])
        }
        self.setCount()
        self.delegate?.textViewDidChange?(textView)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        self.delegate?.textViewDidChangeSelection?(textView)
    }

    public func textView(_ textView: UITextView,
                         shouldInteractWith URL: URL,
                         in characterRange: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        if let function = self.delegate?.textView?(textView,
                                                   shouldInteractWith: URL,
                                                   in: characterRange,
                                                   interaction: interaction) {
            return function
        } else {
            return true
        }
    }

    public func textView(_ textView: UITextView,
                         shouldInteractWith textAttachment: NSTextAttachment,
                         in characterRange: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        if let function = self.delegate?.textView?(textView,
                                                   shouldInteractWith: textAttachment,
                                                   in: characterRange,
                                                   interaction: interaction) {
            return function
        } else {
            return true
        }
    }
}
