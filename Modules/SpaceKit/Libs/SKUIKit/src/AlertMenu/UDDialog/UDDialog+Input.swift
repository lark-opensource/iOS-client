//
//  UDDialog+Input.swift
//  SKUIKit
//
//  Created by guoqp on 2021/7/6.
//

import UniverseDesignDialog
import SKResource
import SnapKit
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignIcon
import CoreGraphics

public protocol UDDialogInputDelegate: AnyObject {
    func checkInputContent(dialog: UDDialog, input: String) -> Bool
    func inputFieldHasEdit(dialog: UDDialog)
}

// MARK: - inputTextView
extension UDDialog {
    public var textField: UDTextField {
        return self.inputTextView.textField
    }

    private static var _kInputTextViewKey: UInt8 = 0
    fileprivate var inputTextView: InputTextView {
        get {
            guard let view = objc_getAssociatedObject(self, &UDDialog._kInputTextViewKey) as? InputTextView else {
                let view = InputTextView()
                self.inputTextView = view
                return view
            }
            return view
        }
        set { objc_setAssociatedObject(self, &UDDialog._kInputTextViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private static var inputKey: UInt8 = 0
    public var inputDelegate: UDDialogInputDelegate? {
        get {
            let value = objc_getAssociatedObject(self, &Self.inputKey) as? UDDialogInputDelegate
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.inputKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private static var hasEditKey: UInt8 = 0
    public var hasEdit: Bool {
        get {
            let value = objc_getAssociatedObject(self, &Self.hasEditKey) as? Bool ?? false
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.hasEditKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

extension UDDialog {

    public func setTitle(
        text: String,
        style: TextStyle = UDDialog.TextStyle.title(),
        inputView: Bool) {
        setTitle(text: text)
        if inputView {
            _setInputTextView()
        }
    }
    /**
     * Only one UITextField supported
     */
    @discardableResult
    public func addTextField(placeholder: String, text: String? = nil, asFirstResponder: Bool = true) -> UDTextField {
        inputTextView.setPlaceholder(placeholder)
        if let txt = text {
            inputTextView.setText(txt)
        }
        _setInputTextView()
        if asFirstResponder {
//            registerFirstResponder(for: textField)
        }
        return textField
    }

    public func bindInputEventWithConfirmButton(_ button: UIButton) {
        inputTextView.confirmButton = button
        let empty = textField.text?.isEmpty ?? false
        inputTextView._renderConfirmButton(canUse: !empty,
                                           button: button)
        _ = textField.input.rx.controlEvent(.editingChanged)
            .asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.inputTextView.removeErrorTips()
                let empty = self.textField.text?.isEmpty ?? false
                self.inputTextView._renderConfirmButton(
                    canUse: !empty,
                    button: self.inputTextView.confirmButton
                )
            })
    }

    // 额外传入一个当前文本内容，如果用户没有修改，则disable确认按钮
    public func bindInputEventWithConfirmButton(_ button: UIButton, initialText: String) {
        inputTextView.confirmButton = button
        let empty = textField.text?.isEmpty ?? false
        if empty {
            inputTextView._renderConfirmButton(canUse: false,
                                               button: button)
        }
        if textField.text == initialText {
            // 如果输入框内容与初始文本相同，禁止点击创建按钮
            inputTextView._renderConfirmButton(canUse: false,
                                               button: button)
        }
        _ = textField.input.rx.controlEvent(.editingChanged)
            .asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.inputTextView.removeErrorTips()
                self.textField.setStatus(.activated)
                var canUse = true
                if self.textField.text?.isEmpty ?? false {
                    canUse = false
                } else if self.textField.text == initialText, !self.hasEdit {
                    canUse = false
                } else if self.textField.text != nil {
                    canUse = self.inputDelegate?.checkInputContent(dialog: self, input: self.textField.text!) ?? true
                }
                self.inputTextView._renderConfirmButton(
                    canUse: canUse,
                    button: self.inputTextView.confirmButton
                )
                if self.hasEdit == false {
                    self.inputDelegate?.inputFieldHasEdit(dialog: self)
                }
                self.hasEdit = true
            })
    }

    private func _setInputTextView() {
        customMode = .input
        self.config.contentMargin = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        setContent(view: inputTextView)
    }
    
    public func showErrorTips(_ msg: String) {
        //UDTextFiled组件不支持多行展示，先业务自已来实现支持多行提示, 后面可用textField.config.errorMessege = msg, textField.setStatus(.error)替换
        inputTextView.showErrorTips(msg)
    }
}

private class InputTextView: UIView {
    let textField: SKUDBaseTextField = {
        let text = SKUDBaseTextField()
        var config = UDTextFieldUIConfig()
        config.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        config.textColor = UIColor.ud.N900
        config.isShowBorder = true
        config.backgroundColor = .clear
        config.clearButtonMode = .whileEditing
        text.config = config
        return text
    }()
    
    let errorTipLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0, weight: .regular)
        label.textColor = UDInputColorTheme.inputErrorHelperValidationTextColor
        label.backgroundColor = .clear
        label.numberOfLines = 1
        return label
    }()
    
    private let leftOffset = 20
    fileprivate weak var confirmButton: UIButton?

    fileprivate func _renderConfirmButton(canUse: Bool, button: UIButton?) {
        button?.isUserInteractionEnabled = canUse
        button?.setTitleColor(canUse ?  UIColor.ud.primaryContentDefault : UIColor.ud.textDisabled, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.leading.equalTo(leftOffset)
            make.trailing.equalTo(-leftOffset)
            make.height.equalTo(56)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-8)
        }
        self.snp.makeConstraints { (make) in
            make.width.equalTo(303)
        }
    }

    func setPlaceholder(_ text: String) {
        textField.placeholder = text
    }

    func setText(_ text: String) {
        textField.text = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showErrorTips(_ msg: String) {
        addSubview(errorTipLabel)
        errorTipLabel.text = msg
        errorTipLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(leftOffset)
            make.trailing.equalTo(-leftOffset)
            make.height.equalTo(20)
            make.top.equalTo(58)
        }
        textField.config.borderColor = UDInputColorTheme.inputErrorHelperValidationTextColor
        textField.setStatus(.activated)
    }
    
    func removeErrorTips() {
        errorTipLabel.removeFromSuperview()
        textField.config.borderColor = UDInputColorTheme.inputNormalBorderColor
        textField.setStatus(.activated)
    }
}
