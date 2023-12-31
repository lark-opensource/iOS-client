//
//  UDTextField.swift
//  UniverseDesignInput
//
//  Created by 姚启灏 on 2020/9/18.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignFont

/// UDTextField Delegate
public protocol UDTextFieldDelegate: UDInput, UITextFieldDelegate {}

/// UDTextField
open class UDTextField: UIView {

    var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.isHidden = true
        titleLabel.textColor = UDInputColorTheme.inputCharactercounterNormalColor
        titleLabel.font = UIFont.ud.body0
        return titleLabel
    }()

    var errorLabel: UILabel = {
        let errorLabel = UILabel()
        errorLabel.font = UIFont.ud.body2
        errorLabel.textColor = UDInputColorTheme.inputErrorHelperValidationTextColor
        errorLabel.isHidden = true
        return errorLabel
    }()

    public var cornerRadius: CGFloat {
        get { inputWrapperView.layer.cornerRadius }
        set { inputWrapperView.layer.cornerRadius = newValue }
    }

    private var containerView: UIView = UIView()

    private var inputWrapperView: UIView = {
        let inputWrapperView = UIView()
        inputWrapperView.layer.borderWidth = 1
        inputWrapperView.layer.cornerRadius = 6
        return inputWrapperView
    }()

    private var textFieldType: UITextField.Type = UITextField.self

    public lazy var input: UITextField = { textFieldType.init() }()

    var leftView: UIView?

    var rightView: UIView?

    /// UDTextField delegate
    public weak var delegate: UDTextFieldDelegate?

    /// UDTextField UI Config
    public var config: UDTextFieldUIConfig {
        didSet {
            self.update()
            self.layoutViewsByConfig(config, oldValue: oldValue)
        }
    }

    var status: UDInputStatus = .normal {
        didSet {
            self.updateStatus()
            self.layoutViewsByStatus(status, oldValue: oldValue)
        }
    }

    public override var isFirstResponder: Bool {
        return self.input.isFirstResponder
    }

    public var isEnable: Bool {
        get {
            self.input.isEnabled
        }
        set {
            self.input.isEnabled = newValue
            if !newValue {
                self.status = .disable
            }
        }
    }

    public var isEditing: Bool {
        return self.input.isEditing
    }

    public var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
            self.titleLabel.textColor = UDInputColorTheme.inputInputcompleteTextColor
        }
    }

    public var text: String? {
        get {
            return self.input.text
        }
        set {
            self.input.text = newValue
        }
    }

    public var placeholder: String? {
        get {
            return self.input.attributedPlaceholder?.string
        }
        set {
            let attributes = [NSAttributedString.Key.foregroundColor: config.placeholderColor]
            self.input.attributedPlaceholder = NSAttributedString(string: newValue ?? "",
                                                                  attributes: attributes)
        }
    }

    public var attributedText: NSAttributedString? {
        get {
            return self.input.attributedText
        }
        set {
            self.input.attributedText = newValue
        }
    }

    public var defaultTextAttributes: [NSAttributedString.Key: Any] {
        get {
            return self.input.defaultTextAttributes
        }
        set {
            self.input.defaultTextAttributes = newValue
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

    public init(config: UDTextFieldUIConfig = UDTextFieldUIConfig()) {
        self.config = config
        super.init(frame: .zero)
        self.initUDTextField()
    }

    public init(config: UDTextFieldUIConfig = UDTextFieldUIConfig(), textFieldType: UITextField.Type) {
        self.config = config
        self.textFieldType = textFieldType
        super.init(frame: .zero)
        self.initUDTextField()
    }

    func initUDTextField() {
        self.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalTo(config.contentMargins)
        }

        containerView.addSubview(inputWrapperView)
        containerView.addSubview(errorLabel)
        containerView.addSubview(titleLabel)

        self.inputWrapperView.addSubview(input)
        self.inputWrapperView.clipsToBounds = true
        input.delegate = self

        self.inputWrapperView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        self.layoutInput()

        self.titleLabel.isHidden = !config.isShowTitle
        if config.isShowTitle {
            self.titleLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.bottom.equalTo(inputWrapperView.snp.top).offset(-8)
            }
        }

        self.errorLabel.isHidden = self.status != .error
        if self.status == .error {
            self.errorLabel.snp.makeConstraints { (make) in
                make.top.equalTo(inputWrapperView.snp.bottom).offset(8)
                make.left.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
            }
        }

        update()

        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(textFieldContentDidChange),
                         name: UITextField.textDidChangeNotification,
                         object: self.input)

    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return self.input.resignFirstResponder()
    }

    public func setLeftView(_ leftView: UIView?) {
        self.leftView?.snp.removeConstraints()
        self.leftView?.removeFromSuperview()
        self.leftView = leftView
        self.leftView?.setContentHuggingPriority(.required, for: .horizontal)
        self.leftView?.setContentCompressionResistancePriority(.required, for: .horizontal)

        if let leftView = leftView {
            self.inputWrapperView.addSubview(leftView)
            self.layoutInput()

            if let margins = config.leftImageMargins {
                leftView.snp.remakeConstraints { (make) in
                    make.edges.equalTo(margins)
                }
            } else {
                let leftImageMargin: CGFloat = config.leftImageMargin ?? -12
                leftView.snp.remakeConstraints { (make) in
                    make.top.greaterThanOrEqualToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                    make.centerY.equalToSuperview()
                    make.left.equalToSuperview().offset(config.isShowBorder ? 12 : 0)
                    make.right.equalTo(input.snp.left).offset(leftImageMargin)
                }
            }
        }
    }

    public func setRightView(_ rightView: UIView?) {
        self.rightView?.snp.removeConstraints()
        self.rightView?.removeFromSuperview()
        self.rightView = rightView
        self.rightView?.setContentHuggingPriority(.required, for: .horizontal)
        self.rightView?.setContentCompressionResistancePriority(.required, for: .horizontal)

        if let rightView = rightView {
            self.inputWrapperView.addSubview(rightView)
            self.layoutInput()

            if let margins = config.rightImageMargins {
                rightView.snp.remakeConstraints { (make) in
                    make.edges.equalTo(margins)
                }
            } else {
                let rightImageMargin: CGFloat = config.rightImageMargin ?? 12
                rightView.snp.remakeConstraints { (make) in
                    make.top.greaterThanOrEqualToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().offset(config.isShowBorder ? -10 : 0)
                    make.left.equalTo(input.snp.right).offset(rightImageMargin)
                }
            }
        }
    }

    /// Set UDTextField Status
    /// - Parameter status: UDTextField.Status
    public func setStatus(_ status: UDInputStatus) {
        if !isEnable {
            self.status = .disable
            return
        }

        self.status = status
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return self.input.becomeFirstResponder()
    }

    private func update() {
        self.errorLabel.text = config.errorMessege
        self.containerView.snp.remakeConstraints { (make) in
            make.edges.equalTo(config.contentMargins)
        }
        updateInput()
        updateStatus()

        setNeedsLayout()
    }

    private func layoutInput() {
        let textMargins = config.isShowBorder ? config.textMargins : UIEdgeInsets.zero
        if leftView != nil || rightView != nil {
            self.input.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(textMargins.top)
                make.bottom.equalToSuperview().offset(-textMargins.bottom)
                if leftView != nil {
                    make.left.greaterThanOrEqualToSuperview()
                } else {
                    make.left.equalToSuperview().offset(textMargins.left)
                }
                if rightView != nil {
                    make.right.lessThanOrEqualToSuperview()
                } else {
                    make.right.equalToSuperview().offset(-textMargins.right)
                }
            }

            if leftView != nil {
                let leftImageMargin: CGFloat = config.leftImageMargin ?? -12
                leftView?.snp.remakeConstraints { (make) in
                    make.top.greaterThanOrEqualToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                    make.centerY.equalToSuperview()
                    make.left.equalToSuperview().offset(config.isShowBorder ? 12 : 0)
                    make.right.equalTo(input.snp.left).offset(leftImageMargin)
                }
            }

            if rightView != nil {
                let rightImageMargin: CGFloat = config.rightImageMargin ?? 12
                rightView?.snp.remakeConstraints { (make) in
                    make.top.greaterThanOrEqualToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().offset(config.isShowBorder ? -10 : 0)
                    make.left.equalTo(input.snp.right).offset(rightImageMargin)
                }
            }
        } else {
            self.input.snp.remakeConstraints { (make) in
                make.edges.equalTo(textMargins)
            }
        }
    }

    private func layoutViewsByConfig(_ config: UDTextFieldUIConfig, oldValue: UDTextFieldUIConfig) {
        if oldValue.isShowTitle != config.isShowTitle {
            self.titleLabel.isHidden = !config.isShowTitle
            if config.isShowTitle {
                self.titleLabel.snp.remakeConstraints { (make) in
                    make.top.equalToSuperview()
                    make.left.equalToSuperview()
                    make.right.lessThanOrEqualToSuperview()
                    make.bottom.equalTo(inputWrapperView.snp.top).offset(-8)
                }
            } else {
                self.titleLabel.snp.removeConstraints()
            }
        }

        if oldValue.isShowBorder != config.isShowBorder || oldValue.textMargins != config.textMargins {
            self.layoutInput()
        }
    }

    private func layoutViewsByStatus(_ status: UDInputStatus, oldValue: UDInputStatus) {
        if oldValue != self.status {
            if self.status != .error {
                self.errorLabel.snp.removeConstraints()
                self.inputWrapperView.snp.remakeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.top.greaterThanOrEqualToSuperview()
                    make.left.right.equalToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                }
            } else {
                self.errorLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(inputWrapperView.snp.bottom).offset(8)
                    make.left.equalToSuperview()
                    make.right.lessThanOrEqualToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                }
                self.inputWrapperView.snp.remakeConstraints { (make) in
                    make.top.greaterThanOrEqualToSuperview()
                    make.left.right.equalToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                }
            }
            self.errorLabel.isHidden = self.status != .error
        }
    }

    private func updateStatus() {
        var borderColor: UIColor?
        var backgroundColor = config.backgroundColor

        switch self.status {
        case .normal:
            borderColor = config.borderColor
        case .activated:
            borderColor = config.borderActivatedColor ?? UDInputColorTheme.inputActivatedBorderColor
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

    private func updateInput() {
        self.input.minimumFontSize = config.minimumFontSize
        self.input.textAlignment = config.textAlignment
        self.input.font = config.font
        self.input.textColor = config.textColor
        self.input.clearButtonMode = config.clearButtonMode
        let attributes = [NSAttributedString.Key.foregroundColor: config.placeholderColor]
        self.input.attributedPlaceholder = NSAttributedString(string: self.input.attributedPlaceholder?.string ?? "",
                                                              attributes: attributes)
    }

    @objc
    private func textFieldContentDidChange() {
        /// 编辑文本改变时，恢复至 active 状态，否则保持 active / error / normal
        self.setStatus(.activated)
        if let text = input.text,
           let maximumTextLength = config.maximumTextLength,
           text.getLength(countingRule: config.countingRule) >= maximumTextLength {
            self.text = text.getPrefix(maximumTextLength, countintRule: config.countingRule)
        }
    }
}

extension UDTextField: UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let function = self.delegate?.textFieldShouldBeginEditing?(textField) {
            return function
        } else {
            return true
        }
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.status == .error {
            self.setStatus(.error)
        } else {
            self.setStatus(.activated)
        }
        self.delegate?.textFieldDidBeginEditing?(textField)
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let function = self.delegate?.textFieldShouldEndEditing?(textField) {
            return function
        } else {
            return true
        }
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        if self.status == .error {
            self.setStatus(.error)
        } else {
            self.setStatus(.normal)
        }
        self.delegate?.textFieldDidEndEditing?(textField)
    }

    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if self.status == .error {
            self.setStatus(.error)
        } else {
            self.setStatus(.normal)
        }
        self.delegate?.textFieldDidEndEditing?(textField, reason: reason)
    }

    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        if let function = self.delegate?.textField?(textField,
                                                    shouldChangeCharactersIn: range,
                                                    replacementString: string) {
            return function
        } else {
            return true
        }
    }

    @available(iOS 13.0, *)
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        self.delegate?.textFieldDidChangeSelection?(textField)
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if let function = self.delegate?.textFieldShouldClear?(textField) {
            return function
        } else {
            return true
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let function = self.delegate?.textFieldShouldReturn?(textField) {
            return function
        } else {
            return true
        }
    }
}

extension String {

    /// ASCII 字符计数 0.5，其他字符按照 unicodeScalars 数量计算
    static var udCountingRule: (Character) -> Float = { char in
        char.isASCII ? 0.5 : Float(char.unicodeScalars.count)
    }

    func getLength(countingRule: (Character) -> Float = { _ in 1 }) -> Int {
        let result: Float = self.reduce(0) { length, char in
            return length + countingRule(char)
        }
        return Int(ceil(result))
    }

    func getPrefix(_ count: Int, countintRule: (Character) -> Float = { _ in 1 }) -> String {
        let maxLength = Float(count)
        var chars: [Character] = []
        var currentLenth: Float = 0
        for char in self {
            currentLenth += countintRule(char)
            if currentLenth > maxLength { break }
            chars.append(char)
        }
        return String(chars)
    }
}
