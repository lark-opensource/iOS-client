//
//  AuthorizationRiskReminderViewController.swift
//  LarkAccount
//
//  Created by au on 2023/05/09.
//


import EEAtomic
import LarkUIKit
import LKCommonsLogging
import SnapKit
import RxSwift
import UIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignTheme
import UniverseDesignToast

/// 扫码/免密登录遭遇风险提示
final class AuthorizationRiskReminderViewController: UIViewController {

    static let logger = Logger.plog(AuthorizationRiskReminderViewController.self, category: "LarkAccount")

    private let vm: AuthorizationRiskReminderViewModel
    
    lazy var topGradientMainCircle = GradientCircleView()
    lazy var topGradientSubCircle = GradientCircleView()
    lazy var topGradientRefCircle = GradientCircleView()
    lazy var blurEffectView = UIVisualEffectView()

    init(vm: AuthorizationRiskReminderViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }

        let isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        setGradientLayerColors(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if Display.pad {
            preferredContentSize = CGSize(width: 540, height: 595)
        }

        setupViews()
        trackViewLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if countdown <= 0 || timer != nil {
            return
        }

        timer = CADisplayLink(target: self, selector: #selector(updateConfirmButton))
        timer?.add(to: .current, forMode: .default)
        timer?.preferredFramesPerSecond = 1
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if timer != nil {
            invalidateTimer()
        }
        guard let vc = presentingViewController as? AuthorizationBaseViewController else { return }
        vc.dismiss(animated: true)
    }

    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgLogin

        setupBackgroudHeader()
        setupActionButtons()
        setupInfoView()
        setupNavigation(needTitle: Display.pad)
    }

    // 背景图片和渐变样式
    private func setupBackgroudHeader() {
        guard !Display.pad else { return }
        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        self.view.addSubview(topGradientMainCircle)
        self.view.addSubview(topGradientSubCircle)
        self.view.addSubview(topGradientRefCircle)
        topGradientMainCircle.snp.makeConstraints { (make) in
            make.left.equalTo(-40.0 / 375 * view.frame.width)
            make.top.equalTo(0.0)
            make.width.equalToSuperview().multipliedBy(120.0 / 375)
            make.height.equalToSuperview().multipliedBy(96.0 / 812)
        }
        topGradientSubCircle.snp.makeConstraints { (make) in
            make.left.equalTo(-16.0 / 375 * view.frame.width)
            make.top.equalTo(-112.0 / 812 * view.frame.height)
            make.width.equalToSuperview().multipliedBy(228.0 / 375)
            make.height.equalToSuperview().multipliedBy(220.0 / 812)
        }
        topGradientRefCircle.snp.makeConstraints { (make) in
            make.left.equalTo(150.0 / 375 * view.frame.width)
            make.top.equalTo(-22.0 / 812 * view.frame.height)
            make.width.equalToSuperview().multipliedBy(136.0 / 375)
            make.height.equalToSuperview().multipliedBy(131.0 / 812)
        }
        self.view.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        setGradientLayerColors(isDarkModeTheme: isDarkModeTheme)
    }
    
    private func setGradientLayerColors(isDarkModeTheme: Bool) {
        topGradientMainCircle.setColors(color: UIColor.ud.rgb("#1456F0"), opacity: 0.16)
        topGradientSubCircle.setColors(color: UIColor.ud.rgb("#336DF4"), opacity: 0.16)
        topGradientRefCircle.setColors(color: UIColor.ud.rgb("#2DBEAB"), opacity: 0.10)
        blurEffectView.effect = isDarkModeTheme ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
    }

    private func setupNavigation(needTitle: Bool) {
        guard needTitle else { return }
        let titleLabel = UILabel()
        titleLabel.text = vm.stepInfo.suiteInfo.title
        titleLabel.font = UDFont.title3
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(24)
        }
    }

    private func setupInfoView() {
        let infoContainerView = UIView()
        infoContainerView.backgroundColor = .clear
        view.addSubview(infoContainerView)
        infoContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(64)
            if let button = self.actionButtonList.first {
                make.bottom.equalTo(button.snp.top).offset(-24)
            } else {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            }
        }

        infoContainerView.addSubview(infoView)
        infoView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.center.equalToSuperview()
        }
    }

    private func setupActionButtons() {
        guard let buttonList = vm.stepInfo.buttonList, !buttonList.isEmpty else {
            return
        }

        var actionButtons = [NextButton]()
        // reversed 后，从底往上排
        Array(buttonList.reversed()).enumerated().forEach { (index, buttonInfo) in
            let style: NextButton.Style = getButtonStyle(index, buttonType: buttonInfo.actionType ?? .unknown)
            let button = NextButton(title: buttonInfo.text, style: style)
            button.addTarget(self, action: #selector(onActionButtonTapped(_:)), for: .touchUpInside)
            view.addSubview(button)

            let section = CGFloat(index) * (48.0 + 10.0) // button height + spacing
            let basePadding: CGFloat = Display.pad ? 16.0 : 8.0
            let bottomOffset: CGFloat = -basePadding - section
            
            button.snp.makeConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(bottomOffset)
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(48)
            }
            
            actionButtons.append(button)

            if case .qrLoginRiskContinue = buttonInfo.actionType {
                riskConfirmButton = button
                riskConfirmButton?.isEnabled = false
            }
        }
        
        actionButtonList = Array(actionButtons.reversed())
        actionButtonList.enumerated().forEach { (index, button) in
            button.tag = index
        }
    }

    private func getButtonStyle(_ index: Int, buttonType: ActionIconType) -> NextButton.Style {
        let count = vm.stepInfo.buttonList?.count ?? 0
        // 继续授权按钮使用警示红色；如果下发其它按钮，第一个用主题蓝色
        if (index == (count - 1)) {
            if case .qrLoginRiskContinue = buttonType {
                return .roundedRectRed
            } else {
                return .roundedRectBlue
            }
        }
        return .roundedRectWhiteWithGrayOutline
    }
    
    @objc
    private func onActionButtonTapped(_ sender: NextButton) {

        func setRiskConfirmButtonEnable(_ enable: Bool) {
            DispatchQueue.main.async {
                self.riskConfirmButton?.isEnabled = enable
            }
        }

        let tag = sender.tag
        guard let buttonList = vm.stepInfo.buttonList,
              tag < buttonList.count else {
            Self.logger.error("n_action_guide_dialog", body: "tag incorrect")
            return
        }
        let buttonInfo = buttonList[tag]
        if case .qrLoginRiskContinue = buttonInfo.actionType ?? .unknown {
            setRiskConfirmButtonEnable(false)
        }
        switch buttonInfo.actionType {
        case .qrLoginRiskContinue:
            Self.logger.info("n_action_auth_risk_reminder: tap qrLoginRiskContinue")
            confirmToken(success: {
                setRiskConfirmButtonEnable(true)
            }, failure: {
                setRiskConfirmButtonEnable(true)
            })
            trackClick(isConfirm: true)
        case .qrLoginRiskCancel:
            Self.logger.info("n_action_auth_risk_reminder: tap qrLoginRiskCancel")
            vm.closeWork(authorizationPageType: nil)
            trackClick(isConfirm: false)
            dismiss(animated: true)
        default:
            Self.logger.warn("n_action_auth_risk_reminder: tap unknown type")
            return
        }
    }

    @objc
    private func updateConfirmButton() {
        guard let buttonInfo = vm.stepInfo.buttonList?.first(where: { $0.actionType == .qrLoginRiskContinue }) else {
            riskConfirmButton?.title = ""
            return
        }
        DispatchQueue.main.async {
            self.riskConfirmButton?.setTitle(self.getButtonTitle(buttonInfo: buttonInfo), for: [])
            if self.countdown >= 0 {
                self.countdown = self.countdown - 1
            }
            if self.countdown < 0 {
                self.invalidateTimer()
                self.riskConfirmButton?.isEnabled = true
            }
        }
    }

    private func getButtonTitle(buttonInfo: V4ButtonInfo) -> String {
        guard let type = buttonInfo.actionType else {
            return buttonInfo.text
        }
        if case .qrLoginRiskContinue = type {
            let title: String
            if countdown > 0 {
                title = "\(buttonInfo.text)\(I18N.Lark_PassportLoginPage_EnvironmentUnsafeConfirmPage_AuthorizeCountdown(countdown))"
            } else {
                title = buttonInfo.text
            }
            return title
        }
        return buttonInfo.text
    }

    private func confirmToken(success: @escaping () -> Void, failure: @escaping () -> Void) {
        // 遗留参数
        let scope = ""
        let hud = UDToast.showDefaultLoading(on: PassportNavigator.getUserScopeKeyWindow(userResolver: vm.userResolver) ?? self.view)
        vm.confirm(scope: scope, isMultiLogin: vm.isMultiLogin)
            .subscribe { [weak self] jump in
                guard let self = self else { return }
                hud.remove()
                success()
                switch jump {
                case .bundleId(_):
                    // 原bundleid逻辑使用私有api，v6.1起使用url scheme跳转
                    assertionFailure("Open app via bundle id was deprecated, should use scheme.")
                    Self.logger.info("n_action_auth_risk_reminder: open app via bundle id was deprecated, should use scheme.")
                case .scheme(let url):
                    if let url = URL(string: url) {
                        Self.logger.info("n_action_auth_risk_reminder: login auth success jump to \(url)")
                        UIApplication.shared.open(url) { (_) in
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        Self.logger.errorWithAssertion("n_action_auth_risk_reminder: no url for scheme jump")
                        self.dismiss(animated: true, completion: nil)
                    }
                case .none(let needDismiss):
                    if needDismiss {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } onError: { [weak self] error in
                guard let self = self else { return }
                hud.remove()
                failure()
                self.errorHandle(error: error)
            }
            .disposed(by: disposeBag)
    }

    private func errorHandle(error: Error, closeAlertHandle: @escaping () -> Void = {}) {
        var errorInfo: String
        if let error = error.underlyingError as? QRCodeError {
            switch error.type {
            case .networkIsNotAvailable:
                errorInfo = I18N.Lark_Legacy_NetworkOrServiceError
            default:
                errorInfo = error.displayMessage
            }
        } else if let error = error as? V3LoginError, case .badServerCode(let info) = error {
            errorInfo = info.message
        } else {
            errorInfo = error.localizedDescription
        }
        Self.logger.error("n_action_auth_risk_reminder:login auth fail errorInfo: \(errorInfo)")
        showToast(errorInfo)
    }

    private func showToast(_ message: String, on parent: UIView? = nil) {
        guard !message.isEmpty else { return }
        DispatchQueue.main.async {
            var toShowTipsView: UIView? = parent
            if toShowTipsView == nil {
                toShowTipsView = self.view
            }
            let config = UDToastConfig(toastType: .error, text: message, operation: nil)
            if let toShowView = toShowTipsView {
                UDToast.showToast(with: config, on: toShowView)
            } else {
                guard let mainSceneWindow = PassportNavigator.keyWindow else {
                    Self.logger.errorWithAssertion("no main scene for showToast")
                    return
                }
                UDToast.showToast(with: config, on: mainSceneWindow)
            }
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func trackViewLoad() {
        let info = vm.stepInfo
        // 扫码或免密
        let key = (info.qrSource == "qr_code" || info.qrSource == "qr_scan") ? "passport_qr_login_risk_confirm_view" : "passport_disposable_login_risk_confirm_view"
        SuiteLoginTracker.track(key)
    }

    private func trackClick(isConfirm: Bool) {
        let info = vm.stepInfo
        let key = (info.qrSource == "qr_code" || info.qrSource == "qr_scan") ? "passport_qr_login_risk_confirm_click" : "passport_disposable_login_risk_confirm_click"
        let click = isConfirm ? "go_on" : "cancel"
        let target = "none"
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: "", click: click, target: target)
        SuiteLoginTracker.track(key, params: params)
    }

    private var actionButtonList = [NextButton]()
    private var riskConfirmButton: NextButton?

    private lazy var infoView: RiskRemindView = {
        let descList = [vm.stepInfo.riskBlockInfo.location ?? "",
                        vm.stepInfo.riskBlockInfo.deviceType ?? "",
                        vm.stepInfo.riskBlockInfo.deviceName ?? ""]
        let view = RiskRemindView(title: vm.stepInfo.suiteInfo.subtitle, subtitle: vm.stepInfo.suiteInfo.tips ?? "", descList: descList)
        return view
    }()

    private var timer: CADisplayLink?

    @AtomicObject
    private var countdown = 5

    private let disposeBag = DisposeBag()
}
