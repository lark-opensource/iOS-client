//
//  MailClientViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/23.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import RxRelay
import LarkNavigation
import LarkUIKit
import UniverseDesignIcon
import FigmaKit
import UniverseDesignTheme
import EENavigator
import LarkAlertController
import LarkReleaseConfig
import LarkLocalizations
import UniverseDesignColor
import UniverseDesignActionPanel
import UniverseDesignToast
import UniverseDesignDialog

enum MailClientScene {
    case normal
    case setting
    case newFreeBind
    case newFreeBindSetting
    
    var isFreeBind: Bool {
        switch self {
        case .newFreeBind, .newFreeBindSetting:
            return true
        default:
            return false
        }
    }
    
    var isSetting: Bool {
        switch self {
        case .setting, .newFreeBindSetting:
            return true
        default:
            return false
        }
    }
}

class MailClientViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate, MailClientVendorDelegate {
    private let cellHeight = 72.0
    private lazy var tableView = self.makeTabelView()
    private var titleLabel = UILabel()
    private lazy var datasource: [MailTripartiteProvider] = self.makeDatasource()
    weak var displayDelegate: TarBarDisplayDelegate?
    weak var navbarBridge: MailNavBarBridge?
    private let disposeBag = DisposeBag()
    private let scene: MailClientScene
    private let userContext: MailUserContext
    // Const
    private let navHeight: CGFloat = 44

    var displaying = false
    var didLoginSuccess = false
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgBody
    }
    private var isAppeared = false
    private var isFirstAppeared = true
    private var isRequestingPermit = false
    private lazy var gradientView = LinearGradientView()
    private lazy var footerView = MailFreeBindFooterView()

    private weak var currentGuideVC: MailClientOAuthGuideViewController?

    init(scene: MailClientScene = .normal, userContext: MailUserContext) {
        self.scene = scene
        self.userContext = userContext
        super.init(nibName: nil, bundle: nil)
        self.isNavigationBarHidden = true
        MailLogger.info("[mail_client] MailClientViewController scene: \(scene)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        userContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.displaying = true
        configViews()

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                if self.scene.isFreeBind {
                    if case .accountChange(let change) = push {
                        self.mailPrimaryAccountChange(change)
                    }
                } else {
                    if case .shareAccountChange(let change) = push {
                        self.mailSharedAccountChange(change)
                    }
                }
            }).disposed(by: disposeBag)

        if scene.isFreeBind {
            MailTracker.log(event: "email_mail_binding_view", params: [:])
        } else {
            MailTracker.log(event: !scene.isSetting ? "email_tripartite_service_select_view" : "email_tripartite_service_select_window_view", params: ["mail_account_type":  Store.settingData.getMailAccountType()])
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // to update view frame
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // update view along with animation
            self?.gradientView.frame = CGRect(x: 0, y: 0, width: size.width, height: 240)
        }, completion: { _ in             // update view after transition
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isAppeared = true
        if self.displaying {
            MailLogger.info("[mail_client_nav] viewDidAppear updateNavStatus false")
            self.getLarkNaviBar()?.isShown = false
            changeNaviBarPresentation(show: false, animated: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// 不能放在 viewDidLoad，不然会影响正在显示的 VC
        if isFirstAppeared {
            isFirstAppeared = false
            // 适配iOS 15 bartintcolor颜色不生效问题
            updateNavAppearanceIfNeeded()
        }
        self.getLarkNaviBar()?.isShown = false
        changeNaviBarPresentation(show: false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isAppeared = false
        if displaying {
            MailLogger.info("[mail_client_nav] viewWillDisappear updateNavStatus true")
            if self.scene.isSetting {
                changeNaviBarPresentation(show: true, animated: false)
                self.navigationController?.isNavigationBarHidden = false
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if scene.isFreeBind {
            configFooterView()
        }
    }

    func mailSharedAccountChange(_ change: MailSharedAccountChange) {
        MailLogger.info("[mail_client] change: \(change.account.mailAccountID), isBind: \(change.isBind)")
        if change.isBind {
            loginSuccess()
        }
    }

    func makeDatasource() -> [MailTripartiteProvider] {
        var providers: [MailTripartiteProvider] = []
        if scene.isFreeBind {
            if userContext.provider.configurationProvider?.isFeishuBrand == true {
                return feishuBindDataSource()
            } else {
                return larkBindDataSource()
            }
        } else if ReleaseConfig.isLark {
            let type: MailTripartiteProvider = .outlook
            if type.isTokenLogin() {
                providers = [.office365, .zoho, .outlook, .other]
            } else {
                providers = [.office365, .zoho, .other]
            }
            if userContext.featureManager.open(FeatureKey(fgKey: .mailClientOAuthLoginGmail, openInMailClient: true)) {
                providers.insert(.gmail, at: 1)
            }
        } else {
            providers = [.office365, .exchangeOnPrem, .tencent, .netEase, .ali, .coreMail, .other]
        }
        return providers
    }

    private func feishuBindDataSource() -> [MailTripartiteProvider] {
        return [.office365, .tencent, .netEase, .ali, .other]
    }

    private func larkBindDataSource() -> [MailTripartiteProvider] {
        var providers: [MailTripartiteProvider] = []
        if userContext.featureManager.realTimeOpen(.newFreeBindGMail, openInMailClient: false) {
            providers.append(.gmail)
        }
        if userContext.featureManager.realTimeOpen(.newFreeBindExchange, openInMailClient: false) {
            providers.append(.office365)
        }

        providers.append(contentsOf: [.tencent, .ali, .zoho])

        if userContext.featureManager.realTimeOpen(.newFreeBindIMAP, openInMailClient: false) {
            providers.append(.other)
        }
        return providers
    }

    func configViews() {
        view.backgroundColor = UIColor.ud.bgBody

        gradientView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 240)
        gradientView.direction = .topToBottom
        let upColor = UIColor.mail.rgb("#E3EBFC") & UIColor.mail.rgb("#121429")
        let downColor = UIColor.mail.rgb("#FFFFFF") & UIColor.mail.rgb("#191919")
        gradientView.colors = [upColor, downColor]
        view.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(240)
        }

        let imageView = UIImageView()
        imageView.image = Resources.image(named: "bg_light")
        imageView.frame = gradientView.frame
        view.addSubview(imageView)

        let titleLabel = UILabel()
        titleLabel.text = scene.isFreeBind
        ? BundleI18n.MailSDK.Mail_LinkYourBusinessEmailToLark_Mobile_Text
        : BundleI18n.MailSDK.Mail_ThirdClient_AddEmailAccounts
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)
        if Display.pad {
            titleLabel.snp.makeConstraints { make in
                make.width.equalTo(343)
                make.top.equalTo(view.safeAreaLayoutGuide).inset(navHeight)
                make.centerX.equalToSuperview()
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                make.left.equalTo(24)
                make.top.equalTo(view.safeAreaLayoutGuide).inset(navHeight + 20)
                make.right.equalTo(-24)
            }
        }
        titleLabel.sizeToFit()

        view.addSubview(tableView)
        let tablePadding: CGFloat = scene.isFreeBind ? 18 : 24
        if Display.pad {
            tableView.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(tablePadding)
                make.centerX.equalToSuperview()
                make.width.equalTo(400)
                let bottomOffset = scene == .normal ? animatedTabBarController?.tabbarHeight ?? 0 : 0
                make.bottom.equalTo(-bottomOffset)
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(tablePadding)
                make.left.right.equalToSuperview()
                let bottomOffset = scene == .normal ? animatedTabBarController?.tabbarHeight ?? 0 : 0
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 52, right: 0)

        if scene.isSetting {
            setupCustomNavBar()
        }
        setupHelpBtnOnNav()
    }

    func configFooterView() {
        let contentHeight = cellHeight * CGFloat(self.tableView.numberOfRows(inSection: 0))
        let visibleHeight = self.tableView.bounds.height
        guard visibleHeight > 0 else { return }
        let width = tableView.bounds.width
        if visibleHeight - contentHeight > 60 {
            self.footerView.changeStyle(.normal)
            let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                                                          withHorizontalFittingPriority: .required,
                                                          verticalFittingPriority: .fittingSizeLevel)
            if self.tableView.tableFooterView == nil {
                self.footerView.removeFromSuperview()
                footerView.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
                self.tableView.tableFooterView = footerView
            } else if !footerView.frame.size.equalTo(size) {
                footerView.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
                self.tableView.tableFooterView = nil
                footerView.removeFromSuperview()
                self.tableView.tableFooterView = footerView
            }
        }
        else {
            self.footerView.changeStyle(.gradient)
            guard footerView.superview != self.view else { return }
            let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                                                          withHorizontalFittingPriority: .required,
                                                          verticalFittingPriority: .fittingSizeLevel)
            self.tableView.tableFooterView = nil
            footerView.removeFromSuperview()
            self.view.addSubview(footerView)
            footerView.snp.makeConstraints { make in
                make.left.equalTo(self.tableView.snp.left)
                make.right.equalTo(self.tableView.snp.right)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: size.height, right: 0)
        }

    }

    func setupHelpBtnOnNav() {
        guard !scene.isFreeBind else { return }
        let text = BundleI18n.MailSDK.Mail_ThirdClient_HelpDocsMobile
        let font = UIFont.systemFont(ofSize: 14)
        let helpBtn = UIButton(type: .custom)
        helpBtn.setImage(UDIcon.maybeOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        helpBtn.setTitle(text, for: .normal)
        helpBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        helpBtn.setTitleColor(UIColor.ud.textCaption, for: .normal)
        helpBtn.tintColor = UIColor.ud.iconN2
        helpBtn.addTarget(self, action: #selector(openHelpGuide), for: .touchUpInside)
        let textWidth = text.getWidth(font: font)
        let btnWidth = 20 + textWidth
        let viewRect = self.view.frame
        helpBtn.frame = CGRect(x: viewRect.width - 16 - btnWidth, y: Display.realStatusBarHeight() + 12, width: btnWidth, height: 20)
        helpBtn.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: textWidth + 4)
        helpBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        view.addSubview(helpBtn)
        helpBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.width.equalTo(btnWidth)
            make.height.equalTo(20)
            make.right.equalToSuperview().offset(-16)
        }
    }

    func setupCustomNavBar() {
        let naviBar = UIView()
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.width.left.equalToSuperview()
            make.height.equalTo(navHeight)
        }

        let backButton = UIButton(type: .custom)
        backButton.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = UIColor.ud.iconN1
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        naviBar.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview().offset(-4)
        }
    }

    @objc
    func back() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func openHelpGuide() {
        guard let json = ProviderManager.default.commonSettingProvider?.originalSettingValue(configName: .mailClientURLKey),
              let data = json.data(using: .utf8),
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let urlDict = jsonDict["third_client_login_help_center_url"] as? [String: String] else {
            return
        }
        var link: String
        if LanguageManager.currentLanguage == .zh_CN || LanguageManager.currentLanguage == .zh_HK || LanguageManager.currentLanguage == .zh_TW {
            link = urlDict["cn"] ?? ""
        } else {
            link = urlDict["en"] ?? ""
        }
        if !link.isEmpty, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    func vendorBtnClick(type: MailTripartiteProvider) {
        if scene.isFreeBind {
            showFreeBindTipsIfNeed { [weak self] in
                self?.gotoFreeBind(type: type)
            }

        } else if type == .office365 && !type.isEASLogin() {
            let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
            pop.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_ChooseVersion_title, font: UIFont.systemFont(ofSize: 14.0))
            pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_ThirdClient_Office365Microsoft_option) { [weak self] in
                guard let `self` = self else { return }
                self.loginTripartiteHandler(type)
            }
            pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_ThirdClient_Office365China_option) { [weak self] in
                guard let `self` = self else { return }
                self.loginTripartiteHandler(.office365Cn)
            }
            pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel) {
                MailLogger.info("Cancel selected login office365")
            }
            userContext.navigator.present(pop, from: self)
        } else {
            loginTripartiteHandler(type)
        }
    }
    
    func gotoFreeBind(type: MailTripartiteProvider) {
        switch type {
        case .gmail:
            showFreeBindTipsIfNeed { [weak self] in
                self?.handleOAuthURLLogin(type: .google)
            }
        case .office365:
            handleOffice365FreeBind()
        case .tencent, .ali, .zoho, .netEase, .other:
            handleIMAPLogin(vendorType: type)
        @unknown default:
            mailAssertionFailure("Mail bind type not handle: \(type.rawValue)")
        }
        MailTracker.log(event: "email_mail_binding_click", params: ["click": type.bindType])
    }

    func loginTripartiteHandler(_ type: MailTripartiteProvider) {
        let name = scene == .normal ? "email_tripartite_service_select_click" : "email_tripartite_service_select_window_click"
        var params = ["mail_account_type":  Store.settingData.getMailAccountType(), "click": "mail_service", "target": "none"]
        if scene == .normal {
            params["mail_service_name"] = type.config().0
        }
        MailTracker.log(event: name, params: params)
        if type.isEASLogin() {
            let loginVC = MailClientLoginViewController(type: type, accountContext: userContext.getCurrentAccountContext(), scene: .eas)
            loginVC.delegate = self
            loginVC.supportSecondaryOnly = true
            navigator?.push(loginVC, from: self)
        } else if type.isTokenLogin() {
            Store.settingData.tokenRelink(provider: type, navigator: userContext.navigator, from: self)
        } else {
            let loginVC = MailClientLoginViewController(type: type, accountContext: userContext.getCurrentAccountContext(), scene: .imap)
            loginVC.delegate = self
            loginVC.supportSecondaryOnly = true
            navigator?.push(loginVC, from: self)
        }
    }

    func makeTabelView() -> UITableView {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = .zero
        tableView.lu.register(cellSelf: MailClientVendorCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MailClientVendorCell.lu.reuseIdentifier) as? MailClientVendorCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        cell.configVendor(datasource[indexPath.row])
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}

// MARK: - Free Bind

extension MailClientViewController {
    func mailPrimaryAccountChange(_ change: MailAccountChange) {
        let userType = change.account.mailSetting.userType
        MailLogger.info("[mail_client] account change: \(change.account.mailAccountID), user type: \(userType.rawValue)")
        if userType == .oauthClient {
            loginSuccess()
        }
    }
    
    func handleOAuthURLLogin(type: MailOAuthURLType) {
        guard !isRequestingPermit else { return }
        isRequestingPermit = true
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Label_Loading, on: view)
        MailDataServiceFactory.commonDataService?
            .getGoogleOrExchangeOauthUrl(type: type, emailAddress: nil, fromVC: self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (url, denied, _) in
                guard let self = self else { return }
                if !denied {
                    MailRoundedHUD.remove(on: self.view)
                }
                defer { self.isRequestingPermit = false }
                guard let oauthURL =  URL(string: url) else {
                    MailLogger.error("[mail_client] cannot init url from: \(url)")
                    return
                }
                UIApplication.shared.open(oauthURL)
                if self.userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                    let model = MailClientOAuthGuideViewModel.defaultAuthModel(url: oauthURL, type: type)
                    let vc = MailClientOAuthGuideViewController(model: model) { [weak self] in
                        self?.currentGuideVC = nil
                    }
                    vc.modalPresentationStyle = .overFullScreen
                    self.navigator?.present(vc, from: self, animated: false)
                    self.currentGuideVC = vc
                }
                switch type {
                case .google:
                    MailTracker.log(event: "email_google_waiting_binding_view", params: [:])
                case .exchange:
                    MailTracker.log(event: "email_office_365_waiting_binding_view", params: [:])
                @unknown default:
                    break
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view)
                self.isRequestingPermit = false
                MailLogger.error("[mail_client] Fail to get OAuth URL, error: \(error)")
            }).disposed(by: disposeBag)
    }
    
    func handleIMAPLogin(vendorType: MailTripartiteProvider) {
        guard !isRequestingPermit else { return }
        isRequestingPermit = true
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Label_Loading, on: view)
        MailDataServiceFactory
            .commonDataService?
            .checkCanUserBindImap(fromVC: self)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] canBind in
                guard let self = self else { return }
                defer { self.isRequestingPermit = false }
                guard canBind else {
                    MailLogger.info("[mail_client] cannot bind IMAP")
                    return
                }
                MailRoundedHUD.remove(on: self.view)
                let loginVC = MailClientLoginViewController(
                    type: vendorType,
                    accountContext: self.userContext.getCurrentAccountContext(),
                    scene: .freeBind
                )
                loginVC.supportSecondaryOnly = true
                loginVC.delegate = self
                self.navigator?.push(loginVC, from: self)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view)
                self.isRequestingPermit = false
                MailLogger.error("[mail_client] Fail to get IMAP availability, error: \(error)")
            }).disposed(by: disposeBag)
    }

    func handleOffice365FreeBind() {
        if userContext.provider.configurationProvider?.isFeishuBrand == true {
            let loginVC = MailClientLoginViewController(
                type: .office365,
                accountContext: self.userContext.getCurrentAccountContext(),
                scene: .freeBind
            )
            loginVC.supportSecondaryOnly = true
            loginVC.delegate = self
            self.navigator?.push(loginVC, from: self)
        } else {
            self.handleOAuthURLLogin(type: .exchange)
        }
    }
    
    private func showFreeBindTipsIfNeed(gotoLogin: @escaping () -> Void) {
        if scene.isFreeBind && !footerView.checkboxSelected {
            var dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.MailSDK.Mail_Login_LoginNotice_Title)
            dialog.setContent(text: BundleI18n.MailSDK.Mail_Login_LoginNotice_Desc())
            dialog.addButton(text: BundleI18n.MailSDK.Mail_Login_LoginNotice_IUnderstand_Button, dismissCompletion: {[weak self] in
                self?.footerView.checkboxSelected = true
                gotoLogin()
            })
            dialog.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Login_LoginNotice_Cancel_Button)
            self.present(dialog, animated: true)
        } else {
            gotoLogin()
        }
    }
}

extension MailClientViewController: MailClientLoginDelegate {
    func loginSuccess() {
        /// 防止多次走切换 home 流程
        guard !didLoginSuccess else {
            MailLogger.info("[mail_client] already login success once vc scene: \(self.scene)")
            return
        }
        didLoginSuccess = true
        currentGuideVC?.dismiss(animated: false)
        currentGuideVC = nil
        MailLogger.info("[mail_client] change, vc scene: \(self.scene)")
        if !self.scene.isSetting, (self.presentedViewController as? MailClientViewController) != nil {
            guard let navigationController = self.navigationController else { return }
            if let tabVC = navigationController.viewControllers.first {
                self.navigationController?.viewControllers = [tabVC]
            }
        }
        if self.scene.isSetting {
            dismissSelf(delay: true, completion: { [weak self] in
                self?.displayDelegate?.switchContent(inHome: true, insert: false, initData: false)
            })
        } else {
            self.dismissTopViewControllersIfNeed { [weak self] in
                self?.displayDelegate?.switchContent(inHome: true, insert: false, initData: false)
            }
        }
    }

    func dismissSelf(delay: Bool = false, completion: (() -> Void)? = nil) {
        let duration = delay ? 0.3 : 0 // 展示全局loadingvc也需要dismiss，会导致控制器连续dimiss，其中一个失败，所以此场景需要延迟执行
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: { [weak self] in
            guard let `self` = self else { return }
            if self.presentingViewController != nil {
                self.popSelf()
                self.closeBtnTapped()
            } else {
                self.backItemTapped()
            }
            completion?()
        })
    }
    
    func dismissTopViewControllersIfNeed(completion: @escaping (() -> Void)) {
        guard let topVC = self.navigationController?.topViewController, topVC != self, !topVC.isKind(of: MailSettingViewController.self) else {
            completion()
            return
        }
        if let presentedVC = topVC.presentedViewController {
            presentedVC.dismiss(animated: false) {
                topVC.popSelf()
                completion()
            }
        } else {
            topVC.popSelf()
            completion()
        }
    }
}

extension MailClientViewController: MailNavBarDatasource, MailNavBarBridge {
    func customTitleArrowView(titleColor: UIColor) -> UIView? {
        return nil
    }

    var navbarShowLoading: BehaviorRelay<Bool> {
        return BehaviorRelay(value: false)
    }

    var navbarEnable: Bool {
        return false
    }

    var navbarTitle: BehaviorRelay<String> {
        return BehaviorRelay(value: "")
    }

    var navbarSubTitle: BehaviorRelay<String?> {
        return BehaviorRelay(value: nil)
    }

    func navbar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        return nil
    }

    func navbar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        return nil
    }

    func setNavBarBridge(_ bridge: MailNavBarBridge) {
        navbarBridge = bridge
    }

    // MailNavBarBridge
    func changeLarkNaviBarTitleArrow(folded: Bool?, animated: Bool) {}
    func getLarkNaviBar() -> LarkNaviBar? {
        navbarBridge?.getLarkNaviBar()
    }

    func reloadLarkNaviBar() {
        navbarBridge?.reloadLarkNaviBar()
    }
}
