//
//  MailClientSignEditViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/12/15.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignInput
import RxSwift
import RxRelay
import EENavigator
import LarkAlertController

extension String {
    var html2AttributedString: NSAttributedString? {
        do {
            guard let data = data(using: String.Encoding.utf8) else {
                MailLogger.info("parse html rich text to AttributedString Fail length: \(self.count), encode utf8 failed")
                return nil
            }
            return try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        } catch {
            MailLogger.info("parse html rich text to AttributedString Fail length: \(self.count), error: \(error)")
            return nil
        }
    }

    var htmlEscapeString: String {
        var htmlString = ""
        for c in self {
            switch c {
            case " ":
                htmlString += "&nbsp;"
            case "<":
                htmlString += "&lt;"
            case ">":
                htmlString += "&gt;"
            case "&":
                htmlString += "&amp;"
            case "\"":
                htmlString += "&quot;"
            case "\n":
                htmlString += "<br>"
            case "\t":
                htmlString += "&nbsp;&nbsp;&nbsp;&nbsp;"
            default:
                htmlString.append(c)
            }
        }
        return htmlString
    }
}

protocol MailClientSignEditViewControllerDelegate: AnyObject {
    func needShowToastAndRefreshSignList(_ toast: String, inNewScene: Bool, sign: MailSignature)
}

class MailClientSignEditViewController: MailBaseViewController, UDTextFieldDelegate, UDMultilineTextFieldDelegate {
    enum Scene {
        case newSign
        case editSign
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    var scene: Scene = .newSign
    lazy var sign = MailSignature()
    var signNewID: String?
    var signModel: MailSettingSigWebModel?
    var existSignNames = [String]()
    weak var delegate: MailClientSignEditViewControllerDelegate?

    private lazy var signNameTextField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         clearButtonMode: .whileEditing,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
        config.contentMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 12)
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        textField.placeholder = BundleI18n.MailSDK.Mail_ThirdClient_EnterSignatureName
        textField.input.addTarget(self, action: #selector(handleEdtingChange(sender:)), for: .editingChanged)
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.backgroundColor = UIColor.ud.bgBody
        textField.delegate = self
        return textField
     }()
    private lazy var tipsLabel = self.makeTipsLabel()

    private lazy var signContentTextField: UDMultilineTextField = {
        var config = UDMultilineTextFieldUIConfig(isShowBorder: false,
                                                  textColor: UIColor.ud.textTitle,
                                                  placeholderColor: UIColor.ud.textPlaceholder.withAlphaComponent(0.5),
                                                  font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
        config.textMargins = UIEdgeInsets(top: 1, left: 12, bottom: 13, right: 16)
        config.placeholderColor = UIColor.ud.textPlaceholder
        let textField = UDMultilineTextField()
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        var attribute = [NSAttributedString.Key: Any]()
        attribute[NSAttributedString.Key.foregroundColor] = UIColor.ud.textPlaceholder
        attribute[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        let placeholderString = NSAttributedString(string: BundleI18n.MailSDK.Mail_ThirdClient_EnterSignatureContent, attributes: attribute)
        textField.placeholder = BundleI18n.MailSDK.Mail_ThirdClient_EnterSignatureContent
        textField.backgroundColor = UIColor.ud.bgBody
        textField.delegate = self
        textField.config = config
        return textField
     }()
    private var saveBtn = UIButton(type: .custom)
    private let disposeBag = DisposeBag()
    private var accountID: String
    private var existName = ""
    private var didEdit: Bool = false
    private var didAppear: Bool = false

    private let accountContext: MailAccountContext

    init(accountID: String, accountContext: MailAccountContext) {
        self.accountID = accountID
        self.accountContext = accountContext
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
        loadData()
        addObserver()
        updateNavAppearanceIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAppear {
            signNameTextField.input.becomeFirstResponder()
        }
    }

    func loadData() {
        if scene == .editSign, let sigID = signModel?.sigId {
            sign.id = sigID
            sign.signatureType = .user
            sign.signatureDevice = .mobile
            sign.templateHtml = signModel?.html ?? ""
            sign.name = signModel?.title ?? ""

            signNameTextField.input.text = sign.name
            signContentTextField.input.text = sign.templateHtml.html2AttributedString?.string
            existName = sign.name
        }
    }

    override func backItemTapped() {
        guard saveBtn.isEnabled else {
            super.backItemTapped()
            return
        }
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_SaveSignatures)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_SaveChangesBeforeExiting, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Discard, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.navigator?.pop(from: self)
        })
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Save, dismissCompletion: { [weak self] in
            self?.saveSign()
        })
        navigator?.present(alert, from: self)
    }

    func isLegal(_ signName: String?) -> Bool {
        guard let signName = signName else { return false }
        if scene == .newSign && !signName.isEmpty {
            return !existSignNames.contains(signName)
        }
        if scene == .editSign {
            existSignNames.lf_remove(object: existName)
        }
        return !existSignNames.contains(signName)
    }

    func notEmpty() -> Bool {
        return !(self.signNameTextField.input.text?.isEmpty ?? true) &&
        !(self.signContentTextField.input.text?.isEmpty ?? true)
    }

    func addObserver() {
        let signNameValid = self.signNameTextField.input.rx.text.map{ [weak self] in ( self?.isLegal($0) ?? false ) }.share(replay: 1)
        let contentValid = self.signContentTextField.input.rx.text.map{ ( !($0?.isEmpty ?? true) ) }.share(replay: 1)
        let saveValid = Observable.combineLatest(signNameValid, contentValid) { [weak self] (signNameValid, contentValid) -> Bool in
            guard let `self` = self else { return false }
            if self.scene == .newSign {
                return signNameValid && contentValid && self.notEmpty()
            } else if self.scene == .editSign {
                return (signNameValid || contentValid)
                && self.notEmpty() && self.didEdit && !self.existSignNames.contains(self.signNameTextField.input.text ?? "")
            } else {
                return false
            }
        }.bind(to: saveBtn.rx.isEnabled).disposed(by: disposeBag)

        signNameValid.subscribe(onNext: { [weak self] (valid) in
            guard let `self` = self else { return }
            if self.isLegal(self.signNameTextField.input.text) {
                self.tipsLabel.snp.updateConstraints { (make) in
                    make.height.equalTo(0)
                }
            } else {
                self.tipsLabel.snp.updateConstraints { (make) in
                    make.height.equalTo(20)
                }
            }
        }, onError: { error in
            //
        }).disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
    }


    @objc
    func didReceivedKeyboardDidShowNotification(_ notify: Notification) {
        didAppear = true
    }

    func setupViews() {
        if scene == .newSign {
            title = BundleI18n.MailSDK.Mail_ThirdClient_AddSignature
        } else if scene == .editSign {
            title = BundleI18n.MailSDK.Mail_ThirdClient_EditSignature
        }

        saveBtn.isEnabled = false
        saveBtn.addTarget(self, action: #selector(saveSign), for: .touchUpInside)
        saveBtn.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_Save, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        saveBtn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveBtn)

        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.text = BundleI18n.MailSDK.Mail_ThirdClient_SignatureName
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-16)
            make.top.equalTo(10)
            make.height.equalTo(22)
        }

        view.addSubview(signNameTextField)
        signNameTextField.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.height.equalTo(48)
        }
        view.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(signNameTextField.snp.bottom).offset(4)
            make.height.equalTo(0)
        }

        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = UIColor.ud.textTitle
        contentLabel.text = BundleI18n.MailSDK.Mail_ThirdClient_SignatureContent
        view.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-16)
            make.top.equalTo(tipsLabel.snp.bottom).offset(24)
            make.height.equalTo(22)
        }

        let contentBgView = UIView()
        contentBgView.backgroundColor = UIColor.ud.bgBody
        contentBgView.layer.cornerRadius = 10
        contentBgView.layer.masksToBounds = true
        view.addSubview(contentBgView)
        contentBgView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
            make.height.equalTo(254+24)
        }

        view.addSubview(signContentTextField)
        signContentTextField.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(contentLabel.snp.bottom).offset(20)
            make.height.equalTo(254)
        }
    }

    private func makeTipsLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = BundleI18n.MailSDK.Mail_ThirdClient_SignatureNameExisted
        return label
    }

    @objc
    func handleEdtingChange(sender: UITextField) {
        let name = sender.text ?? ""
        sign.name = name
        if didAppear {
            didEdit = true
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        guard textView == self.signContentTextField.input else { return }
        if didAppear {
            didEdit = true
        }
    }

    @objc
    func saveSign() {
        sign.templateHtml = self.signContentTextField.input.text.htmlEscapeString
        if scene == .newSign {
            sign.signatureType = .user
            sign.signatureDevice = .mobile
            let lastID = (Int(signNewID ?? "1") ?? 1) + 1
            sign.id = "\(lastID)"
            MailLogger.info("[mail_client_sign] addSignature lastID: \(lastID)")
            MailDataServiceFactory
                .commonDataService?
                .addSignature(accountID: accountID, signature: sign)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    self.delegate?.needShowToastAndRefreshSignList(BundleI18n.MailSDK.Mail_ThirdClient_ChangesSaved,
                                                                   inNewScene: self.scene == .newSign, sign: self.sign)
                    self.navigator?.pop(from: self)
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_FailedToSave, on: self.view)
                    MailLogger.error("[mail_client_sign] addSignature fail error:\(error)")
                }).disposed(by: disposeBag)
        } else {
            MailDataServiceFactory
                .commonDataService?
                .updateSignature(accountID: accountID, signature: sign)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    self.delegate?.needShowToastAndRefreshSignList(BundleI18n.MailSDK.Mail_ThirdClient_ChangesSaved,
                                                                   inNewScene: self.scene == .newSign, sign: self.sign)
                    self.navigator?.pop(from: self)
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_FailedToSave, on: self.view)
                    MailLogger.error("[mail_client_sign] updateSignature fail error:\(error)")
                }).disposed(by: disposeBag)
        }
    }
}
