//
//  MailSenderAliasController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/12/3.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RustPB
import UniverseDesignInput

protocol MailSenderAliasDelegate: AnyObject {
    func didUpdateAliasAndDismiss(address: MailAddress)
    func shouldShowAliasLimit() -> Bool
}

/// 修改发信名称VC
class MailSenderAliasController: MailBaseViewController, UDTextFieldDelegate {
    private var viewModel: MailSettingViewModel?
    private let disposeBag = DisposeBag()
    private var titleText: String
    var accountId: String
    var accountSetting: MailAccountSetting?
    var currentAddress: MailAddress
    weak var delegate: MailSenderAliasDelegate?

    // MARK: - Views
    lazy var aliasTextField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         clearButtonMode: .whileEditing,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))

        config.contentMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 12)
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        textField.input.clearButtonMode = .whileEditing
        textField.input.addTarget(self, action: #selector(handleEdtingChange(sender:)), for: .editingChanged)
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.delegate = self
        textField.placeholder = BundleI18n.MailSDK.Mail_ManageSenders_SenderName_Enter_Placeholder
        return textField
     }()

    lazy var aliasLimitWarningLabel: UILabel = {
        let warningLabel = UILabel()
        warningLabel.text = ""
        warningLabel.font = UIFont.systemFont(ofSize: 14)
        warningLabel.textColor = UIColor.ud.functionDangerContentDefault
        warningLabel.numberOfLines = 0
        return warningLabel
    }()

    let saveButton = UIButton(type: .custom)
    private let accountContext: MailAccountContext

    init(viewModel: MailSettingViewModel?,
         accountId: String,
         accountContext: MailAccountContext,
         titleText: String,
         currentAddress: MailAddress?) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        self.accountId = accountId
        self.titleText = titleText
        if let currentAddress = currentAddress {
            self.currentAddress = currentAddress
        } else {
            self.currentAddress = MailAddress(name: "", address: "", larkID: "", tenantId: "", displayName: "", type: nil)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.bgColor(vc: self)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase, tintColor: UIColor.ud.textTitle)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordMailState = false
        setupViewModel()
        setupViews()
        setupAddress()
        let senderAliasValid = self.aliasTextField.input.rx.text.map{
            [weak self] in (self?.checkIsTextValid(text: $0 ?? "") ?? false)
        }.share(replay: 1)
        senderAliasValid.bind(to: saveButton.rx.isEnabled).disposed(by: disposeBag)
        aliasTextField.becomeFirstResponder()
    }

    private func setupViewModel() {
        viewModel?.getEmailPrimaryAccount()
        viewModel?.viewController = self
    }

    private func setupAddress() {
        accountSetting = viewModel?.getAccountSetting(of: accountId)
        if currentAddress.address.isEmpty, let accountSetting = self.accountSetting {
            currentAddress = MailAddress(with: accountSetting.setting.emailAlias.defaultAddress)
        }
        aliasTextField.input.text = currentAddress.name
    }



    @objc
    func handleEdtingChange(sender: UITextField) {
        let text = sender.text ?? ""
        _ = self.checkIsTextValid(text: text)
    }

    private func checkIsTextValid(text: String) -> Bool {
        guard self.delegate?.shouldShowAliasLimit() ?? false else {
            return !text.isEmpty
        }
        let limitLength = 200
        let processedText = text.replacingOccurrences(of: " ", with: "")
        if processedText.isEmpty {
            aliasLimitWarningLabel.text = BundleI18n.MailSDK.Mail_ManageSenders_NameEmpty_Error
            return false
        }
        if text.count > limitLength {
            aliasLimitWarningLabel.text = BundleI18n.MailSDK.Mail_ManageSenders_NameTooLong_Error(limitLength)
            return false
        }
        aliasLimitWarningLabel.text = ""
        return true
    }

    func setupViews() {
        view.backgroundColor = ModelViewHelper.bgColor(vc: self)

        saveButton.isEnabled = false
        saveButton.addTarget(self, action: #selector(saveAlias), for: .touchUpInside)
        saveButton.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_SaveMobile, for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        saveButton.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        saveButton.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)

        let cancelBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Common_Cancel)
        cancelBtn.button.tintColor = UIColor.ud.textTitle
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        navigationItem.leftBarButtonItem = cancelBtn

        title = self.titleText

        aliasTextField.backgroundColor = ModelViewHelper.listColor(vc: self)
        view.addSubview(aliasTextField)
        aliasTextField.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.top.equalTo(16)
            make.height.equalTo(48)
        }
        if delegate?.shouldShowAliasLimit() ?? false {
            view.addSubview(aliasLimitWarningLabel)
            aliasLimitWarningLabel.snp.makeConstraints { (make) in
                make.left.equalTo(32)
                make.right.equalTo(-28)
                make.top.equalTo(aliasTextField.snp.bottom).offset(4)
            }
        }
    }

    @objc
    func saveAlias() {
        currentAddress.name = aliasTextField.input.text ?? ""
        accountSetting?.loadingToast = MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view)
        accountSetting?.updateSettings(.senderAlias(currentAddress.toPBModel())) { [weak self] in
            guard let `self` = self else { return }
            asyncRunInMainThread { [weak self] in
                guard let `self` = self else { return }
                MailRoundedHUD.remove(on: self.view)
                self.accountSetting?.loadingToast = nil
                self.dismiss(animated: true, completion: { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.didUpdateAliasAndDismiss(address: self.currentAddress)
                })
            }
        }
    }

    @objc
    func cancel() {
        dismiss(animated: true, completion: nil)
    }
}
