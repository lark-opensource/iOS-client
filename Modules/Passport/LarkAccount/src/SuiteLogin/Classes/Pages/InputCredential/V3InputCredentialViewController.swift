//
//  RegisterInputCredentialViewController.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/18.
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
import ECOProbeMeta
import LarkReleaseConfig
import LarkFontAssembly
#if BYTEST_AUTO_LOGIN
import AAFastbotTweak
#endif

typealias V3InputCredentialViewModel = V3InputCredentialBaseViewModel & V3InputCredentailViewModelProtocol & V3InputCrendentialTrackProtocol

class V3InputCredentialViewController: BaseViewController {

    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        imageView.image = BundleResources.AppResourceLogo.logo
        imageView.layer.cornerRadius = Layout.logoWidth * 0.2
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var loginInputView: LoginInputView = {

        let config = LoginInputViewConfig(
            canChangeMethod: vm.canChangeMethod,
            defaultMethod: vm.method.value,
            topCountryList: vm.service.topCountryList,
            allowRegionList: [],
            blockRegionList: vm.service.blackCountryList,
            emailRegex: vm.emailRegex,
            credentialInputList: []
        )
        return LoginInputView(delegate: self, config: config)
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
        return lbl
    }()

    private lazy var checkbox: V3Checkbox = {
        let cb = V3Checkbox(iconSize: CL.checkBoxSize)
        cb.hitTestEdgeInsets = Layout.checkBoxInsets
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
            leftIcon: Resource.V3.lan_icon.ud.withTintColor(UIColor.ud.iconN2),
            title: LanguageManager.currentLanguage.displayName,
            rightIcon: Resource.V3.lan_arrow.ud.withTintColor(UIColor.ud.textCaption)
        )
        btn.addTarget(self, action: #selector(switchLocaleButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    var idpGoogleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setupBottonActionStyle()
        button.layer.masksToBounds = true
        button.setImage(Resource.V3.login_google_logo, for: .normal)
        button.setImage(Resource.V3.login_google_logo, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(I18N.Lark_Passport_GoogleUserSignInOption_Google, for: .normal)
        button.addTarget(self, action: #selector(handleAuthorizationGoogleButtonPress), for: .touchUpInside)
        return button
    }()
    
    var idpAppleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setupBottonActionStyle()
        button.layer.masksToBounds = true
        button.setImage(Resource.V3.login_apple_logo.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        button.setImage(Resource.V3.login_apple_logo.ud.withTintColor(UIColor.ud.iconN1), for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(I18N.Lark_Passport_GoogleUserSignInOption_Apple, for: .normal)
        button.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        return button
    }()

    lazy var moreLoginOptionLineView: MoreLoginOptionLineView = {
        //客户端底部idp点位可配置化逻辑
        //b-idp和c-idp分别配置
        var bottomActions = vm.bottomActions
        if !vm.needBIdpView {
            bottomActions = .none
        }
        var idpButtons: [UIButton]
        if !vm.needCIdpView {
            idpButtons = [UIButton]()
        } else {
            idpButtons = buttonsToShow()
        }

        return MoreLoginOptionLineView(bottomActions, idpButtons: idpButtons)

    }()

    private var viewFirstLayout = true
    private var viewFirstAppear = true
    private var viewWillDisappear = false
    #if BYTEST_AUTO_LOGIN
    private var autoLoginNotification = "autoLoginNotification" //自动登录通知
    static var hasAutoLogin: Bool = false                       //是否执行过自动登录
    static var fastbotTweakHasSetup: Bool = false               //是否初始化自动登录库
    #endif

    private var needRegist: Bool {
        return !vm.ugRegistEnable.value && vm.needRegisterView
    }

    @Provider var idpService: IDPServiceProtocol

    let vm: V3InputCredentialViewModel

    init(vm: V3InputCredentialViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        setupBottomEnterpriseView()
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgLogin
        setupSwitchLanguage()
        setupLogo()
        setupInputView()
        setupLabels()
        updateViewLocale()
        setupLoginInfo()
        setupSwitchLoginMethodHandler()
        setupNextButtonClickHandler()
        setupLocaleNotification()
        setupFontNotification()
        layoutBottomEnterpriseView()

        inputAdjustView.snp.remakeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.visualNaviBarHeight)
            make.height.greaterThanOrEqualTo(1)
            make.left.right.equalToSuperview()
        }

        updateSwitchButtonLayout()

        // 精简登录，不先Layout，push时有展开动画
        // 理论上是通用问题，所以不加layout调用条件限定
        view.layoutIfNeeded()

        //只有执行bytest的时候才会执行自动登录
        #if BYTEST_AUTO_LOGIN
        self.autoLogin()
        #endif

        //如果是走 ug 的注册流程, 隐藏 passport 注册入口
        vm.ugRegistEnable.subscribe(onNext: {[weak self] isON in
            let needRegist = self?.needRegist ?? true
            if !isON && needRegist { //ug 流程没有开, 用passport 注册流程
                self?.setupProcessTipLabel()
                self?.updatePolicyLayout()
                self?.updateSwitchButtonLayout()
            }
        }).disposed(by: disposeBag)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !vm.service.store.isLoggedIn {
            // 当该vc 有 present（fullScreen）页面，登录成功更换 rootVC 时会触发该vc的 willAppear
            vm.revertEnvIfNeeded()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        removeBackOrCloseButtonIfNeeded()
        vm.trackViewShow()
        vm.cleanTokenIfNeeded()

        self.logger.info("n_page_login_input_start", method: .local)

        if viewFirstAppear {
            viewFirstAppear = false
            // make sure user see login page first
            let qrLoginDidAppear = presentQRLoginIfNeeded()

            #if ONE_KEY_LOGIN
            if !qrLoginDidAppear {
                checkOpenOneKeyLogin { [weak self] in
                    guard let self = self else { return }
                    self.logger.info("loginVCAvailableSub triggered from checkOpenOneKeyLogin callback")
                    self.vm.service.loginVCAvailableSub.accept(true)
                }
            }
            #else
            self.logger.info("loginVCAvailableSub triggered from else macro handle logic", method: .local)
            self.vm.service.loginVCAvailableSub.accept(true)
            #endif
            
            #if BYTEST_AUTO_LOGIN
            if !V3InputCredentialViewController.hasAutoLogin {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: autoLoginNotification), object: nil)
                V3InputCredentialViewController.hasAutoLogin = true
            }
            #endif
        } else {
            self.logger.info("loginVCAvailableSub triggered from else handle logic", method: .local)
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
    
    private func presentQRLoginIfNeeded() -> Bool {
        if vm.needQRLogin {
            switchAction(sender: switchButton)
            return true
        }
        return false
    }
    
    // 由于 UIKit 的问题，使用 popToViewController 方法回到登录页时，
    // viewWillAppear 里 navigationController 的数据不对，错误显示返回 button
    // 使用这个方法在 viewDidAppear 里处理一次
    private func removeBackOrCloseButtonIfNeeded() {
        if backButton.superview == nil { return }
        if presentingViewController == nil && !hasBackPage {
            backButton.removeFromSuperview()
        }
    }

    @objc
    func handleAuthorizationAppleIDButtonPress() {
        self.vm.trackClickIDPLogin(.appleID)
        self.logger.info("n_action_login_c_idp", additionalData: ["channel" : "apple"])
        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_c_apple_login_click, context: vm.context)
        
        guard #available(iOS 13.0, *) else {
            return
        }
        
        if vm.needPolicyCheckbox, !checkbox.isSelected {
            self.showPolicyAlert(delegate: self) { (confirm) in
                if confirm {
                    self.checkbox.isSelected = true
                    self.handleAuthorizationAppleIDButtonPress()
                }
            }
            return
        }

        PassportMonitor.flush(PassportMonitorMetaLogin.startIdpLoginPrepare,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.channel: ProbeConst.idpApple],
                              context: vm.context)
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginIdpPrepareFlow)
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.idpEnter.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "register_or_login",
            MultiSceneMonitor.Const.result.rawValue: "success",
            "idp_type": LoginCredentialIdpChannel.apple_id.rawValue
        ]
        self.showLoading()
        let body = SSOUrlReqBody(authChannel: .apple_id, sceneInfo: sceneInfo, context: vm.context)
        idpService.fetchConfigForIDP(body)
            .do(onNext: {[weak self] _ in
                self?.stopLoading()
            })
            .post(false, context: self.vm.context)
            .subscribe(onNext: { [weak self] in
                self?.stopLoading()
                let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpPrepareFlow)
                PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginPrepareResult,
                                        eventName: ProbeConst.monitorEventName,
                                        categoryValueMap: [ProbeConst.duration: duration, ProbeConst.channel: ProbeConst.idpApple],
                                        context: self?.vm.context ?? UniContextCreator.create(.login)).setResultTypeSuccess().flush()
            }, onError: { [weak self] (error) in
                self?.handlerError(error)
                let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpPrepareFlow)
                PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginPrepareResult,
                                        eventName: ProbeConst.monitorEventName,
                                        categoryValueMap: [ProbeConst.duration: duration, ProbeConst.channel: ProbeConst.idpApple],
                                        context: self?.vm.context ?? UniContextCreator.create(.login))
                    .setResultTypeFail()
                    .setPassportErrorParams(error: error)
                    .flush()
            }).disposed(by: disposeBag)
    }

    @objc
    func handleAuthorizationGoogleButtonPress() {
        self.vm.trackClickIDPLogin(.google)
        self.logger.info("n_action_login_c_idp", additionalData: ["channel" : "google"])
        PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_c_google_login_click, context: vm.context)

        if vm.needPolicyCheckbox, !checkbox.isSelected {
            self.showPolicyAlert(delegate: self) { (confirm) in
                if confirm {
                    self.checkbox.isSelected = true
                    self.handleAuthorizationGoogleButtonPress()
                }
            }
            return
        }

        PassportMonitor.flush(PassportMonitorMetaLogin.startIdpLoginPrepare,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.channel: ProbeConst.idpGoogle],
                              context: vm.context)
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginIdpPrepareFlow)
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.idpEnter.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "register_or_login",
            MultiSceneMonitor.Const.result.rawValue: "success",
            "idp_type": LoginCredentialIdpChannel.google.rawValue
        ]
        self.showLoading()
        let body = SSOUrlReqBody(authChannel: .google, sceneInfo: sceneInfo, action: .idp, context: vm.context)
        idpService
            .fetchConfigForIDP(body)
            .do(onNext: {[weak self] _ in
                self?.stopLoading()
            })
                .post(false, context: self.vm.context)
                .subscribe(onNext: { [weak self] in
                    self?.stopLoading()
                    let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpPrepareFlow)
                    PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginPrepareResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration, ProbeConst.channel: ProbeConst.idpGoogle],
                                            context: self?.vm.context ?? UniContextCreator.create(.login)).setResultTypeSuccess().flush()
                }, onError: { [weak self] (error) in
                    self?.handlerError(error)
                    let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpPrepareFlow)
                    PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginPrepareResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration, ProbeConst.channel: ProbeConst.idpGoogle],
                                            context: self?.vm.context ?? UniContextCreator.create(.login))
                        .setResultTypeFail()
                        .setPassportErrorParams(error: error)
                        .flush()
                }).disposed(by: disposeBag)
    }

    #if BYTEST_AUTO_LOGIN
    func autoLogin() {
        self.logger.info("n_action_autoLogin_setupFastbotTweak")
        guard V3InputCredentialViewController.fastbotTweakHasSetup == false else {
            return
        }
        FastbotTweak.setup()
        if(FastbotTweak.isFastbot()) {
            FTAutoLogin.autoLogin(whenReceiveNotification: autoLoginNotification) { [weak self](account, captcha, password, smscode, extraInfo) in
                
                guard let self = self else { return }
                
                self.vm.autoLogin(phoneNumber: account ?? "", password: password ?? "", code: smscode ?? "")
                    .subscribe(onNext: { _ in
                        self.logger.info("n_action_autoLogin_succ")
                    }, onError: { error in
                        self.logger.error("n_action_autoLogin_fail", error: error)
                        DispatchQueue.main.asyncAfter(deadline: .now()+5) {
                            self.logger.info("n_action_autoLogin_setupFastbotTweak", body: "second try")
                            self?.vm.autoLogin(phoneNumber: account ?? "", password: password ?? "", code: smscode ?? "").subscribe(onNext: { _ in
                                self.logger.info("n_action_autoLogin_succ")
                            }).disposed(by: self.disposeBag)
                        }
                    }).disposed(by: self.disposeBag)
            }
          }
        V3InputCredentialViewController.fastbotTweakHasSetup = true
    }
    #endif

    func setupSwitchLoginMethodHandler() {
        vm.method
            .observeOn(MainScheduler.instance)
            .skip(1) // 忽略初始化的信号
            .subscribe(onNext: { [unowned self] (loginMethod) in
                self.logger.info("n_action_login_input_change_cp_type", additionalData: ["type": "\(loginMethod)"], method: .local)
                self.vm.trackSwitchMethod()
                self.loginInputView.checkTextFieldFocus()
                self.checkButtonDisable()
            }).disposed(by: self.disposeBag)
    }

    func setupNextButtonClickHandler() {
        nextButton.rx.tap.subscribe { [unowned self] (_) in
            self.logger.info("n_action_login_input_next", method: .local)
            self.view.endEditing(true)
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
        PassportMonitor.monitor(PassportMonitorMetaLogin.startCommonLoginVerify,
                                eventName: ProbeConst.monitorEventName,
                                categoryValueMap: nil,
                                context: UniContextCreator.create(.authorization)).flush()
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginCommonFlow)
        logger.info("input credential click next button process: \(vm.processName)", method: .local)
        updateCreadential()
        vm.storeLoginConfig()
        showLoading()
        vm.clickNextButton().subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginCommonFlow)
            PassportMonitor.monitor(PassportMonitorMetaLogin.commonLoginVerifyResult,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: [ProbeConst.duration: duration],
                                    context: self.vm.context).setResultTypeSuccess().flush()
            self.stopLoading()
        }, onError: { [weak self] (err) in
            guard let self = self else { return }
            let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginCommonFlow)
            PassportMonitor.monitor(PassportMonitorMetaLogin.commonLoginVerifyResult,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: [ProbeConst.duration: duration],
                                    context: self.vm.context)
            .setResultTypeFail()
            .setPassportErrorParams(error: err)
            .flush()
            self.handlerError(err)
        }).disposed(by: self.disposeBag)
    }
    
    func handleEnterpriseStep(){
        self.logger.info("n_action_login_input_idp")
        self.vm.trackClickIDPLogin(.sso)
        if vm.needPolicyCheckbox, !checkbox.isSelected {
            self.showPolicyAlert(delegate: self) { (confirm) in
                if confirm {
                    self.checkbox.isSelected = true
                    self.handleEnterpriseStep()
                }
            }
            return
        }
        
        SuiteLoginTracker.track(Homeric.IDP_LOGIN_BUTTON)
        let context: UniContext
        if let ctx = vm.context as? UniContext {
            context = ctx
        } else {
            context = UniContextCreator.create(.login) as? UniContext ?? UniContext(.login)
        }
        if vm.enableDirectOpenIDPPage {
            self.vm.post(
                event: V3NativeStep.directOpenIDP.rawValue,
                serverInfo: nil,
                additionalInfo: V3EnterpriseInfo(isAddCredential: false),
                context: context,
                success: {},
                error: {[weak self] error in
                    self?.handle(error)
                })
        } else {
            self.vm.post(
                event: V3NativeStep.enterpriseLogin.rawValue,
                serverInfo: nil,
                additionalInfo: V3EnterpriseInfo(isAddCredential: false),
                context: context,
                success: {},
                error: { [weak self] err in
                    self?.handle(err)
                })
        }
    }

    func setupLocaleNotification() {
        NotificationCenter.default.rx.notification(.preferLanguageChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                // 为了保证切换语言后字体替换完成，将字体重设放到下一个runloop执行
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
        if let info = vm.inputInfo {
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
            checkButtonDisable()
        } else if ReleaseConfig.isLark {
            // 在没有缓存区号的情况下，用当前地区的区号作为默认
            let mobileProvider = MobileCodeProvider(mobileCodeLocale: LanguageManager.currentLanguage,
                                              topCountryList: vm.service.topCountryList,
                                              allowCountryList: [],
                                              blockCountryList: vm.service.blackCountryList)
            if let regionCode = Locale.current.regionCode,
               let country = mobileProvider.searchCountry(countryKey: regionCode) {
                    loginInputView.updateMobileRegion(regionCode: country.code)
            }
        }
    }

    func checkButtonDisable() {
        nextButton.isEnabled = loginInputView.checkButtonDisable()
        stopLoading()
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
                        self.showLoading()
                        self.vm.fetchPrepareTenantInfo().subscribe(onNext: { [weak self] (_) in
                            guard let self = self else { return }
                            self.stopLoading()
                        }, onError: { [weak self] (err) in
                            guard let self = self else { return }
                            self.handle(err)
                        }).disposed(by: self.disposeBag)
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

    override var bottomViewBottomConstraint: ConstraintItem {
        if vm.needBottomView {
            return moreLoginOptionLineView.snp.top
        } else {
            return super.bottomViewBottomConstraint
        }
    }

    override var keyboardShowBottomViewOffset: CGFloat {
        var offset = safeAreaBottom
        if vm.needBottomView {
            offset += moreLoginOptionLineView.frame.height
        }
        return offset
    }

    func updateCreadential() {
        vm.credentialPhone.accept(loginInputView.phoneTextField.text ?? "")
        vm.credentialRegionCode.accept(loginInputView.phoneTextField.labelText ?? "")
        vm.credentialEmail.accept(loginInputView.emailTextField.currentText ?? "")
    }

    override public func pageName() -> String? { vm.pageName }

    override func clickBackOrClose(isBack: Bool) {
        vm.trackClickBack()
        super.clickBackOrClose(isBack: isBack)
    }

    override func switchAction(sender: UIButton) {
        self.showLoading()
        self.vm.handleSwitchAction()
            .subscribe { [weak self](_) in
                guard let self = self else { return }
                self.stopLoading()
                self.logger.info("handleSwitchAction success")
            } onError: { [weak self](error) in
                self?.handle(error)
            }.disposed(by: disposeBag)
    }

    #if ONE_KEY_LOGIN
    func checkToOpen(completion: @escaping (() -> Void)) {
        guard !loginInputView.hadInteractive, !viewWillDisappear else {
            self.logger.warn("n_action_one_key_login: OneKeyLogin interrupted at beginning by user interaction")
            return
        }
        if vm.needOnekeyLogin {
            logger.info("n_action_one_key_login: OneKeyLogin checkToOpen start")
            PassportMonitor.flush(PassportMonitorMetaLogin.startOneKeyLoginPrepare,
                                    eventName: ProbeConst.monitorEventName,
                                    context: vm.context)
            ProbeDurationHelper.startDuration(ProbeDurationHelper.oneKeyLoginPrepareFlow)
            
            OneKeyLogin.oneKeyLoginVC(
                type: vm.process.value.oneKeyLoginType,
                loginService: vm.service,
                otherLoginAction: nil,
                result: { [weak self] (vc) in
                    guard let self = self else { return }
                    guard !self.loginInputView.hadInteractive, !self.viewWillDisappear else {
                        self.logger.warn("n_action_one_key_login: OneKeyLogin interrupted after fetched by user interaction")
                        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.oneKeyLoginPrepareFlow)
                        PassportMonitor.monitor(PassportMonitorMetaLogin.oneKeyLoginPrepareResult,
                                                eventName: ProbeConst.monitorEventName,
                                                categoryValueMap: [ProbeConst.duration: duration],
                                                context: UniContext(.login))
                        .setErrorCode("-1").setErrorMessage("n_action_one_key_login: OneKeyLogin interrupted after fetched by user interaction").setResultTypeFail().flush()
                        return
                    }
                    if let vc = vc {
                        // 一键登录场景必须使用.overCurrentContext
                        // 否则一键登录触发二次验证时，会在InputCredentialViewContrller，didAppear时，清除Passport-Token导致上下文过期回到登录页
                        self.customPresent(vc, phonePresentationStyle: .overCurrentContext) {
                            completion()
                        }
                        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.oneKeyLoginPrepareFlow)
                        PassportMonitor.monitor(PassportMonitorMetaLogin.oneKeyLoginPrepareResult,
                                                eventName: ProbeConst.monitorEventName,
                                                categoryValueMap: [ProbeConst.duration: duration],
                                                context: UniContext(.login))
                        .setResultTypeSuccess()
                        .flush()
                    } else{
                        self.logger.error("n_action_one_key_login: OneKeyLogin Failed to get oneKeyLoginVC")
                        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.oneKeyLoginPrepareFlow)
                        PassportMonitor.monitor(PassportMonitorMetaLogin.oneKeyLoginPrepareResult,
                                                eventName: ProbeConst.monitorEventName,
                                                categoryValueMap: [ProbeConst.duration: duration],
                                                context: UniContext(.login))
                        .setErrorCode("-2").setErrorMessage("n_action_one_key_login: OneKeyLogin Failed to get oneKeyLoginVC").setResultTypeFail().flush()
                        completion()
                    }
                },
                context: vm.context
            )
        } else {
            self.logger.warn("n_action_one_key_login: do not need OneKeyLogin. Info: ReleaseConfig: \(ReleaseConfig.isFeishu); fromUserCenter: \(vm.fromUserCenter)")
            completion()
        }
    }

    func checkOpenOneKeyLogin(completion: @escaping (() -> Void)) {
        OneKeyLogin.updateIsOneKeyLoginBeforeGuide(false)
        if OneKeyLogin.oneKeyLoginFirstPrefetched {
            checkToOpen(completion: completion)
        } else {
            self.logger.info("n_action_one_key_login: OneKeyLogin waiting for first prefetch", method: .local)
            NotificationCenter.default.rx.notification(.oneKeyLoginFirstPrefetched)
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    self.logger.info("n_action_one_key_login: OneKeyLogin first prefetch finished and go checkToOpen", method: .local)
                    self.checkToOpen(completion: completion)
                }).disposed(by: disposeBag)

            OneKeyLogin.updateSetting(oneKeyLoginConfig: vm.service.config.getOneKeyLoginConfig())
        }
    }
    #endif
}

// MARK: Setup 视图
extension V3InputCredentialViewController {
    func setupLogo() {
        inputAdjustView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.logoTop)
            make.leading.equalToSuperview().offset(CL.itemSpace)
            make.width.height.equalTo(Layout.logoWidth)
        }

        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(logoImageView.snp.bottom).offset(Layout.titleLabelTop)
            make.leading.equalToSuperview().offset(CL.itemSpace)
            make.trailing.lessThanOrEqualTo(moveBoddyView).inset(CL.itemSpace)
            make.height.greaterThanOrEqualTo(BaseLayout.titleLabelHeight)
        }
    }

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

    func setupInputView() {
        centerInputView.addSubview(loginInputView)
        loginInputView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
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
                make.top.equalTo(nextButton.snp.bottom).offset(Layout.policyTopSpace)
                make.left.equalTo(checkbox.snp.right).offset(CL.checkBoxRightPadding)
                make.right.equalToSuperview()
            }
            
            if needRegist {
                processTipLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(policyLabel.snp.bottom).offset(Layout.processTipTopSpaceWhenQRLogin)
                    make.left.equalTo(moveBoddyView).inset(CL.itemSpace)
                    make.right.lessThanOrEqualTo(moveBoddyView).inset(CL.itemSpace)
                    make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
                }
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

    func updateSwitchButtonLayout() {
        if needRegist {
            switchButtonContainer.snp.remakeConstraints { (make) in
                make.top.equalTo(processTipLabel.snp.bottom).offset(CL.itemSpace)
                make.left.right.equalTo(moveBoddyView)
                make.height.equalTo(0).priority(.low)   // 高度由内容撑 默认高度0
                make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
            }
        } else {
            switchButtonContainer.snp.remakeConstraints { (make) in
                make.top.equalTo(vm.needPolicyCheckbox ? policyLabel.snp.bottom : nextButton.snp.bottom).offset(CL.itemSpace)
                make.left.right.equalTo(moveBoddyView)
                make.height.equalTo(0).priority(.low)   // 高度由内容撑 默认高度0
                make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
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
            detailLabel.isHidden = true
            //隐藏 detailLabel 后, centerInputView 需要根据 titleLabel 重新布局.
            centerInputView.snp.remakeConstraints { (make) in
                make.top.equalTo(detailLabel.snp.bottom).offset(BaseLayout.centerInputTop2)
                make.left.right.equalTo(moveBoddyView)
                make.height.equalTo(0).priority(.low)   // 高度由内容撑 默认高度0
            }
        } else {
            detailLabel.isHidden = false
        }
        if needRegist {
            setupProcessTipLabel()
        }

        moveBoddyView.addSubview(policyLabel)
        if vm.needPolicyCheckbox {
            moveBoddyView.addSubview(checkbox)
        }
        if vm.needKeepLoginTip {
            moveBoddyView.addSubview(keepLoginLabel)
            moveBoddyView.addSubview(keepLoginCheckbox)
        }

        updatePolicyLayout()
        moveBoddyView.addSubview(nextButton)
        nextButton.snp.remakeConstraints { (make) in
            make.top.equalTo(centerInputView.snp.bottom).offset(CL.itemSpace)
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }
    }

    func setupProcessTipLabel() {
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

    func updateProcessLabelLocale() {
        processTipLabel.attributedText = vm.processTip
    }

    func updatePolicyLabelLocale() {
        policyLabel.attributedText = self.policyTip(
            isRegisterType: vm.process.value == .register
        )
    }

    func updateKeeyLoginLocale() {
        keepLoginLabel.attributedText = self.vm.keepLoginText
    }

    func updateViewLocale() {
        // 注意: 这里重新设置语言后，需要调用'设置字体的方法'以生效字体样式的变化
        nextButton.setTitle(I18N.Lark_Login_V3_NextStep, for: .normal)
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
        updateIdPButtonLocale()
        if vm.needKeepLoginTip {
            updateKeeyLoginLocale()
        }
        if vm.needBottomView {
            moreLoginOptionLineView.updateLocale()
        }
        if vm.needQRLogin {
            self.switchButton.setTitle(I18N.Lark_Login_TitleOfQRPage, for: .normal)
            self.switchButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        }
    }

    func setupBottomEnterpriseView() {
        if vm.needBottomView {
            moveBoddyView.addSubview(moreLoginOptionLineView)
            if vm.bottomActions.contains(.enterpriseLogin) {
                moreLoginOptionLineView
                    .enterpriseLoginButton
                    .rx
                    .tap
                    .subscribe(onNext: { [weak self] (_) in
                        guard let self = self else {
                            return
                        }
                        self.handleEnterpriseStep()
                    }).disposed(by: disposeBag)
            }
            if vm.bottomActions.contains(.joinTeam) {
                moreLoginOptionLineView
                    .joinTeamButton
                    .rx
                    .tap
                    .subscribe(onNext: { [weak self] (_) in
                        guard let self = self else { return }
                        self.doJoinType()
                    }).disposed(by: disposeBag)
            }
        }
    }

    func layoutBottomEnterpriseView() {
        if vm.needBottomView {
            moreLoginOptionLineView.snp.makeConstraints { (make) in
                make.top.equalTo(bottomView.snp.bottom)
                make.left.right.equalTo(moveBoddyView).inset(CL.itemSpace)
                make.bottom.equalToSuperview().offset(-MoreLoginOptionLineView.Layout.noJoinMettingBottomSapce)
            }
        }
    }

    func doJoinType() {
        logger.info("input credential click join team")
        showLoading()
        vm.trackClickJionTeam()
        vm.doJoinType().subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.stopLoading()
        }, onError: { [weak self] (err) in
            guard let self = self else { return }
            self.handlerError(err)
        }).disposed(by: disposeBag)
    }

    func buttonsToShow() -> [UIButton] {
        var result: [UIButton] = []
        if vm.resultSupportChannel.contains(.google) {
            result.append(idpGoogleButton)
        }
        if vm.resultSupportChannel.contains(.apple_id) {
            result.append(idpAppleButton)
        }
        return result
    }
    
    func updateIdPButtonLocale() {
        idpGoogleButton.setTitle(I18N.Lark_Passport_GoogleUserSignInOption_Google, for: .normal)
        idpGoogleButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        idpAppleButton.setTitle(I18N.Lark_Passport_GoogleUserSignInOption_Apple, for: .normal)
        idpAppleButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    }
}

// MARK: - LoginInputSegmentViewDelegateProtocol
extension V3InputCredentialViewController: LoginInputSegmentViewDelegateProtocol {
    func mobileCodeSelectClick() {
        self.logger.info("n_action_login_input_change_region_code")
        self.vm.trackSwitchCountryCode()
    }

    func selectedMobileCode(_ mobileCode: MobileCode) {
        vm.credentialRegionCode.accept(mobileCode.code)
        vm.trackSwitchRegionCode()
        checkButtonDisable()
    }

    func needUpdateButton(enable: Bool) {
        nextButton.isEnabled = enable
    }

    func inputMethodChange(method: SuiteLoginMethod) {
        vm.method.accept(method)
    }

    func didTapReturnButton() {
        guard loginInputView.checkButtonDisable() else { return }
        handleNextStep()
    }
}

// MARK: Label 点击
extension V3InputCredentialViewController {

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.registerURL:
            self.logger.info("n_action_login_input_register")
            vm.trackClickToRegister()
            self.view.endEditing(true)
            self.updateCreadential()

            self.showLoading()
            self.vm.fetchPrepareTenantInfo().subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.stopLoading()
            }, onError: { [weak self] (err) in
                guard let self = self else { return }
                self.handle(err)
            }).disposed(by: self.disposeBag)
        case Link.termURL, Link.privacyURL, Link.alertTermURL, Link.alertPrivacyURL:
            var openUrl: Foundation.URL?
            if URL == Link.termURL || URL == Link.alertTermURL {
                self.logger.info("n_action_login_input_policy", additionalData: ["type": "service term"])
                vm.trackClickServiceTerm(URL)
                let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.serviceTerm)
                if let urlString = urlValue.value {
                    openUrl = Foundation.URL(string: urlString)
                }
            } else {
                let urlValue = PassportConf.shared.serverInfoProvider.getUrl(.privacyPolicy)
                self.logger.info("n_action_login_input_policy", additionalData: ["type": "privacy policy"])
                vm.trackClickPrivacy(URL)
                if let urlString = urlValue.value {
                    openUrl = Foundation.URL(string: urlString)
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
extension V3InputCredentialViewController {

    @objc
    func switchLocaleButtonTapped() {
        vm.trackClickLocaleButton()
        self.logger.info("n_action_login_input_lang")
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

extension V3InputCredentialViewController {
    struct Layout {
        static let logoTop: CGFloat = 28
        static let logoWidth: CGFloat = 56
        static let titleLabelTop: CGFloat = 24
        static let policyLabelSpace: CGFloat = 16 // 不同的值影响 LKLabel 绘制
        static let policyTop: CGFloat = 10
        static let policyBottom: CGFloat = 10
        static let lanBtnTopSpace: CGFloat = 12.0
        static let lanBtnHeight: CGFloat = 22.5
        static let policyLabelPadding: CGFloat = 11
        static let processTipTopSpaceWhenQRLogin: CGFloat = 20
        static let policyTopSpace: CGFloat = 24
        static let checkBoxInsets: UIEdgeInsets = UIEdgeInsets(top: -40, left: -50, bottom: -20, right: -50)
    }
}

extension V3InputCredentialViewController: PassportPrivacyServicePolicyProtocol {
    var currentPolicyPresentVC: UIViewController { self }
}
