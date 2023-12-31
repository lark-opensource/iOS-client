//
//  V3ListShareBottomView.swift
//  Todo
//
//  Created by GCW on 2022/12/27.
//

import Foundation
import UniverseDesignCheckBox
import UniverseDesignButton
import EditTextView
import UniverseDesignFont

protocol V3ListShareBottomDelegate: AnyObject {
    func tapInviteBtn(isSendNote: Bool, note: String?)
}

class V3ListShareBottomView: UIView {
    weak var delegate: V3ListShareBottomDelegate?
    private var isSelected: Bool = true

    private lazy var textField: LarkEditTextView = {
        let textField = LarkEditTextView()
        textField.backgroundColor = UIColor.ud.bgBody
        textField.font = UDFont.systemFont(ofSize: 16)
        textField.defaultTypingAttributes = [
            .font: UDFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle
        ]
        textField.placeholder = I18N.Todo_ShareList_SendNotification_Placeholder()
        textField.placeholderTextColor = UIColor.ud.textPlaceholder
        textField.maxHeight = 77
        textField.isScrollEnabled = false
        return textField
    }()

    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig()) { [weak self] _ in
            guard let self = self, let delegate = self.delegate else { return }
            self.alterCheckBox()
        }
        checkBox.isSelected = true
        return checkBox
    }()

    private lazy var notifyLabel: UILabel = {
        let notifyLabel = UILabel()
        notifyLabel.font = UDFont.systemFont(ofSize: 14)
        notifyLabel.textColor = UIColor.ud.textTitle
        notifyLabel.text = I18N.Todo_ShareList_SendNotification_Checkbox
        notifyLabel.numberOfLines = 1
        notifyLabel.lineBreakMode = .byWordWrapping
        return notifyLabel
    }()

    private lazy var crossLine: UIView = {
        let crossLine = UIView()
        crossLine.backgroundColor = UIColor.ud.lineBorderCard
        return crossLine
    }()

    private lazy var inviteBtn: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .small
        let inviteBtn = UDButton(config)
        inviteBtn.titleLabel?.font = UDFont.systemFont(ofSize: 14)
        inviteBtn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        inviteBtn.setTitle(I18N.Todo_TaskList_Invite_Button, for: .normal)
        inviteBtn.layer.cornerRadius = 4
        inviteBtn.addTarget(self, action: #selector(tapInviteBtn), for: .touchUpInside)
        return inviteBtn
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(textField)
        addSubview(checkBox)
        addSubview(notifyLabel)
        addSubview(crossLine)
        addSubview(inviteBtn)
    }

    private func setupLayout() {
        crossLine.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        textField.snp.makeConstraints { (make) in
            make.top.equalTo(crossLine.snp.bottom).offset(15)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(textField.snp.bottom).offset(19)
            make.width.height.equalTo(18)
        }
        notifyLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(8)
            make.top.equalTo(textField.snp.bottom).offset(18)
            make.bottom.equalToSuperview().offset(-12)
        }
        inviteBtn.snp.makeConstraints { (make) in
            make.top.equalTo(textField.snp.bottom).offset(18)
            make.bottom.equalToSuperview().offset(-8)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(28)
        }
    }

    private func alterCheckBox() {
        isSelected = !isSelected
        checkBox.isSelected = isSelected
        textField.isHidden = !isSelected
        closeKeyBoard()
        checkBox.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            if isSelected {
                make.top.equalTo(textField.snp.bottom).offset(19)
            } else {
                make.bottom.equalToSuperview().offset(-13)
            }
            make.width.height.equalTo(isSelected ? 18 : 20)
        }
        notifyLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(8)
            if isSelected {
                make.top.equalTo(textField.snp.bottom).offset(18)
            }
            make.bottom.equalToSuperview().offset(-12)
        }
        inviteBtn.snp.remakeConstraints { (make) in
            if isSelected {
                make.top.equalTo(textField.snp.bottom).offset(18)
            } else {
                make.top.equalToSuperview().offset(18)
            }
            make.bottom.equalToSuperview().offset(-8)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(28)
        }
        notifyLabel.font = UDFont.systemFont(ofSize: isSelected ? 14 : 16)
    }

    @objc
    private func tapInviteBtn() {
        guard let delegate = delegate else { return }
        delegate.tapInviteBtn(isSendNote: self.isSelected, note: textField.text)
    }

    func closeKeyBoard() {
        textField.resignFirstResponder()
    }
}
