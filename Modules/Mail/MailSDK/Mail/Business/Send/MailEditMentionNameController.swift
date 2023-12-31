//
//  MailCreateTagController.swift
//  MailSDK
//
//  Created by majx on 2019/10/28.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import LarkAlertController
import UniverseDesignFont
import UniverseDesignInput
import UniverseDesignIcon

protocol MentionModifyNameVCDelegate: AnyObject {
    func modifyName(key: String, name: String)
    func cancelModify(key: String)
}

class MailEditMentionNameController: MailBaseViewController, UDTextFieldDelegate {
    let saveBtn = UIButton(type: .custom)
    let originName: String
    var changedName = ""
    let key: String
    private var canceled = false
    private let accountContext: MailAccountContext
    private(set) weak var delegate: MentionModifyNameVCDelegate?
    
    init(accountContext: MailAccountContext, mentionDelegate: MentionModifyNameVCDelegate, key: String, name: String) {
        self.accountContext = accountContext
        self.delegate = mentionDelegate
        self.key = key
        self.originName = name
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        // 点击修改名称上报
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["target": "none",
                        "click": "edit_at",
                        "mail_account_type": NewCoreEvent.accountType()]
        event.post()
        let event1 = NewCoreEvent(event: .email_at_edit_menu_view)
        event1.params = ["target": "none",
                        "click": "edit_at",
                        "mail_account_type": NewCoreEvent.accountType()]
        event1.post()
        if !self.originName.isEmpty {
            self.labelTextField.text = self.originName
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.labelTextField.becomeFirstResponder()
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal, execute: { [weak self] in
            guard let `self` = self else { return }
            if !self.canceled {
                self.labelTextField.becomeFirstResponder()
            }
        })
    }

    func setupViews() {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.MailSDK.Mail_ComposeMessageMentionsEditTextToDisplay_Text
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(16)
            make.height.equalTo(24)
        }
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(labelTextField)
        saveBtn.addTarget(self, action: #selector(saveLabel), for: .touchUpInside)
        var buttonStr = BundleI18n.MailSDK.Mail_ComposeMessageMentionsEditConfirm_Button
        saveBtn.setTitle(buttonStr, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        saveBtn.setTitleColor(UIColor.ud.primaryFillSolid03, for: .disabled)
        self.view.addSubview(saveBtn)
        saveBtn.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalToSuperview().offset(-16)
        }
        saveBtn.isEnabled = false

        let cancelBtn = UIButton(type: .custom)
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelBtn.setTitle(BundleI18n.MailSDK.Mail_ComposeMessageMentionsEditCancel_Button, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelBtn.setTitleColor(UIColor.ud.textTitle, for: .normal)
        cancelBtn.setTitleColor(UIColor.ud.textTitle.withAlphaComponent(0.7), for: .highlighted)
        self.view.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.leading.equalToSuperview().offset(16)
        }
    
        labelTextField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
        labelTextField.backgroundColor = UIColor.ud.bgBody
    }

    // MARK: - Views
    lazy var labelTextField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         clearButtonMode: .whileEditing,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))

        config.contentMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.primaryContentDefault
        textField.placeholder = BundleI18n.MailSDK.Mail_ComposeMessageMentionsEditTextToDisplay_Placeholder
        textField.input.addTarget(self, action: #selector(handleEdtingChange(sender:)), for: .editingChanged)
        textField.layer.cornerRadius = 6
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        textField.layer.masksToBounds = true
        textField.delegate = self
        return textField
     }()

    @objc
    func cancel() {
        self.canceled = true
        self.delegate?.cancelModify(key: self.key)
        dismiss(animated: true, completion: nil)
    }

    @objc
    func saveLabel() {
        dismiss(animated: true, completion: nil)
        if !self.changedName.isEmpty {
            // 点击保存名称上报
            let event = NewCoreEvent(event: .email_email_edit_click)
            event.params = ["target": "none",
                            "click": "edit_at_confirm",
                            "mail_account_type": NewCoreEvent.accountType()]
            event.post()
            let event1 = NewCoreEvent(event: .email_at_edit_menu_view)
            event1.params = ["target": "none",
                            "click": "edit_at_confirm",
                            "mail_account_type": NewCoreEvent.accountType()]
            event1.post()
            self.delegate?.modifyName(key: self.key, name: self.changedName)
        }
    }
    
    @objc
    func handleEdtingChange(sender: UITextField) {
        let content = sender.text ?? ""
        saveBtn.isEnabled = ((content != originName) && !content.isEmpty)
        self.changedName = content
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let existLen = textField.text?.utf16.count ?? 0
        if existLen > 64 {
            return true
        }
        let selectLen = range.length
        let replaceLen = string.utf16.count
        if existLen - selectLen + replaceLen > 64 {
            return false
        }
        return true
    }
    
}
