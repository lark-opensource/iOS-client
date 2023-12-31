//
//  OneKeyLoginViewController.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/11.
//

import Foundation
import LarkLocalizations
import RxSwift
import LarkUIKit
import LarkAlertController
import Homeric
import ECOProbeMeta
import LarkFontAssembly

class OneKeyLoginViewController: BaseViewController {

    lazy var switchLanguageButton: SelectLanguageButton = {
        return SelectLanguageButton(presentVC: self, didStartSelect: nil)
    }()

    lazy var loginBtn: NextButton = {
        let btn = NextButton(title: vm.loginBtnTitle, style: .roundedRectBlue)
        btn.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return}
                self.handleNextStep()
                self.logger.info("n_action_onekey_auth_next")
            }).disposed(by: disposeBag)
        return btn
    }()

    lazy var otherLoginBtn: NextButton = {
        let otherBtn = NextButton(title: vm.otherBtnTitle, style: .roundedRectWhiteWithGrayOutline)
        otherBtn.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self](_) in
                guard let self = self else { return }
                self.otherLogin()
                self.vm.trackSwitchToOther()
                let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.stepInfo.flowType ?? "", click: "switch_login_method", target: "none")
                SuiteLoginTracker.track(Homeric.PASSPORT_ONE_CLICK_LOGIN_CLICK, params: params)
                self.logger.info("n_action_onekey_auth_other")
            }).disposed(by: disposeBag)
        return otherBtn
    }()

    let phoneLabel = UILabel()
    let serviceLabel = UILabel()
    lazy var agreement: AgreementView = {
        return AgreementView(
            needCheckBox: vm.needCheckBox,
            plainString: vm.agreementPlainString,
            links: vm.agreementLinks,
            checkAction: { (_) in
            }) { [weak self](url, _, label) in
                self?.handleClickLink(url, textView: label)
        }
    }()

    let vm: OneKeyLoginViewModel

    init(vm: OneKeyLoginViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
        self.useCustomNavAnimation = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(switchLanguageButton)
        switchLanguageButton.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Layout.lanBtnTopSpace)
            make.height.equalTo(Layout.lanBtnHeight)
            make.right.equalTo(horizontalSafeAeraTarget).inset(Common.Layout.itemSpace)
        }
        let logoImg: UIImage
        if let appIcon = PassportConf.shared.appIcon {
            logoImg = appIcon
        } else {
            logoImg = BundleResources.AppResourceLogo.logo
        }
        let imageView = UIImageView(image: logoImg)
        imageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        imageView.layer.cornerRadius = Layout.imageSize.width * 0.2
        imageView.clipsToBounds = true

        view.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(Layout.imageSize)
            make.centerX.equalToSuperview()
        }

        let tipLabelView = staticLabelView()
        view.addSubview(tipLabelView)
        tipLabelView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.centerY)
            make.top.equalTo(imageView.snp.bottom).offset(Layout.imageBottom)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        let btnView = mainButtonView()
        view.addSubview(btnView)
        btnView.snp.makeConstraints { (make) in
            make.top.equalTo(tipLabelView.snp.bottom).offset(Layout.btnViewTop)
            make.left.right.equalToSuperview().inset(CL.itemSpace)
        }

        view.addSubview(agreement)
        agreement.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.top.equalTo(btnView.snp.bottom).offset(Layout.agreementTop)
        }

        setupLocaleNotification()
        setupFontNotification()

        if vm.needRefetch {
            OneKeyLogin.getPhoneNumber(success: { (number, _) in
                self.phoneLabel.text = number
            }) { (error) in
                self.logger.error("get one key login number error", error: error)
            }
        }

        PassportMonitor.flush(PassportMonitorMetaLogin.oneKeyLoginEnter,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: nil,
                              context: vm.context)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pageName = self.pageName() {
            SuiteLoginTracker.track(pageName, params: [
                TrackConst.loginType: vm.type.rawValue,
                TrackConst.carrier: vm.oneKeyService.trackName
            ])
        }
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.stepInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_ONE_CLICK_LOGIN_VIEW, params: params)
        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_login_page_entry, context: vm.context)
        logger.info("n_page_onekey_auth_start")
    }

    override func onlyNavUI() -> Bool {
        return true
    }

    func setupLocaleNotification() {
        NotificationCenter.default.rx.notification(.preferLanguageChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.agreement.updateContent(
                    plainString: self.vm.agreementPlainString,
                    links: self.vm.agreementLinks
                )
                self.updateContent()
            }).disposed(by: disposeBag)
    }

    func setupFontNotification() {
        // 监听字体可能的变化（语言 或者 粗体），重新调用字体设置才能生效
        NotificationCenter.default.rx.notification(LarkFont.systemFontDidChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateContent()
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(LarkFont.boldTextStatusDidChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateContent()
            }).disposed(by: disposeBag)
    }

    func otherLogin() {
        dismiss(animated: true, completion: {
            self.vm.otherLoginAction?()
        })
    }

    override func pageName() -> String? {
        return Homeric.LOGIN_ENTER_ONE_KEY_AUTH
    }

    override func clickBackOrClose(isBack: Bool) {
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.stepInfo.flowType ?? "", click: "closed", target: "none")
        SuiteLoginTracker.track(Homeric.PASSPORT_ONE_CLICK_LOGIN_CLICK, params: params)

        PassportMonitor.flush(PassportMonitorMetaLogin.oneKeyLoginCancel,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: nil,
                              context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }
}

extension OneKeyLoginViewController {
    func staticLabelView() -> UIView {
        let backView = UIView()

        phoneLabel.textColor = UIColor.ud.textTitle
        phoneLabel.textAlignment = .center
        phoneLabel.font = UIFont.systemFont(ofSize: 26.0, weight: .medium)
        phoneLabel.text = vm.number
        backView.addSubview(phoneLabel)

        serviceLabel.textColor = UIColor.ud.textPlaceholder
        serviceLabel.text = vm.serviceTip
        serviceLabel.textAlignment = .center
        serviceLabel.font = UIFont.systemFont(ofSize: 14.0)
        backView.addSubview(serviceLabel)

        phoneLabel.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }

        serviceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(phoneLabel.snp.bottom).offset(Layout.serviceLabelTop)
            make.bottom.left.right.equalToSuperview()
        }

        return backView
    }

    func mainButtonView() -> UIView {
        let backView = UIView()
        backView.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }
        backView.addSubview(otherLoginBtn)
        otherLoginBtn.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(loginBtn.snp.bottom).offset(CL.itemSpace)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }
        return backView
    }

    func updateContent() {
        // 更新语言时要更新文案，也要重新设置字体才能生效
        loginBtn.setTitle(vm.loginBtnTitle, for: .normal)
        loginBtn.resetFont()

        otherLoginBtn.setTitle(vm.otherBtnTitle, for: .normal)
        otherLoginBtn.resetFont()

        switchLanguageButton.setTitle(LanguageManager.currentLanguage.displayName)
        switchLanguageButton.resetFont()

        serviceLabel.text = vm.serviceTip
        serviceLabel.font = UIFont.systemFont(ofSize: 14.0)

        phoneLabel.font = UIFont.systemFont(ofSize: 26.0, weight: .medium)

    }

    func handleNextStep() {
        func login() {
            logger.info("start login")
            PassportMonitor.flush(PassportMonitorMetaLogin.startOneKeyLoginVerify,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: nil,
                                  context: self.vm.context)
            ProbeDurationHelper.startDuration(ProbeDurationHelper.loginOneKeyVerifyFlow)
            self.showLoading()
            vm.login().subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.logger.info("login success")
                self.stopLoading()
                self.vm.trackResult(success: true, error: nil)
                let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.stepInfo.flowType ?? "", click: "login", target: "none", data: ["login_result": "success"])
                SuiteLoginTracker.track(Homeric.PASSPORT_ONE_CLICK_LOGIN_CLICK, params: params)
                PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_login_page_goto_login, context: self.vm.context)

                let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginOneKeyVerifyFlow)
                PassportMonitor.monitor(PassportMonitorMetaLogin.oneKeyLoginVerifyResult,
                                        eventName: ProbeConst.monitorEventName,
                                        categoryValueMap: [ProbeConst.duration: duration],
                                        context: self.vm.context).setResultTypeSuccess().flush()

            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.logger.error("login failed", error: error)
                self.stopLoading()
                self.handle(error)
                let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.stepInfo.flowType ?? "", click: "login", target: "none", data: ["login_result": "failed"])
                SuiteLoginTracker.track(Homeric.PASSPORT_ONE_CLICK_LOGIN_CLICK, params: params)
                PassportMonitor.flush(EPMClientPassportMonitorLoginCode.onekey_login_page_goto_login, context: self.vm.context)

                let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginOneKeyVerifyFlow)
                PassportMonitor.monitor(PassportMonitorMetaLogin.oneKeyLoginVerifyResult,
                                        eventName: ProbeConst.monitorEventName,
                                        categoryValueMap: [ProbeConst.duration: duration,
                                                           ProbeConst.carrier: "\(OneKeyLogin.currentService?.rawValue ?? "")"],
                                        context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
            }).disposed(by: disposeBag)
        }
        if vm.needCheckBox {
            if agreement.checked {
                login()
            } else {
                alertPolicyCheckNeeded()
            }
        } else {
            login()
        }
    }

    override func handle(_ error: Error) {
        self.vm.trackResult(success: false, error: error)
        func errorAlert(title: String, content: String) {
            SuiteLoginUtil.runOnMain {
                let alert = LarkAlertController()
                alert.setTitle(text: title)
                alert.setContent(text: content)
                alert.addPrimaryButton(text: I18N.Lark_Login_NumberDetectPopUpButtonOtherLoginSignup, dismissCompletion:  {
                    self.otherLogin()
                })
                self.present(alert, animated: true, completion: nil)
            }
        }

        if let err = error as? V3LoginError {
            if case .badServerCode(let errroInfo) = err, errroInfo.type == .oneKeyLoginServiceError {
                errorAlert(title: I18N.Lark_Login_NumberDetectOperatorErrorPopupTitle, content: vm.serverErrorContent)
            } else {
                super.handle(error)
            }
        } else if let err = error as? EventBusError {
            super.handle(err)
        } else {
            if let errorCode = OneKeyLoginSDKErrorCode(rawValue: (error as NSError).code), errorCode == .timeout {
                errorAlert(title: I18N.Lark_Login_NumberDetectOverTimePopupTitle, content: vm.timeoutContent)
            } else {
                errorAlert(title: I18N.Lark_Login_NumberDetectOperatorErrorPopupTitle, content: vm.serverErrorContent)
            }
        }
    }
}

extension OneKeyLoginViewController {

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.termURL, Link.alertTermURL:
            let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.serviceTerm)
            guard let urlString = urlValue.value, let url = Foundation.URL(string: urlString) else {
                self.logger.error("invalid url link: \(URL) serviceTermUrl: \(urlValue)")
                return
            }
            BaseViewController.clickLink(url, vm: vm, vc: self, errorHandler: self)
        case Link.privacyURL, Link.alertPrivacyURL:
            let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.privacyPolicy)
            guard let urlString = urlValue.value, let url = Foundation.URL(string: urlString) else {
                self.logger.error("invalid url link: \(URL) privacyUrl: \(urlValue)")
                return
            }
            BaseViewController.clickLink(url, vm: vm, vc: self, errorHandler: self)
        case Link.oneKeyLoginPolicyURL, Link.alertOneKeyLoginPolicyURL:
            guard let url = Foundation.URL(string: vm.policyURL) else {
                self.logger.error("invalid url link: \(URL) oneKeyLoginPolicy: \(vm.policyURL)")
                return
            }
            BaseViewController.clickLink(url, vm: vm, vc: self, errorHandler: self)
        default:
            super.handleClickLink(URL, textView: textView)
            return
        }
    }

    func alertPolicyCheckNeeded() {
        let controller = LarkAlertController()
        controller.setTitle(text: I18N.Lark_Login_V3_AgreePolicyTitle)
        let label = LinkClickableLabel.default(with: self)
        label.attributedText = .makeLinkString(
            plainString: vm.alertPolicyPlainString,
            links: vm.alertAgreementLinks,
            font: .systemFont(ofSize: 16.0),
            color: UIColor.ud.textTitle,
            linkFont: .systemFont(ofSize: 16.0)
        )
        label.textAlignment = .center
        controller.setFixedWidthContent(view: label)
        controller.addSecondaryButton(
            text: I18N.Lark_Login_V3_PolicyAlertCancel,
            dismissCompletion: nil
        )
        controller.addPrimaryButton(
            text: I18N.Lark_Login_V3_PolicyAlertAgree,
            dismissCompletion: {
                self.agreement.checked = true
                self.handleNextStep()
            }
        )
        self.present(controller, animated: true, completion: nil)
    }
}

extension OneKeyLoginViewController {
    enum Layout {
        static let btnViewTop: CGFloat = 24.0
        static let imageSize: CGSize = CGSize(width: 86.0, height: 86.0)
        static let imageBottom: CGFloat = 38.0
        static let serviceLabelTop: CGFloat = 8.0
        static let lanBtnTopSpace: CGFloat = 12.0
        static let lanBtnHeight: CGFloat = 22.0
        static let agreementTop: CGFloat = 20.0
    }
}
