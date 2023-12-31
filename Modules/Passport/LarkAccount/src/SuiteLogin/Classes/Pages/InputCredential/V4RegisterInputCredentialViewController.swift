//
//  V4RegisterInputCredentialViewController.swift
//  LarkAccount
//
//  Created by au on 2021/6/9.
//

import UIKit
import LarkLocalizations
import RxSwift
import RxCocoa
import LarkUIKit
import LKCommonsLogging
import SnapKit
import Homeric
import LarkAlertController
import LarkExtensions
import LarkFoundation
import LarkPerf
import LarkContainer
import EENavigator
import LarkReleaseConfig
import LarkFontAssembly

typealias V4InputCredentialViewModel = V3InputCredentialBaseViewModel & V4RegisterInputCredentialViewModelProtocol & V3InputCrendentialTrackProtocol

/// 注册团队设置个人信息页
/// 原先注册阶段个人信息填写页面统一使用 V3InputCredentialViewController，通过 process 区分
/// 新版本在 UI 和逻辑上有了更多的特化，于是抽出新的 vc 用来承载

class V4RegisterInputCredentialViewController: BaseViewController {

    lazy var loginInputView: LoginInputView = {
        let config = LoginInputViewConfig(
            canChangeMethod: vm.canChangeMethod,
            defaultMethod: vm.method.value,
            topCountryList: vm.topCountryList,
            allowRegionList: [],
            blockRegionList: [],
            emailRegex: vm.emailRegex,
            credentialInputList: vm.credentialInputList
        )
        return LoginInputView(delegate: self, config: config)
    }()

    lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .ud.body2
        label.textColor = .ud.functionDangerContentDefault
        label.numberOfLines = 0
        return label
    }()

    lazy var nameTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default, labelChangable: false)
        textfield.disableLabel = true
        textfield.textFiled.returnKeyType = .done
        textfield.textFiled.clearButtonMode = .always
        textfield.textFiled.addTarget(self, action: #selector(updateNextButton), for: .editingChanged)
        return textfield
    }()

    /// 注册link
    private lazy var processTipLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        return lbl
    }()

    /// 隐私协议 和 服务条款 link
    private lazy var policyLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        return lbl
    }()

    private lazy var checkbox: V3Checkbox = {
        let cb = V3Checkbox(iconSize: CL.checkBoxSize)
        cb.hitTestEdgeInsets = CL.checkBoxInsets
        cb.rx.controlEvent(UIControl.Event.valueChanged).subscribe { [weak self] _ in
            guard let self = self else { return }
            if cb.isSelected {
                self.vm.trackPrivacyCheckboxCheck(method: self.vm.method.value)
            } else {
                self.vm.trackPrivacyCheckboxUnCheck(method: self.vm.method.value)
            }
        }.disposed(by: disposeBag)
        return cb
    }()

    private lazy var keepLoginCheckbox: V3Checkbox = {
        let cb = V3Checkbox(iconSize: CL.checkBoxSize)
        cb.hitTestEdgeInsets = CL.checkBoxInsets
        cb.isSelected = PassportStore.shared.keepLogin
        cb.rx.controlEvent(UIControl.Event.valueChanged).subscribe { [weak self] _ in
            guard let self = self else { return }
            PassportStore.shared.keepLogin = cb.isSelected
        }.disposed(by: disposeBag)
        return cb
    }()

    /// 隐私协议 和 服务条款 link
    private lazy var keepLoginLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        return lbl
    }()

    lazy var switchLanguageButton: SideIconButton = {
        let btn = SideIconButton(
            leftIcon: Resource.V3.lan_icon,
            title: LanguageManager.currentLanguage.displayName,
            rightIcon: Resource.V3.lan_arrow
        )
        btn.addTarget(self, action: #selector(switchLocaleButtonTapped), for: .touchUpInside)
        return btn
    }()

    private var viewFirstLayout = true
    private var viewFirstAppear = true
    private var viewWillDisappear = false

    @Provider var idpService: IDPServiceProtocol

    let vm: V4InputCredentialViewModel

    init(vm: V4InputCredentialViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSwitchLanguage()
        setupNameTextField()
        setupInputView()
        setupLabels()
        updateViewLocale()
        setupLoginInfo()
        setupSwitchLoginMethodHandler()
        setupNextButtonClickHandler()
        setupLocaleNotification()
        setupFontNotification()
        setupPersonalInfo()
        updateCredentialIfNeeded()
        updateNextButton()

        inputAdjustView.snp.remakeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.visualNaviBarHeight)
            make.height.greaterThanOrEqualTo(1)
            make.left.right.equalToSuperview()
        }

        // 精简登录，不先Layout，push时有展开动画
        // 理论上是通用问题，所以不加layout调用条件限定
        view.layoutIfNeeded()

        PassportMonitor.flush(PassportMonitorMetaStep.personalInfoEnter,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.flowType],
                context: vm.context)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = UIColor.ud.bgBody
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pageName = self.pageName() {
            SuiteLoginTracker.track(pageName, params: [TrackConst.path: vm.trackPath])
        }
        vm.trackViewShow()
        vm.cleanTokenIfNeeded()
        logger.info("n_page_set_user_info_start")

        if viewFirstAppear {
            viewFirstAppear = false
            self.logger.info("loginVCAvailableSub triggered from else macro handle logic")
            self.vm.service.loginVCAvailableSub.accept(true)
        } else {
            self.logger.info("loginVCAvailableSub triggered from else handle logic")
            self.vm.service.loginVCAvailableSub.accept(true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if viewFirstLayout {
            viewFirstLayout = false
            loginInputView.setViewDefault()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappear = true
    }

    @objc
    func handleAuthorizationAppleIDButtonPress() {
        guard #available(iOS 13.0, *) else {
            return
        }

        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.idpEnter.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "register_or_login",
            MultiSceneMonitor.Const.result.rawValue: "success",
            "idp_type": LoginCredentialIdpChannel.apple_id.rawValue
        ]
        self.showLoading()
        let body = SSOUrlReqBody(authChannel: .apple_id, sceneInfo: sceneInfo, context: vm.context)
        idpService.fetchConfigForIDP(body)
            .post(false, context: self.vm.context)
            .subscribe(onNext: { [weak self] in
                self?.stopLoading()
            }, onError: { [weak self] (error) in
                self?.handlerError(error)
            }).disposed(by: disposeBag)
    }

    @objc
    func handleAuthorizationGoogleButtonPress() {
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.idpEnter.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "register_or_login",
            MultiSceneMonitor.Const.result.rawValue: "success",
            "idp_type": LoginCredentialIdpChannel.google.rawValue
        ]
        self.showLoading()
        let body = SSOUrlReqBody(authChannel: .google, sceneInfo: sceneInfo, context: vm.context)
        idpService
            .fetchConfigForIDP(body)
            .post(false, context: self.vm.context)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.stopLoading()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.handlerError(error)
            })
            .disposed(by: disposeBag)
    }

    func setupSwitchLoginMethodHandler() {
        vm.method
            .observeOn(MainScheduler.instance)
            .skip(1) // 忽略初始化的信号
            .subscribe(onNext: { [unowned self] (loginMethod) in
                self.logger.info("n_action_set_user_info_change_cp_type", additionalData: ["type": "\(loginMethod)"])
                self.vm.trackSwitchMethod()
                self.loginInputView.checkTextFieldFocus()
                self.updateNextButton()
            }).disposed(by: self.disposeBag)
    }

    func setupNextButtonClickHandler() {
        nextButton.rx.tap.subscribe { [unowned self] _ in
            self.logger.info("n_action_set_user_info_next")
            self.handleNextStep()
        }.disposed(by: disposeBag)
    }

    func handleNextStep() {
        self.view.endEditing(true)
        vm.trackClickNext()
        if vm.needPolicyCheckbox, !checkbox.isSelected {
            self.showPolicyAlert(delegate: self) { (confirm) in
                if confirm {
                    self.checkbox.isSelected = true
                    self.handleNextStep()
                }
            }
            return
        }
        logger.info("input credential click next button process: \(vm.processName)", method: .local)
        updateCredentialAndName()
        vm.storeLoginConfig()
        showLoading()
        vm.clickNextButton().subscribe(onNext: { [weak self] (_) in
            self?.stopLoading()
        }, onError: { [weak self] (err) in
            self?.handlerError(err)
        }).disposed(by: self.disposeBag)
    }

    func setupLocaleNotification() {
        NotificationCenter.default.rx.notification(.preferLanguageChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateViewLocale()
                self.loginInputView.checkTextFieldFocus()
            }).disposed(by: disposeBag)
    }
    
    func setupFontNotification() {
        // 监听字体可能的变化（语言 或者 粗体），重新调用字体设置才能生效
        NotificationCenter.default.rx.notification(LarkFont.systemFontDidChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateViewLocale()
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(LarkFont.boldTextStatusDidChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.updateViewLocale()
            }).disposed(by: disposeBag)
    }

    func setupLoginInfo() {
        guard let info = vm.inputInfo else {
            // 在Lark包下，按照地区填写默认区号
            if ReleaseConfig.isLark {
                let mobileProvider = MobileCodeProvider(mobileCodeLocale: LanguageManager.currentLanguage,
                                                  topCountryList: vm.service.topCountryList,
                                                  allowCountryList: vm.allowRegionList,
                                                  blockCountryList: vm.blockRegionList)
                if let regionCode = Locale.current.regionCode,
                   let country = mobileProvider.searchCountry(countryKey: regionCode) {
                        loginInputView.updateMobileRegion(regionCode: country.code)
                        vm.credentialRegionCode.accept(country.code)
                }
            }
            return
        }
        switch info.method {
        case .email:
            loginInputView.emailTextField.text = info.contact
        case .phoneNumber:
            if vm.credentialRegionCode.value == info.countryCode {
                loginInputView.phoneTextField.setTextWithFormat(info.contact)
            } else if loginInputView.canChangeRegionCode {
                loginInputView.updateMobileRegion(regionCode: info.countryCode)
                loginInputView.phoneTextField.setTextWithFormat(info.contact)
            }
        }
        nameTextField.text = info.name

        updateCredentialAndName()
        updateNextButton()
    }

    @objc
    func updateNextButton() {
        let regionCodeValid = vm.method.value == .email || vm.regionCodeValid.value
        let nameValid = (nameTextField.text?.count ?? 0 > 0)
        nextButton.isEnabled = regionCodeValid && nameValid && loginInputView.checkButtonDisable()
        stopLoading()
    }

    func setupPersonalInfo() {
        nameTextField.attributedPlaceholder = NSAttributedString(
            string: vm.namePlaceholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.ud.textPlaceholder
        ])
    }

    // 预填 CP 信息
    private func updateCredentialIfNeeded() {
        guard let userCenterInfo = vm.userCenterInfo else {
            return
        }
        
        let mainlandRegionCode = 86
        let prefix = "+"

        nameTextField.text = userCenterInfo.currentIdentityBindings?.first?.userList.first?.user.name

        // 预填CP信息后更新VM里的值
        defer { updateCredentialAndName() }

        if let phoneIdentity = userCenterInfo.currentIdentityBindings?.first(where: { $0.credential?.credentialType == 1 }),
           let cp = phoneIdentity.credential?.credential {
            if vm.joinTeamInFeishu {
                // 这里先判断是否是加入团队场景
                // 如果是加入飞书团队，和包环境无关，只预填 +86 手机号
                guard let regionCode = phoneIdentity.credential?.countryCode,
                        regionCode == mainlandRegionCode else { return }
                let phoneNumber = cp.replacingOccurrences(of: prefix + "\(regionCode)", with: "")
                loginInputView.phoneTextField.setTextWithFormat(phoneNumber)
                return
            }
            if ReleaseConfig.isFeishu {
                // 飞书包下，只预填 +86 手机号
                guard let regionCode = phoneIdentity.credential?.countryCode,
                        regionCode == mainlandRegionCode else { return }
                let phoneNumber = cp.replacingOccurrences(of: prefix + "\(regionCode)", with: "")
                loginInputView.phoneTextField.setTextWithFormat(phoneNumber)
            } else {
                // Lark 包下，不区分地区
                guard let regionCode = phoneIdentity.credential?.countryCode else { return }
                let phoneNumber = cp.replacingOccurrences(of: prefix + "\(regionCode)", with: "")
                loginInputView.updateMobileRegion(regionCode: prefix + "\(regionCode)")
                loginInputView.phoneTextField.setTextWithFormat(phoneNumber)
            }
        }

        if let emailIdentity = userCenterInfo.currentIdentityBindings?.first(where: { $0.credential?.credentialType == 2 }),
           let cp = emailIdentity.credential?.credential {
            loginInputView.emailTextField.text = cp
        }
    }

    private func handlerError(_ error: Error) {

        if let err = error as? V3LoginError {
            switch err {
            case let .badServerCode(info):
                switch info.type {
                case .loginMobileIllegal, .notCredentialContact:
                    self.stopLoading()
                    var cancelOrLogin: UIAlertAction
                    var trackEvent: String = ""
                    if info.type == .loginMobileIllegal {
                        self.logger.info("input credential alert \(info.type)")
                        // 飞书白板用户登录时输入非+86手机的case， 弹窗处理
                        cancelOrLogin = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Login_Cancel, style: .cancel, handler: nil)
                        trackEvent = Homeric.LOGIN_UNREGISTER_PHONE_NUMBER
                    } else {
                        self.logger.info("input credential alert \(info.type)")
                        // 输入非账号，但是联系方式，弹窗提示用户使用关联账号或去注册的弹窗
                        trackEvent = Homeric.LOGIN_UNBOUND_CP_CLICK_REGISTER
                        cancelOrLogin = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Login_V3_LoginTitle(), style: .default) { (_) in
                            // 登陆
                        }
                    }
                    let alert = UIAlertController(title: nil,
                                                  message: info.message,
                                                  preferredStyle: .alert)
                    let register = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Login_V3_notregtoreg, style: .default) { [trackEvent] (_) in
                        // 注册
                        SuiteLoginTracker.track(trackEvent)
                        self.vm.post(
                            event: PassportStep.setPersonalInfo.rawValue,
                            additionalInfo: self.vm.currentInputInfo(),
                            success: {},
                            error: { [weak self] err in
                                self?.handle(err)
                            })
                    }
                    alert.addAction(cancelOrLogin)
                    alert.addAction(register)
                    present(alert, animated: true, completion: nil)
                    return
                default:
                    break
                }
            default:
                break
            }
        }
        // 其余情况交由base处理
        handle(error)
    }

    override public func needSwitchButton() -> Bool {
        return vm.needQRLogin
    }

    override var keyboardShowBottomViewOffset: CGFloat {
        return safeAreaBottom
    }

    func updateCredentialAndName() {
        vm.credentialPhone.accept(loginInputView.phoneTextField.text ?? "")
        vm.credentialRegionCode.accept(loginInputView.phoneTextField.labelText ?? "")
        vm.credentialEmail.accept(loginInputView.emailTextField.currentText ?? "")
        vm.name.accept(nameTextField.text ?? "")
    }

    override public func pageName() -> String? { vm.pageName }

    override func clickBackOrClose(isBack: Bool) {
        vm.trackClickBack()
        PassportMonitor.flush(PassportMonitorMetaStep.personalInfoCancel,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.flowType],
                context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }

    override func switchAction(sender: UIButton) {
        self.showLoading()
        self.vm.handleSwitchAction()
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                self.stopLoading()
                self.logger.info("handleSwitchAction success")
            } onError: { [weak self](error) in
                self?.handle(error)
            }.disposed(by: disposeBag)
    }
}

// MARK: Setup 视图
extension V4RegisterInputCredentialViewController {

    func setupSwitchLanguage() {
        if vm.needLocaleButton {
            view.addSubview(switchLanguageButton)
            switchLanguageButton.snp.makeConstraints { (make) in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Layout.lanBtnTopSpace)
                make.height.equalTo(Layout.lanBtnHeight)
                make.right.equalTo(horizontalSafeAeraTarget).inset(Common.Layout.itemSpace)
            }
        }
    }

    func setupNameTextField() {
        centerInputView.addSubview(nameTextField)
        nameTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.height.equalTo(48.0)
            make.bottom.equalToSuperview().inset(CL.fieldBottom)
        }
    }

    func setupInputView() {
        errorLabel.isHidden = true
        let brand = vm.tenantBrand ?? SwitchEnvironmentManager.shared.appBrand
        if brand == .feishu {
            errorLabel.text = I18N.Lark_Passport_CrossLoginIntercept_UnableToJoinOrgWithNon86Phone_ErrorMsg()
        } else {
            errorLabel.text = I18N.Lark_Passport_CrossLoginIntercept_UnableToJoinOrgWith86Phone_ErrorMsg()
        }

        vm.regionCodeValid
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isValid in
                if self?.vm.method.value == .phoneNumber {
                    self?.errorLabel.isHidden = isValid
                    self?.loginInputView.phoneTextField.hasError = !isValid
                } else {
                    // 非手机号的情况下不展示互通错误提示
                    self?.errorLabel.isHidden = true
                    self?.loginInputView.phoneTextField.hasError = false
                }
            })

        let stack = UIStackView(arrangedSubviews: [loginInputView, errorLabel])
        stack.axis = .vertical
        stack.spacing = 4

        centerInputView.addSubview(stack)
        stack.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.top.equalToSuperview()
            make.bottom.equalTo(nameTextField.snp.top).offset(-16)
        }
        loginInputView.nameTextField = nameTextField
        loginInputView.checkTextFieldFocus()
    }

    func updatePolicyLayout() {
        if vm.needPolicyCheckbox {
            checkbox.snp.remakeConstraints { (make) in
                make.size.equalTo(CL.checkBoxSize)
                make.left.equalToSuperview().offset(CL.itemSpace)
                make.bottom.equalTo(policyLabel.snp.firstBaseline).offset(CL.checkBoxYOffset)
            }
            policyLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(nameTextField.snp.bottom).offset(24)
                make.left.equalTo(checkbox.snp.right).offset(CL.processTipTopSpace)
                make.right.equalToSuperview()
            }
        } else {
            policyLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom).offset(5)
                make.left.equalToSuperview().offset(Layout.policyLabelPadding)
                make.right.lessThanOrEqualToSuperview()
            }
            if vm.needKeepLoginTip {
                keepLoginCheckbox.snp.remakeConstraints { (make) in
                    make.size.equalTo(CL.checkBoxSize)
                    make.left.equalToSuperview().offset(CL.itemSpace)
                    make.bottom.equalTo(keepLoginLabel.snp.firstBaseline).offset(CL.checkBoxYOffset)
                }
                keepLoginLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(processTipLabel.snp.bottom).offset(16)
                    make.left.equalTo(keepLoginCheckbox.snp.right).offset(CL.checkBoxRightPadding)
                    make.right.equalToSuperview()
                }
            }
        }
    }

    func setupLabels() {
        if !vm.needSubtitle {
            detailLabel.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(moveBoddyView).inset(CL.itemSpace)
                make.top.equalTo(titleLabel.snp.bottom).offset(0)
                make.height.equalTo(0)
            }
        }
        detailLabel.isHidden = false
        if vm.needProcessTipLabel {
            detailLabel.isHidden = true
            inputAdjustView.addSubview(processTipLabel)
            inputAdjustView.bringSubviewToFront(bottomView)
            let labelTop = vm.needQRLogin ? Layout.processTipTopSpaceWhenQRLogin : CL.processTipTopSpace
            processTipLabel.snp.makeConstraints { (make) in
                make.top.equalTo(switchButtonContainer.snp.bottom).offset(labelTop)
                make.left.equalTo(moveBoddyView).inset(CL.itemSpace)
                make.right.lessThanOrEqualTo(moveBoddyView).inset(CL.itemSpace)
                make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
            }
        }

        moveBoddyView.addSubview(policyLabel)
        if vm.needPolicyCheckbox {
            moveBoddyView.addSubview(checkbox)
        }
        if vm.needKeepLoginTip {
            moveBoddyView.addSubview(keepLoginLabel)
            moveBoddyView.addSubview(keepLoginCheckbox)
        }
        moveBoddyView.bringSubviewToFront(bottomView)

        updatePolicyLayout()
    }

    func updateProcessLabelLocale() {
        processTipLabel.attributedText = vm.processTip
    }

    func updatePolicyLabelLocale() {
        // TODO: 根据服务端数据显示
        policyLabel.attributedText = self.policyTip(
            isRegisterType: vm.process.value == .register
        )
    }

    func updateKeeyLoginLocale() {
        keepLoginLabel.attributedText = self.vm.keepLoginText
    }

    func updateViewLocale() {
        nextButton.setTitle(vm.nextButtonTitle, for: .normal)
        nextButton.resetFont()
        if vm.needLocaleButton {
            switchLanguageButton.setTitle(LanguageManager.currentLanguage.displayName)
            switchLanguageButton.resetFont()
        }

        loginInputView.updateViewLocale()
        loginInputView.updateMobileRegion(regionCode: vm.credentialRegionCode.value)

        updatePolicyLabelLocale()
        configInfo(vm.title, detail: vm.subtitle)
        resetTitleFont()
        updateProcessLabelLocale()
        if vm.needKeepLoginTip {
            updateKeeyLoginLocale()
        }
        if vm.needQRLogin {
            self.switchButton.setTitle(I18N.Lark_Login_TitleOfQRPage, for: .normal)
            self.switchButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        }
    }

    func googleButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: (UIScreen.main.bounds.size.width - 200) / 2, y: 550, width: 44, height: 44)
        button.layer.borderColor = UIColor.ud.N300.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 22
        button.layer.masksToBounds = true
        button.setImage(Resource.V3.login_google_logo, for: .normal)
        button.setImage(Resource.V3.login_google_logo, for: .highlighted)
        button.addTarget(self, action: #selector(handleAuthorizationGoogleButtonPress), for: .touchUpInside)
        return button
    }

    func appleIdButton() -> UIButton {
        let appleLoginBtn = UIButton(type: .custom)
        appleLoginBtn.frame = CGRect(x: (UIScreen.main.bounds.size.width - 200) / 2 + 50, y: 550, width: 44, height: 44)
        appleLoginBtn.layer.borderColor = UIColor.ud.N300.cgColor
        appleLoginBtn.layer.borderWidth = 1
        appleLoginBtn.layer.cornerRadius = 22
        appleLoginBtn.layer.masksToBounds = true
        appleLoginBtn.setImage(Resource.V3.login_apple_logo, for: .normal)
        appleLoginBtn.setImage(Resource.V3.login_apple_logo, for: .highlighted)
        appleLoginBtn.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        return appleLoginBtn
    }
}

// MARK: - LoginInputSegmentViewDelegateProtocol
extension V4RegisterInputCredentialViewController: LoginInputSegmentViewDelegateProtocol {
    func mobileCodeSelectClick() {
        self.logger.info("tap mobile code")
        self.vm.trackSwitchCountryCode()
    }

    func selectedMobileCode(_ mobileCode: MobileCode) {
        vm.credentialRegionCode.accept(mobileCode.code)
        vm.trackSwitchRegionCode()

        updateNextButton()
    }

    func needUpdateButton(enable: Bool) {
        let regionCodeValid = vm.method.value == .email || vm.regionCodeValid.value
        let nameValid = (nameTextField.text?.count ?? 0 > 0)
        nextButton.isEnabled = regionCodeValid && nameValid && enable
    }

    func inputMethodChange(method: SuiteLoginMethod) {
        let click = method == .phoneNumber ? "phone_login" : "mail_login"
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.flowType, click: click, target: TrackConst.passportVerifyCodeView)
        SuiteLoginTracker.track(Homeric.PASSPORT_USER_INFO_SETTING_CLICK, params: params)
        vm.method.accept(method)
        if method == .phoneNumber {
            let regionCodeValid = vm.regionCodeValid.value
            self.errorLabel.isHidden = regionCodeValid
            self.loginInputView.phoneTextField.hasError = !regionCodeValid
        } else {
            self.errorLabel.isHidden = true
            self.loginInputView.phoneTextField.hasError = false
        }
    }

    func didTapReturnButton() {
        let nameValid = nameTextField.text?.count ?? 0 > 0
        guard nameValid && loginInputView.checkButtonDisable() else { return }
        handleNextStep()
    }
}

// MARK: Label 点击
extension V4RegisterInputCredentialViewController {

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.registerURL:
            self.logger.info("click link to register")
            vm.trackClickToRegister()
            self.view.endEditing(true)
            self.updateCredentialAndName()

            // TODO: .register?
            self.vm.post(
                event: PassportStep.setPersonalInfo.rawValue,
                additionalInfo: self.vm.currentInputInfo(),
                success: {},
                error: { [weak self] err in
                    self?.handle(err)
                })
        case Link.termURL, Link.privacyURL, Link.alertTermURL, Link.alertPrivacyURL:
            var openUrl: Foundation.URL?
            let tenantDomain = vm.tenantUnitDomain ?? ""
            if URL == Link.termURL || URL == Link.alertTermURL {
                vm.trackClickServiceTerm(URL)
                let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.serviceTerm)
                if let urlString = urlValue.value {
                    if !tenantDomain.isEmpty, let host = Foundation.URL(string: urlString)?.host {
                        let tenantString = urlString.replacingOccurrences(of: host, with: tenantDomain)
                        openUrl = Foundation.URL(string: tenantString)
                    } else {
                        openUrl = Foundation.URL(string: urlString)
                    }
                }
            } else {
                let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.privacyPolicy)
                vm.trackClickPrivacy(URL)
                if let urlString = urlValue.value {
                    if !tenantDomain.isEmpty, let host = Foundation.URL(string: urlString)?.host {
                        let tenantString = urlString.replacingOccurrences(of: host, with: tenantDomain)
                        openUrl = Foundation.URL(string: tenantString)
                    } else {
                        openUrl = Foundation.URL(string: urlString)
                    }
                }
            }
            guard let url = openUrl else {
                self.logger.error("invalid url link: \(URL)")
                return
            }
            BaseViewController.clickLink(url, vm: vm, vc: self, errorHandler: self)
        default:
            super.handleClickLink(URL, textView: textView)
        }
    }
}

// MARK: 切换本地化
extension V4RegisterInputCredentialViewController {

    @objc
    func switchLocaleButtonTapped() {
        vm.trackClickLocaleButton()
        let vc = LkNavigationController(rootViewController: SelectLanguageController())
        if isPad {
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = switchLanguageButton
            vc.popoverPresentationController?.sourceRect = switchLanguageButton.bounds
        } else {
            vc.modalPresentationStyle = .fullScreen
        }
        self.present(vc, animated: true, completion: nil)
    }
}

extension V4RegisterInputCredentialViewController {
    struct Layout {
        static let policyLabelSpace: CGFloat = 16 // 不同的值影响 LKLabel 绘制
        static let policyTop: CGFloat = 10
        static let policyBottom: CGFloat = 10
        static let lanBtnTopSpace: CGFloat = 12.0
        static let lanBtnHeight: CGFloat = 22.5
        static let policyLabelPadding: CGFloat = 11
        static let processTipTopSpaceWhenQRLogin: CGFloat = 20
    }
}

extension V4RegisterInputCredentialViewController: PassportPrivacyServicePolicyProtocol {
    var currentPolicyPresentVC: UIViewController { self }
}
