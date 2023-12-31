//
//  MailClientImportViewController.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/11/13.
//

import UIKit
import LarkButton
import RustPB
import RxSwift
import EENavigator
import SnapKit
import LarkUIKit
import LarkReleaseConfig

@objc
enum ImportViewButtonType: Int {
    case googleOauthBtn = 0
    case oauthDelinkBtn = 1
}

class MailClientImportViewController: MailBaseViewController, UIViewControllerTransitioningDelegate {

    private let disposeBag = DisposeBag()

    private var viewType: OAuthViewType = .typeNewUserOnboard {
        didSet {
            setupViews()
        }
    }

    weak var delegate: MailMultiAccountViewDelegate? // MailClientImportViewControllerDelegate?
    weak var displayDelegate: TarBarDisplayDelegate?
    weak var currentGuideVC: MailClientOAuthGuideViewController?

    var showMultiAccount = false

    var isGmailReachable = true

    var oauthURL = ""
    
    let userContext: MailUserContext
    
    init(userContext: MailUserContext) {
        self.userContext = userContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordMailState = false
    }

    override var serviceProvider: MailSharedServicesProvider? {
        userContext
    }

    func setupViewType(viewType: OAuthViewType) {
        self.viewType = viewType
    }

    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        view.subviews.forEach { $0.removeFromSuperview() }

        if viewType == OAuthViewType.typeLoading {
            self.loadingPlaceholderView.isHidden = false
            self.retryLoadingView.isHidden = true
        } else if viewType == OAuthViewType.typeLoadingFailed {
            self.loadingPlaceholderView.isHidden = true
            self.retryLoadingView.isHidden = false
            self.retryLoadingView.retryAction = {
                NotificationCenter.default.post(name:
                Notification.Name.Mail.MAIL_LOADING_VIEW_FAILED, object: nil, userInfo: nil)
            }
        } else {
            self.loadingPlaceholderView.isHidden = true
            self.retryLoadingView.isHidden = true

            view.addSubview(multiAccountView)
            multiAccountView.isHidden = true
            multiAccountView.delegate = self
            multiAccountView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(realTopBarHeight)
                make.height.equalTo(showMultiAccount ? 40: 0)
            }
            MailLogger.info("init oauth view with type: \(viewType)")
            let importView = viewType.view(primaryButtonTappedBlock: { [weak self]  buttonType in
                guard let `self` = self else { return }
                if self.viewType == .typeExchangeOnboard {
                    self.handleImportButtonClick(type: .exchange, buttonType: buttonType)
                } else if self.viewType == .typeApiOnboard {
                    self.handleApiBtnClick()
                } else {
                    self.handleImportButtonClick(type: .google, buttonType: buttonType)
                }
            }, policyTappedBlock: { [weak self] policyType in
                guard let `self` = self else { return }
                if let url = policyType.url {
                    UIApplication.shared.openURL(url)
                }
            }, showDisclaimerView: ReleaseConfig.isLark && viewType == .typeNewUserOnboard)
            view.addSubview(importView)
            importView.snp.makeConstraints { maker in
                maker.top.equalTo(multiAccountView.snp.bottom)
                maker.leading.trailing.equalToSuperview()
                if viewType == .typeOauthExpired {
                    maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                } else {
                    maker.bottom.equalToSuperview()
                }
            }
        }
    }

    func showMultiAccount(address: String, showBadge: (count: Int64, isRed: Bool)) {
        showMultiAccount = true
        if multiAccountView.superview == view {
            MailLogger.info("mail oauth page show multi account")
            multiAccountView.isHidden = false
            multiAccountView.update(address: address, showBadge: showBadge)
            self.multiAccountView.snp.updateConstraints { (make) in
               make.height.equalTo(MailThreadListConst.mulitAccountViewHeight)
            }
            self.view.layoutIfNeeded()
        }
    }

    func hideMultiAccount() {
        showMultiAccount = false
        if multiAccountView.superview == view {
            MailLogger.info("mail oauth page hide multi account")
            multiAccountView.isHidden = true
            multiAccountView.snp.updateConstraints { (make) in
               make.height.equalTo(0)
            }
            view.layoutIfNeeded()
        }
    }

    lazy private var multiAccountView: MailMultiAccountView = {
        let view = MailMultiAccountView()
        view.clipsToBounds = true
        return view
    }()

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented is LkNavigationController {
            return MailCustomPresentationController(presentedViewController: presented, presenting: presenting)
        } else {
            return nil
        }
    }
}

extension MailClientImportViewController: MailMultiAccountViewDelegate {
    func didReverifySuccess() {
        self.delegate?.didReverifySuccess()
    }

    func didClickMultiAccount() {
        self.delegate?.didClickMultiAccount()
    }
}

// MARK: action handler
extension MailClientImportViewController {
    func handleApiBtnClick() {
        Store.settingData.updateCurrentSettings(.showApiOnboarding, onSuccess: nil)
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_HIDE_API_ONBOARDING_PAGE, object: nil)
    }
    func handleImportButtonClick(type: MailOAuthURLType, buttonType: ImportViewButtonType) {
        switch buttonType {
        case .googleOauthBtn:
            guard let account = Store.settingData.getCachedPrimaryAccount() else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed,
                                           on: self.view)
                MailLogger.error("Fail to get current cached primary account")
                return
            }
            let mailType = account.mailSetting.emailClientConfigs.first?.mailType
            let isFreeBind = userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) && account.mailSetting.userType == .oauthClient
            if isFreeBind, mailType == .imap {
                let loginVC = MailClientLoginViewController(type: .other, accountContext: userContext.getCurrentAccountContext(), scene: .freeBindInvaild)
                let loginNav = LkNavigationController(rootViewController: loginVC)
                var imapAccount = MailImapAccount(mailAddress: "", password: "", bindType: .reBind)
                if let config = account.mailSetting.emailClientConfigs.first {
                    imapAccount.mailAddress = config.emailAddress
                }
                loginVC.imapAccount = imapAccount
                loginNav.modalPresentationStyle = Display.pad ? .formSheet : .custom
                loginNav.transitioningDelegate = self
                loginVC.dismissCompletion = { [weak self] success in
                    guard success else { return }
                    self?.delegate?.didReverifySuccess()
                }
                self.navigator?.present(loginNav, from: self)
            } else {
                var type = type
                if isFreeBind {
                    type = mailType == .gmail ? .google : .exchange
                }
                MailDataServiceFactory
                .commonDataService?
                .getGoogleOrExchangeOauthUrl(type: type, emailAddress: account.accountAddress, fromVC: self)
                .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (urlstr, _, _) in
                    guard let `self` = self, let url = URL(string: urlstr) else {
                        return
                    }
                    self.oauthURL = urlstr
                    self.checkGmailReachable()
                    self.alertHelper?.openGoogleOauthPage(url: url, fromVC: nil)
                    if self.userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                        let model = MailClientOAuthGuideViewModel.defaultAuthModel(url: url, type: type)
                        let vc = MailClientOAuthGuideViewController(model: model) { [weak self] in
                            self?.currentGuideVC = nil
                        }
                        vc.modalPresentationStyle = .overFullScreen
                        self.navigator?.present(vc, from: self, animated: false)
                        self.currentGuideVC = vc
                    }
                    }, onError: { [weak self] (_) in
                        guard let `self` = self else {
                            return
                        }
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Common_NetworkError,
                                                   on: self.view, event: ToastErrorEvent(event: .mailclient_oauth_get_url_fail))
                }).disposed(by: disposeBag)
                
            }
        case .oauthDelinkBtn:
            didClickDelinkBtn()
        }

    }
    private func didClickDelinkBtn() {
        let request = { [weak self]() in
            guard let `self` = self else {
                return
            }
            self.updateMailClientTabStatus(false)
        }
        
        self.alertHelper?.showUnbindConfirmAlert(keepUsing: {
            // nothing
        }, unbindEmail: {
            request()
        }, fromVC: self)
    }
    private func updateMailClientTabStatus(_ status: Bool) {
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Setting_Unbinding, on: self.view, disableUserInteraction: false)
        MailDataServiceFactory
            .commonDataService?
            .updateMailClientTabSetting(status: status)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Setting_UnbindSuccess, on: self.view)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Setting_UnbindFailed,
                                           on: self.view, event: ToastErrorEvent(event: .mailclient_unbind_fail))
                MailLogger.error("updateMailClientTabStatus failed, error:\(error)")
            }).disposed(by: disposeBag)
    }
}

// MARK: Seal
extension MailClientImportViewController {
    func checkGmailReachable () {
        DispatchQueue.global().async {[weak self] in
            guard let `self` = self else {
                return
            }
            var error: Error?
            if let url = URL(string: self.oauthURL) {
                var request = URLRequest(url: url)
                let task = URLSession.shared.dataTask(with: request) { (data, resp, error) in
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        self.isGmailReachable = error == nil
                        MailLogger.error("isGmailReachable: \(self.isGmailReachable), error:\(error?.desensitizedMessage)")
                        if !self.isGmailReachable {
                            if let fromVC = self.navigationController?.topViewController {
                                self.alertHelper?.showCheckVpnAlertIfNeeded(fromVC: fromVC)
                            } else {
                                self.alertHelper?.showCheckVpnAlertIfNeeded(fromVC: self)
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }
}
