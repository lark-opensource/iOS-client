//
//  MailTabBarController.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/27.
//

import Foundation
import LarkUIKit
import RxCocoa
import LarkAlertController
import EENavigator
import AnimatedTabBar
import Homeric
import LKCommonsTracker
import RxSwift
import LarkSplitViewController

protocol TabBarDelegate: AnyObject {
    func doubleTapEvent()
}

protocol TarBarDisplayDelegate: AnyObject {
    func switchContent(inHome: Bool, insert: Bool, initData: Bool)
}

typealias MailHomeInterface = UIViewController &
    TabBarDelegate &
    MailNavBarDelegate &
    MailNavBarDatasource &
    MailClientDelegate &
    MailMultiAccountViewDelegate &
    MailFirstScrennDataObservable
//&
//    TarBarDisplayDelegate

typealias MailClientInterface = UIViewController & MailNavBarDatasource

/// 用于首页邮件tab的viewcontroller，为了以防某天不是mailhome做主页不用改胶水代码，不集成MailBaseViewController @liutefeng
public final class MailTabBarController: UIViewController, TarBarDisplayDelegate {
    public var unreadData: (Int, Int) = (0, -1) // 左边为未读数，右边为未读样式枚举值

    private let disposeBag = DisposeBag()
    private var loadingDisposeBag = DisposeBag()

    // lazy load
    lazy var content: MailHomeInterface = MailHomeController(userContext: userContext)

    // lazy load
    lazy var clientContent: MailClientInterface = MailClientViewController(scene: userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) ? .newFreeBind : .normal, userContext: userContext)
    private let loadingView = MailBaseLoadingView()
    private(set) var inHome = true
    /// 是否需要检查显示登录页
    private var shouldCheckLogin = false
    private var didLoadFirstVC = false
    private var didDelaySwitchContent = false
    private var enterTabTimeStamp: TimeInterval = -1
    private lazy var speedupLoadingFg = userContext.featureManager.open(FeatureKey(fgKey: .homeSpeedupLoading, openInMailClient: true))

    private var realTimeShouldCheckLogin: Bool {
        userContext.featureManager.realTimeOpen(.mailClient) || userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false)
    }

    public var firstScreenObserver: MailFirstScrennDataObservable {
        return self.content
    }

    let userContext: MailUserContext

    init(userContext: MailUserContext) {
        self.userContext = userContext
        super.init(nibName: nil, bundle: nil)
        content.setNavBarBridge(self)
        clientContent.setNavBarBridge(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // to update view frame
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // update view along with animation
            guard let `self` = self else { return }
            MailLogger.info("[mail_client_ipad] size: \(size)")
            if !self.inHome {
                self.clientContent.view.frame = CGRect(x: 0, y: 0, width: Display.width, height: Display.height)
            }
        }, completion: {_ in
            // update view after transition
        })
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MailLogger.info("[mail_client] mailClient fg self.clientFg: \(self.shouldCheckLogin) realTime: \(realTimeShouldCheckLogin)")
        if self.shouldCheckLogin != realTimeShouldCheckLogin {
            MailLogger.info("[mail_client] mailClient fg realTime change: \(realTimeShouldCheckLogin)")
            displayHomeIfNeeded(realTimeShouldCheckLogin)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        MailLogger.info("[mail_loading] Tabbar VC viewDidLoad")
        (clientContent as? MailClientViewController)?.displayDelegate = self
        (content as? MailHomeController)?.displayDelegate = self
        displayHomeIfNeeded(realTimeShouldCheckLogin)
        Store.settingData
            .netSettingPush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if self.userContext.featureManager.realTimeOpen(.mailClient) {
                    MailLogger.info("[mail_client] mailClient netSettingPush refresh")
                    self.displayHomeIfNeeded(self.realTimeShouldCheckLogin)
                }
        }).disposed(by: disposeBag)

        Store.settingData
            .rebootChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let fg = self.realTimeShouldCheckLogin
                MailLogger.info("[mail_client] mailClient rebootChangesPush refresh fg: \(fg)")
                self.displayHomeIfNeeded(fg)
        }).disposed(by: disposeBag)
        
        if speedupLoadingFg {
            loadingView.isHidden = true
            view.addSubview(loadingView)
            loadingView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
            Observable.just(())
            .delay(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    if !self.didLoadFirstVC {
                        self.showMailLoading()
                    }
                }).disposed(by: loadingDisposeBag)
        }
    }

    func displayHomeIfNeeded(_ shouldCheckLogin: Bool) {
        switchToInitVC(shouldCheckLogin: shouldCheckLogin, handler: { [weak self] (show) in
            guard let `self` = self else { return }
            self.hideMailLoading()
            self.switchContent(inHome: show, insert: true, initData: true)
            if !show {
                self.clientContent.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            } else {
                self.content.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            if !self.didLoadFirstVC {
                self.didLoadFirstVC = true
                self.mailPageActive()
            }
        })
    }

    func switchToInitVC(shouldCheckLogin: Bool, handler: @escaping (Bool) -> Void) {
        self.shouldCheckLogin = shouldCheckLogin
        if shouldCheckLogin {
            if !didLoadFirstVC && !speedupLoadingFg {
                showMailLoading()
            }
            if let primaryAccount = Store.settingData.getCachedPrimaryAccount() {
                MailLogger.info("[mail_client] use Cache")
                needShowHomeVC(primaryAccount: primaryAccount, accountList: primaryAccount.sharedAccounts, handler: { (show) in
                    handler(show)
                })
            } else {
                Store.settingData.getAccountList(fetchDb: true).subscribe { [weak self] (resp) in
                    guard let `self` = self else { return }
                    guard let primaryAccount = resp.accountList.first(where: { !$0.isShared }) else {
                        mailAssertionFailure("[mail_client] primaryAccount is nil accountList: \(resp.accountList.map({ $0.mailAccountID }))")
                        self.inHome = true
                        handler(self.inHome)
                        return
                    }
                    self.needShowHomeVC(primaryAccount: primaryAccount, accountList: resp.accountList, handler: { (show) in
                        handler(show)
                    })
                } onError: { [weak self] (err) in
                    guard let `self` = self else { return }
                    mailAssertionFailure("[mail_client] setting error: \(err)")
                    self.inHome = true
                    handler(self.inHome)
                }.disposed(by: self.disposeBag)
            }
        } else {
            MailLogger.info("[mail_client] mailClient fg is closed")
            self.inHome = true
            handler(self.inHome)
        }
    }

    func needShowHomeVC(primaryAccount: MailAccount, accountList: [MailAccount], handler: @escaping (Bool) -> Void) {
        let sharedAccs: [MailAccount] = accountList.filter({ $0.isShared && $0.mailSetting.userType == .tripartiteClient })
        MailLogger.info("[mail_client] pri userType: \(primaryAccount.mailSetting.userType) sharedAccCount: \(sharedAccs.count)")
        if sharedAccs.isEmpty {
            MailLogger.info("[mail_client] why pri userType: \(primaryAccount.mailSetting.userType) sharedAccCount: \(sharedAccs.count)")
        }
        var mailClientFlag = false
        if primaryAccount.mailSetting.userType == .noPrimaryAddressUser || Store.settingData.isInIMAPFlow(primaryAccount) {
            let enable = primaryAccount.mailSetting.isThirdServiceEnable
            mailClientFlag = enable && userContext.featureManager.realTimeOpen(.mailClient)
            MailLogger.info("[mail_client] pri isThirdServiceEnable: \(enable) mailClientFlag: \(mailClientFlag)")
        }
        var newFreeBindFlag = false
        if primaryAccount.mailSetting.userType == .newUser {
            newFreeBindFlag = userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false)
        }
        let shouldCheckLogin = mailClientFlag || newFreeBindFlag
        Store.settingData.updateClientStatusIfNeeded()
        Store.settingData.updateCachedCurrentAccount(primaryAccount, accountList: primaryAccount.sharedAccounts)
        self.inHome = (shouldCheckLogin && sharedAccs.count > 0) || !shouldCheckLogin // 没开三方就进首页提示, 开了三方且当前有三方账号也进首页
        handler(self.inHome)
        if mailClientFlag {
            self.setMailClientCache()
        }
        if self.inHome {
            Store.settingData.tabVCFetchSettingLoadedNotify()
        }
    }

    func setMailClientCache() {
        userContext.userKVStore.set(!self.inHome, forKey: "MailClient_ShowLoginPage_\(userContext.user.tenantID)")
    }
    
    func showMailLoading() {
        if speedupLoadingFg {
            MailLogger.info("[mail_loading] Tabbar VC showMailLoading")
            (content as? MailHomeController)?.viewModel.resetWhiteScreenDetect()
            loadingView.isHidden = false
        } else {
            view.addSubview(loadingView)
            loadingView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        }
        loadingView.play()
    }

    func hideMailLoading() {
        if speedupLoadingFg {
            MailLogger.info("[mail_loading] Tabbar VC hideMailLoading")
            loadingView.isHidden = true
            loadingView.stop()
        } else {
            loadingView.stop()
            loadingView.removeFromSuperview()
        }
    }

    func switchContent(inHome: Bool, insert: Bool, initData: Bool) {
        self.inHome = inHome
        MailLogger.info("[mail_client_nav] switchContent - inHome: \(inHome)")
        if inHome {
            (clientContent as? MailClientViewController)?.displaying = false
            let homeVC = content as? MailHomeController
            homeVC?.displaying = true
            homeVC?.initData = initData
            if speedupLoadingFg {
                if Date().timeIntervalSince1970 - enterTabTimeStamp < 300 {
                    MailLogger.info("[mail_loading] enterTabTimeStamp: \(enterTabTimeStamp)")
                    homeVC?.enterTabTimeStamp = enterTabTimeStamp
                }
            }
            homeVC?.changeNaviBarPresentation(show: true, animated: false)
            if clientContent.isViewLoaded {
                hideContentController(clientContent)
            }
            self.larkSplitViewController?.cleanSecondaryViewController()
            self.larkSplitViewController?.setViewController(UIViewController.DefaultDetailController(), for: .secondary)
            self.larkSplitViewController?.updateSplitMode(.twoBesideSecondary, animated: false)
            displayContentController(content, insert: insert)
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short, execute: {
                homeVC?.changeNaviBarPresentation(show: true, animated: false)
                if let nav = homeVC?.getLarkNavbar() {
                    self.view.bringSubviewToFront(nav)
                }
                self.didDelaySwitchContent = true
            })
        } else {
            (content as? MailHomeController)?.displaying = false
            guard let clientVC = clientContent as? MailClientViewController else {
                MailLogger.error("[mail_client] client vc is nil")
                return
            }
			guard !Display.pad || clientVC.displaying == false else {
                MailLogger.info("[mail_client] client vc already presented, skip to prevent flashing in ipad")
                return
            }
            clientVC.displaying = true
            clientVC.didLoginSuccess = false
            if content.isViewLoaded { // 如果view没有创建，不需要，避免导致view懒加载。
                hideContentController(content)
            }

            if let splitViewController = self.larkSplitViewController {
                let navi = LkNavigationController(rootViewController: clientVC)
                clientVC.supportSecondaryOnly = true
                splitViewController.setViewController(navi, for: .secondary)
                splitViewController.updateSplitMode(.secondaryOnly, animated: false)
            } else {
                displayContentController(clientVC)
            }
            if !didDelaySwitchContent {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short, execute: { // 首次冷启动导航栏初始化时机不可控，会被移动到最前，所以需要延迟做一下
                    clientVC.navigationController?.isNavigationBarHidden = true
                    if let nav = clientVC.navbarBridge?.getLarkNaviBar() {
                        self.view.sendSubviewToBack(nav)
                    }
                    self.didDelaySwitchContent = true
                })
            }
        }
    }

    public func didReceiveDoubleTabEvent() {
        content.doubleTapEvent()
    }

    private func mailPageActive() {
        mailTabSelected()
        Tracker.post(TeaEvent(Homeric.EMAIL_LAUNCH, params: ["flag": "enter", "unread_count": unreadData.0, "unread_state": unreadData.1]))
        MailStateManager.shared.enterMailTab()
        MailRiskEvent.enterMail(channel: .tab)
    }

    private func mailTabSelected() {
        // apm
        MailDataServiceFactory
            .commonDataService?
            .noticeClientEvent(event: .mailTabSelected)
            .subscribe().disposed(by: disposeBag)
    }

    private func mailTabUnselected() {
        MailDataServiceFactory
            .commonDataService?
            .noticeClientEvent(event: .mailTabUnselected)
            .subscribe().disposed(by: disposeBag)
    }
}

/// status bar style depend on it's content controller preferredStatusBarStyle
extension MailTabBarController {
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return content.preferredStatusBarStyle
    }
}

extension MailTabBarController: TabBarEventViewController {
    public func didSwitchToTabBarController(_ tabType: TabType, oldType: TabType) {
        if didLoadFirstVC {
            mailPageActive()
        }
    }

    public func didSwitchOutTabBarController(_ tabType: TabType, oldType: TabType) {
        mailTabUnselected()
        Tracker.post(TeaEvent(Homeric.EMAIL_LAUNCH, params: ["flag": "leave"]))
        MailStateManager.shared.exitMailTab()
    }
}
