//
//  MailSignatureEditViewController.swift
//  MailSDK
//
//  Created by majx on 2020/1/9.
//

import Foundation
import LarkUIKit
import EENavigator
import RxSwift
import LarkAlertController

protocol MailSignatureEditViewControllerDelegate: AnyObject {
    func updateSigText(text: String)
}

class MailSignatureEditViewController: MailBaseViewController, UITextViewDelegate {
    let keyBoard: Keyboard = Keyboard()
    private weak var viewModel: MailSettingViewModel?
    private var accountId: String
    private let disposeBag = DisposeBag()
    private var prevSignatureText = ""
    private var saveBtn: UIButton?
    private let maxTextCount = 2000
    private let accountContext: MailAccountContext
    weak var delegate: MailSignatureEditViewControllerDelegate?

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        self.accountId = accountContext.accountID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenKeyBoard()
        textView.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListenKeyBoard()
    }

    func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        self.title = BundleI18n.MailSDK.Mail_Signature_EditSignature
        view.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(0)
            make.bottom.equalTo(0)
        }

        /// save
        let saveBtn = UIButton(type: .custom)
        saveBtn.setTitle(BundleI18n.MailSDK.Mail_Signature_DraftConfirmAction, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.iconDisable, for: .disabled)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveBtn.addTarget(self, action: #selector(onClickSave), for: .touchUpInside)
        saveBtn.isEnabled = false
        saveBtn.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSignatureSaveDisableKey
        self.saveBtn = saveBtn
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveBtn)
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    func reloadData() {
        if let signature = viewModel?.getAccountSetting(of: accountId)?.setting.signature {
            prevSignatureText = signature.text
            textView.text = signature.text
        }
    }

    func dismissSelf() {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: { [weak self] in
            self?.closeCallback?()
        })
    }

    func shouldDismissSelf() -> Bool {
        if saveEnable() {
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_Signature_DraftConfirmTitle)
            alert.setContent(text: BundleI18n.MailSDK.Mail_Signature_DraftConfirmtxt, alignment: .center)
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_DiscardDraftBtn, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                self.dismissSelf()
            })
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Signature_DraftConfirmAction, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                self.onClickSave()
            })

            navigator?.present(alert, from: self)
            return false
        } else {
            return true
        }
    }

    override func closeBtnTapped() {
        if shouldDismissSelf() {
            dismissSelf()
        }
    }

    @objc
    func onClickSave() {
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Toast_Saving, on: view, disableUserInteraction: false)
        viewModel?.getAccountSetting(of: accountId)?
                  .updateSettings(.signature(.text(textView.text ?? ""))) { [weak self] in
            guard let `self` = self else { return }
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_SaveSuccess, on: self.view)
                    self.delegate?.updateSigText(text: self.textView.text ?? "")
            self.dismissSelf()
                  }
    }

    func saveEnable() -> Bool {
        return textView.text != prevSignatureText
    }

    lazy var textView: MailPlaceholderTextView = {
        let textView = MailPlaceholderTextView()
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.placeholderColor = UIColor.ud.textPlaceholder
        textView.placeholder = BundleI18n.MailSDK.Mail_Signature_Type
        textView.delegate = self
        textView.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSignatureTextViewKey
        textView.textContainerInset = UIEdgeInsets(top: 32, left: 26, bottom: 26, right: 26)
        textView.backgroundColor = UIColor.ud.bgBody
        return textView
    }()

    // MARK: - keyboard event - UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        /// max characters limit
        let maxLength = maxTextCount
        let tempString = (textView.text as NSString).replacingCharacters(in: range, with: text)
        if tempString.count <= maxLength {
            return true
        }
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        saveBtn?.isEnabled = saveEnable()
        if let btn = saveBtn {
            if btn.isEnabled {
                btn.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSignatureSaveKey
            } else {
                btn.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSignatureSaveDisableKey
            }
        }
        navigationItem.rightBarButtonItem?.isEnabled = saveEnable()
    }
}

// MARK: - keyboard event
extension MailSignatureEditViewController {
    func listenKeyBoard() {
        let events: [Keyboard.KeyboardEvent] = [.willShow, .didShow, .willHide, .didHide, .willChangeFrame, .didChangeFrame]
        self.keyBoard.on(events: events) { [weak self] (opt) in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.handleKeyBoardOptions(opt)
            }
        }
        self.keyBoard.start()
    }

    func stopListenKeyBoard() {
        self.keyBoard.stop()
    }

    func handleKeyBoardOptions(_ options: Keyboard.KeyboardOptions) {
        guard options.event == .willShow || options.event == .willHide || options.event == .willChangeFrame  else {
            return
        }
        let keyBoardHeight = options.endFrame.height
        if !Display.pad {
            textView.snp.updateConstraints { (make) in
                make.bottom.equalTo(-keyBoardHeight)
            }
        }
        self.view.layoutIfNeeded()
    }
}
