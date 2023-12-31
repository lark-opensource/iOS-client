//
//  V3RecoverAccountCarrierViewController.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/21.
//

import Foundation
import RxSwift
import LarkAlertController
import Homeric
import SnapKit
import LarkUIKit
import LarkLocalizations

enum RecoverAccountSourceType: String, Codable {
    case unknown = ""
    case login = "login"
    case forgetVerifyCode = "pwd"
    case modifyCp = "modify"
}

class V3RecoverAccountCarrierViewController: BaseViewController {

    private let vm: V3RecoverAccountCarrierViewModel
    
    let rustDomainProvider = RustDynamicDomainProvider()

    lazy var userNameTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default)
        textfield.delegate = self
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 17)
        textfield.textFiled.returnKeyType = .done
        textfield.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.suiteLogin.Lark_Login_RecoverAccountNamePlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.ud.textPlaceholder
        ])
        return textfield
    }()

    lazy var identifyNumberTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default)
        textfield.delegate = self
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 17)
        textfield.textFiled.returnKeyType = .done
        textfield.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.suiteLogin.Lark_Login_RecoverAccountIDPlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.ud.textPlaceholder
        ])
        return textfield
    }()

    private lazy var policyLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        return lbl
    }()

    private lazy var appealLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var checkbox: V3Checkbox = {
        let cb = V3Checkbox(iconSize: CL.checkBoxSize)
        cb.hitTestEdgeInsets = CL.checkBoxInsets
        cb.rx.controlEvent(UIControl.Event.valueChanged).subscribe { _ in
        }.disposed(by: disposeBag)
        return cb
    }()

    override var bottomViewBottomConstraint: ConstraintItem {
        appealLabel.snp.top
    }

    override var keyboardShowBottomViewOffset: CGFloat {
        safeAreaBottom + appealLabel.bounds.height + CL.itemSpace + 10
    }

    init(vm: V3RecoverAccountCarrierViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        moveBoddyView.addSubview(appealLabel)
        super.viewDidLoad()

        self.setupUI()
        self.setupNextButtonClickHandler()

        logger.info("n_page_old_opthree_start")
    }

    func checkBtnDisable() {
        nextButton.isEnabled = self.vm.isNextButtonEnabled()
    }
    
    private func policyTip() -> NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 14.0)
        let res = I18N.Lark_Login_V3_registerNextStepPolicyTip(I18N.Lark_Passport_IdentityVerifyPolicy, I18N.Lark_Passport_FaceInfoRulesPolicy)
        let attributedString = NSMutableAttributedString.tip(str: res, color: UIColor.ud.textPlaceholder, font: font, aligment: .left)
        let termAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.identityURL
        ]
        let privacyAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.faceIdURL
        ]
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Passport_IdentityVerifyPolicy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(termAttributed, range: rng)
            }
        }
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Passport_FaceInfoRulesPolicy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(privacyAttributed, range: rng)
            }
        }
        return attributedString
    }

    func setupUI() {
        configTopInfo(vm.title, detail: vm.subTitleInAttributedString)

        centerInputView.addSubview(userNameTextField)
        userNameTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(centerInputView)
        }

        centerInputView.addSubview(identifyNumberTextField)
        identifyNumberTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(CL.fieldHeight)
            make.top.equalTo(userNameTextField.snp.bottom).offset(Common.Layout.itemSpace)
            make.bottom.equalToSuperview()
        }

        moveBoddyView.addSubview(checkbox)
        moveBoddyView.addSubview(policyLabel)
        switchButtonContainer.removeFromSuperview()
        policyLabel.attributedText = self.policyTip()
        checkbox.snp.remakeConstraints { (make) in
            make.size.equalTo(CL.checkBoxSize)
            make.left.equalToSuperview().offset(CL.itemSpace)
            make.bottom.equalTo(policyLabel.snp.firstBaseline).offset(CL.checkBoxYOffset)
        }
        policyLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(identifyNumberTextField.snp.bottom).offset(15)
            make.left.equalTo(checkbox.snp.right).offset(CL.checkBoxRightPadding)
            make.right.equalTo(identifyNumberTextField)
        }

        appealLabel.attributedText = .makeLinkString(
            plainString: "\(I18N.Lark_Passport_IdentityVerificationDisabledTip)\(I18N.Lark_Passport_IdentityVerificationDisabled_AppealLink)",
            links: [(I18N.Lark_Passport_IdentityVerificationDisabled_AppealLink, Link.accountAppealURL)],
            font: UIFont.systemFont(ofSize: 14.0),
            linkFont: UIFont.systemFont(ofSize: 14.0)
        )
        appealLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(CL.itemSpace)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(CL.itemSpace)
            make.trailing.lessThanOrEqualToSuperview().inset(CL.itemSpace)
        }

        NotificationCenter.default
        .rx.notification(UITextField.textDidChangeNotification)
        .subscribe(onNext: { [weak self] (_) in
            self?.refreshViewModel()
            self?.checkBtnDisable()
        }).disposed(by: disposeBag)

        nextButton.setTitle(I18N.Lark_Login_V3_NextStep, for: .normal)

        self.checkBtnDisable()
        self.view.layoutIfNeeded()
    }

    override func handleKeyboardWhenShow(_ noti: Notification) {
        func adjust(orignalHeight: CGFloat) {
            self.bottomView.snp.remakeConstraints({ (make) in
                // 只留下 nextButton.height + CL.bottomMargin
                make.top.equalTo(inputAdjustView.snp.bottom)
//                make.top.equalTo(self.policyLabel.snp.bottom).offset(15)
                make.left.right.equalToSuperview()
                make.bottom.greaterThanOrEqualTo(self.policyLabel.snp.bottom).offset(NextButton.Layout.nextButtonHeight48 + 20).priority(.high)
                make.bottom.equalTo(self.bottomViewBottomConstraint).offset(-(orignalHeight - self.keyboardShowBottomViewOffset)).priority(.medium)
            })
            self.view.layoutIfNeeded()
            if self.inputAdjustView.contentSize.height > self.inputAdjustView.frame.height {
                self.inputAdjustView.setContentOffset(
                    CGPoint(x: 0, y: self.inputAdjustView.contentSize.height - self.inputAdjustView.frame.height),
                    animated: true
                )
            }

        }

        if let keyboardSize = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if Display.pad {
                /*
                     iPad modalPresentationStyle = formSheet，横屏下。
                     self.view会往上移动，但是要等动画设置完成才知道移动的目标位置，所以增加了Dispatch，获取移动的目标位置。
                     Dispatch之后，除了系统执行的动画作用域，会缺少位移动画，增加读取键盘动画配置进行动画。
                     */
                let animationDuration = (noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue ?? 0
                let animationOptions = (noti.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
                DispatchQueue.main.async {
                    UIView.animate(
                        withDuration: TimeInterval(animationDuration),
                        delay: 0,
                        options: UIView.AnimationOptions(rawValue: animationOptions),
                        animations: {
                            adjust(orignalHeight: keyboardSize.height)
                        },
                        completion: nil)
                }
            } else {
                adjust(orignalHeight: keyboardSize.height)
            }
        }
    }

    override func handleKeyboardWhenHide(_ noti: Notification) {
        self.bottomView.snp.remakeConstraints({ (make) in
            make.top.equalTo(inputAdjustView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomViewBottomConstraint)
        })
        self.view.layoutIfNeeded()
    }

    func setupNextButtonClickHandler() {
        nextButton.rx.tap.subscribe { [unowned self] (_) in
            self.onNextStepClicked()
        }.disposed(by: disposeBag)
    }

    private func refreshViewModel() {
        self.vm.name = userNameTextField.text
        self.vm.identityNumber = identifyNumberTextField.text
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        userNameTextField.becomeFirstResponder()
    }

    func onNextStepClicked() {

        logger.info("n_action_old_opthree_next")

        self.view.endEditing(true)
        SuiteLoginTracker.track(Homeric.ACCOUNT_VERIFY_NEXT, params: ["from": self.vm.from.rawValue])

        if !checkbox.isSelected {
            self.showPolicyAlert(delegate: self) { (confirm) in
                if confirm {
                    self.checkbox.isSelected = true
                    self.onNextStepClicked()
                }
            }
            return
        }

        logger.info("n_action_old_opthree_next_req")
        self.showLoading()
        self.vm.onNextButtonClicked().subscribe(onNext: { [weak self] in
            self?.stopLoading()
            self?.logger.info("n_action_old_opthree_req_succ")
            SuiteLoginTracker.track(Homeric.ACCOUNT_VERIFY_RESULT, params: [
                "from": self?.vm.from.rawValue ?? "",
                "result": "success"
            ])
        }, onError: { [weak self] (err) in
            self?.logger.error("n_action_old_opthree_req_fail", error: err)
            self?.handle(err)
            SuiteLoginTracker.track(Homeric.ACCOUNT_VERIFY_RESULT, params: [
                "from": self?.vm.from.rawValue ?? "",
                "result": "fail"
            ])
        }).disposed(by: self.disposeBag)
    }

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.termURL, Link.privacyURL, Link.alertTermURL, Link.alertPrivacyURL, Link.identityURL, Link.faceIdURL:
            SuiteLoginTracker.track(Homeric.PRIVACY_POLICY_CLICK, params: ["from": self.vm.from.rawValue])

            var openUrl: Foundation.URL?
            if URL == Link.termURL || URL == Link.alertTermURL {
                let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.serviceTerm)
                if let urlString = urlValue.value {
                    openUrl = Foundation.URL(string: urlString)
                }
            } else if URL == Link.identityURL || URL == Link.faceIdURL {
                let val: String?
                let domainVal = rustDomainProvider.getDomain(.privacy)
                let language = LanguageManager.currentLanguage.languageIdentifier
                let suffix = URL == Link.identityURL ? "/identity" : "/face-id"
                if let domain = domainVal.value {
                    if domain.hasSuffix("/") {
                        val = CommonConst.prefixHTTPS + domain + language + suffix
                    } else {
                        val = CommonConst.prefixHTTPS + domain + "/" + language + suffix
                    }
                    openUrl = Foundation.URL(string: val ?? "")
                }
            } else {
                let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.privacyPolicy)
                if let urlString = urlValue.value {
                    openUrl = Foundation.URL(string: urlString)
                }

            }
            guard let url = openUrl else {
                self.logger.error("invalid url link: \(URL)")
                return
            }
            BaseViewController.clickLink(url, vm: vm, vc: self, errorHandler: self)
        case Link.accountAppealURL:
            guard let urlString = vm.appealUrl else {
                self.logger.errorWithAssertion("handleClickLink no accountAppeal url")
                return
            }
            vm.post(
                event: PassportStep.accountAppeal.rawValue,
                serverInfo: V3AccountAppeal(appealUrl: urlString),
                success: {},
                error: { [weak self] err in
                    self?.errorHandler.handle(err)
                })
        default:
            super.handleClickLink(URL, textView: textView)
        }
    }
}

// MARK: alert
extension V3RecoverAccountCarrierViewController: PassportPrivacyServicePolicyProtocol {
    var currentPolicyPresentVC: UIViewController { self }
}

extension V3RecoverAccountCarrierViewController: V3FlatTextFieldDelegate {
    func textFieldShouldReturn(_ textField: V3FlatTextField) -> Bool {
        if self.vm.isNextButtonEnabled() {
            self.onNextStepClicked()
        }
        return true
    }
}
