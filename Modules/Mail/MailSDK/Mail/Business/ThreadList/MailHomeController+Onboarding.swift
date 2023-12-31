//
//  MailHomeController+Onboarding.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/10.
//

import Foundation
import RxSwift
import EENavigator
import LarkUIKit
import LarkGuideUI
import UIKit
import LarkAlertController
import LarkReleaseConfig
import LarkLocalizations
import UniverseDesignToast
import RustPB

struct SmartInboxOnboardState {
    var didClickDismiss: Bool = false
    var didClickTurnOn: Bool = false
}

protocol MailClientDelegate: AnyObject {
    func checkIfShowNewUserPopupAlert()
}

extension MailHomeController: MailClientDelegate, MailMigrationTipsViewControllerDelegate {
    func showClientMigrationTips() {
        // mock
//        var resp = MailIMAPMigrationOldestMessage()
//        resp.sender = "发件人"
//        resp.title = "邮件标题"
//        resp.totalMessageCount = 100
//        resp.sendTimestamp = 1638761493275
//        let tipsVC = MailMigrationTipsViewController(provider: .tencent, imapResp: resp)
//        tipsVC.delegate = self
//        navigator?.present(tipsVC, from: self)
        // 使用本地缓存维护是否展示，首次绑定三方账号需要弹出
        guard let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID else {
            MailLogger.error("[mail_client_tips] getCachedCurrentAccount nil")
            return
        }
        let kvStore = userContext.userKVStore
        guard kvStore.bool(forKey: "mail_client_account_onboard_\(accountID)") else {
            MailLogger.info("[mail_client_tips] no need to showClientMigrationTips")
            return
        }
        MailDataServiceFactory.commonDataService?.getOldestMessage().subscribe(onNext: { [weak self] (resp) in
            guard let `self` = self, resp.status == .ready else {
                MailLogger.info("[mail_client_tips] getOldestMessage status not ready, resp.status: \(resp.status)")
                return
            }
            let imapResp = resp
            MailDataServiceFactory
                .commonDataService?
                .getTripartiteAccountConfig(accountID: accountID)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    if resp.account.provider == .tencent ||  resp.account.provider == .netEase {
                        self.clientMigrationTipsVC?.dismiss(animated: true)
                        self.clientMigrationTipsVC = nil
                        self.clientMigrationTipsVC =
                        MailMigrationTipsViewController(provider: resp.account.provider, imapResp: imapResp, rootSizeClassIsRegular: self.rootSizeClassIsRegular)
                        self.clientMigrationTipsVC?.maskResponse = false
                        self.clientMigrationTipsVC?.delegate = self
                        if let tipsVC = self.clientMigrationTipsVC {
                            self.navigator?.present(tipsVC, from: self)
                        }
                    } else {
                        kvStore.removeValue(forKey: "mail_client_account_onboard_\(accountID)")
                    }
                }, onError: { (error) in
                    MailLogger.error("[mail_client_tips] getTripartiteAccountConfig fail error:\(error)")
                }).disposed(by: self.disposeBag)
        }, onError: { (error) in
            MailLogger.error("[mail_client_tips] onboard fail", error: error)
        }).disposed(by: self.disposeBag)
    }

    func migrationTipsButtonClick(_ flag: Bool, provider: MailTripartiteProvider) {
        clientMigrationTipsVC?.dismiss(animated: true)
        clientMigrationTipsVC = nil
        guard let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID else {
            MailLogger.error("[mail_client_tips] getCachedCurrentAccount nil")
            return
        }
        let kvStore = userContext.userKVStore
        kvStore.removeValue(forKey: "mail_client_account_onboard_\(accountID)")
        if !flag {
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_SyncMoreData)
            alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_AdjustRetry, alignment: .center)
            var providerTips = ""
            switch provider {
            case .tencent:
                providerTips = BundleI18n.MailSDK.Mail_ThirdClient_GoTecentExmail
            case .netEase:
                providerTips = BundleI18n.MailSDK.Mail_ThirdClient_Go163Mail
            @unknown default:
                break
            }
            if !providerTips.isEmpty {
                alert.addPrimaryButton(text: providerTips, dismissCompletion: { [weak self] in
                    self?.openProvider(provider)
                })
            }
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_ViewHelpMobile, dismissCompletion: { [weak self] in
                self?.openHelpGuide(provider)
            })
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_NoNeed, dismissCompletion: nil)
            navigator?.present(alert, from: self)
        }
    }

    func openProvider(_ type: MailTripartiteProvider) {
        var link = ""
        switch type {
        case .tencent:
            link = "https://exmail.qq.com/"
        case .netEase:
            link = "https://qiye.163.com/"
        @unknown default:
            break
        }
        guard let url = URL(string: link) else { return }
        UIApplication.shared.openURL(url)
    }

    func openHelpGuide(_ type: MailTripartiteProvider) {
        guard let link = ProviderManager.default.commonSettingProvider?.stringValue(key: "open-imap")?.localLink,
              let url = URL(string: link) else { return }
        UIApplication.shared.open(url)
    }

    func showOnboardPage() {
        dualVC = MailDualViewController()
        dualVC?.modalPresentationStyle = .overCurrentContext
        dualVC?.delegate = self
        if dualVC != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
                guard let `self` = self, let temDualVC = self.dualVC else { return }
                if let onboardingParentView = self.larkSplitViewController?.view {
                    onboardingParentView.addSubview(temDualVC.view)
                    onboardingParentView.bringSubviewToFront(temDualVC.view)
                    temDualVC.view.frame = CGRect(x: 0, y: 0, width: onboardingParentView.bounds.size.width, height: onboardingParentView.bounds.size.height)
                } else if let tabBarControllerView = self.tabBarController?.view {
                    tabBarControllerView.addSubview(temDualVC.view)
                    tabBarControllerView.bringSubviewToFront(temDualVC.view)
                    let onboardingFrame = self.parent?.view.convert(self.view.frame, to: tabBarControllerView) ?? .zero
                    temDualVC.view.frame = onboardingFrame
                }
            }
        }
    }

    func checkIfShowNewUserPopupAlert() {
        if !isInMailTab() {
            return
        }
        if let setting = Store.settingData.getCachedCurrentSetting(), setting.userType == .newUser, setting.accountRevokeNotifyPopupVisible == true {
            // 需要展示popup弹框
            if dualVC != nil {
                dualVC?.view.removeFromSuperview()
                dualVC = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak self] in
                    self?.showOnboardPage()
                }
            } else {
                showOnboardPage()
            }
        }
    }
    
    func showMailClientPassLoginExpriedAlertIfNeeded() {
        guard Store.settingData.mailClient, let account = Store.settingData.getCachedCurrentAccount() else {
            MailLogger.error("[mail_client_token] getCachedCurrentAccount nil")
            headerViewManager.dismissPassLoginExpiredTips()
            return
        }
        let guideKey = "all_mail_Client_OAuth_login"
        guard let shouldShowGuide = userContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: guideKey),
        shouldShowGuide else {
            if account.provider.needShowPassLoginExpried() && account.loginPassType == .password {
                headerViewManager.showPassLoginExpiredTips()
            }
            return
        }
        if account.provider.needShowPassLoginExpried() && account.loginPassType == .password {
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn)
            alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogInDesc, alignment: .center)
            alert.addCancelButton(dismissCompletion:  { [weak self] in
                self?.headerViewManager.showPassLoginExpiredTips()
            })
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn,
                                   numberOfLines: 2, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                Store.settingData.tokenRelink(
                    provider: account.provider,
                    navigator: self.userContext.navigator,
                    from: self,
                    accountID: account.mailAccountID,
                    address: account.mailSetting.emailAlias.defaultAddress.address
                )
            })
            navigator?.present(alert, from: self)
            userContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
        }
    }

    func showPreloadTaskStatusIfNeeded() {
        Store.fetcher?.mailGetPreloadStatus()
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else { return }
                MailLogger.info("[mail_cache_preload] showPreloadTaskStatusIfNeeded response: \(response.accountID) currentAcc: \(Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? "") progress: \(response.progress) status: \(response.status) errorCode: \(response.errorCode) isBannerClosed: \(response.isBannerClosed), needPush: \(response.needPush)")
                guard response.accountID == Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? "" else { return }
                self.headerViewManager.refreshPreloadProgressStage(
                    MailPreloadProgressPushChange(status: response.status, progress: response.progress, errorCode: response.errorCode, preloadTs: response.preloadTs, isBannerClosed: response.isBannerClosed, needPush: response.needPush),
                    fromLabel: self.viewModel.currentLabelId
                )
        }, onError: { (error) in
            MailLogger.error("[mail_cache_preload] mailSetPreloadTimeStamp fail", error: error)
        }).disposed(by: self.disposeBag)
    }
}

extension MailHomeController: MailDualViewControllerDelegate {
    func dismiss() {
        dualVC?.view.removeFromSuperview()
        dualVC = nil
    }
    func jumpToWebView(url: URL) {
        navigator?.push(url, from: self)
    }

    func confirmSuccessTips() {
        // smart inbox onboarding stash
//        dualVC?.view.removeFromSuperview()
//        dualVC = nil
//        if isSmartInboxEnable && !UserDefaults.standard.bool(forKey: UserDefaultKeys.mailSmartInboxLabelOnboarding) {
//            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
//                self.showFilterDrawer()
//            }
//        }
    }
}

extension MailHomeController: MailSettingAccountCellDependency {
    func jumpSettingOfAccount(_ accountId: String) {}
    func jumpAdSetting(_ accountId: String, provider: MailTripartiteProvider) {}
}

// New UserGuide
extension MailHomeController: MailSmartInboxGuideViewDelegate {
    func clickTurnOn() {
        smartInboxOnboardState.didClickTurnOn = true
        userContext.provider.guideServiceProvider?.guideService?.removeGuideTasksIfNeeded(keys: ["all_email_smartinbox_intro",
                                                                                                    "all_email_smartinbox_dialog",
                                                                                                    "all_email_previewcard"])
        self.showMailSettings()
        MailTracker.log(event: "mail_si_onboarding_result", params: ["timestamp": Int(1000 * Date().timeIntervalSince1970), "result": "enable"])
    }

    func clickDismiss() {
        smartInboxOnboardState.didClickDismiss = true
        MailTracker.log(event: "mail_si_onboarding_result", params: ["timestamp": Int(1000 * Date().timeIntervalSince1970), "result": "dismiss"])
    }

    func showMultiAccountOnboardingIfNeeded() {
        if isShowing {
            let guideKey = "all_email_publicinbox"
            let targetAnchor = TargetAnchor(targetSourceType: .targetView(self.tableHeaderView))
            let textConfig = TextInfoConfig(title: nil, detail: BundleI18n.MailSDK.Mail_Mailbox_PublicMailbox)
            let bubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor, textConfig: textConfig))
            userContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                                bubbleType: .single(bubbleConfig),
                                                                                                dismissHandler: nil,
                                                                                                didAppearHandler: nil,
                                                                                                willAppearHandler: nil)
        }
    }
}

struct AssociatedKey {
    static var notifyBotOnboarding: String = "NotifyBotOnboardingAssociatedKey"
}

// MARK: - NotifyBotOnboarding
extension MailHomeController:MailNotifyBotGuideViewDelegate {
    
    var isNotifyBotCustomOnboardingShowing: Bool {
        get {
            let isShowing = objc_getAssociatedObject(self, &AssociatedKey.notifyBotOnboarding) as? Bool
            return isShowing ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.notifyBotOnboarding, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func closeNotifyBotOnboarding() {
        if self.isNotifyBotCustomOnboardingShowing {
            LarkGuideUI.GuideUITool.closeGuideIfNeeded(hostProvider: self)
            self.isNotifyBotCustomOnboardingShowing = true
        }
    }
    
    /// TODO: 由于 CustomGuideView 目前无法处理iPad旋转的适配，暂时采用先关闭后重新显示的方案，等待其优化完毕后再优化实现
    func updateNotifyBotOnboardingFrame() {
        if self.isNotifyBotCustomOnboardingShowing {
            let customView = MailNotifyBotGuideView(delegate: self, notifyBotDelegate: self)
            if let window = currentWindow() {
                let x = (window.frame.width - customView.intrinsicContentSize.width)/2.0
                let y = (window.frame.height - customView.intrinsicContentSize.height)/2.0
                let frame = CGRect(x: x, y: y, width: customView.intrinsicContentSize.width, height: customView.intrinsicContentSize.height)
                let customConfig = GuideCustomConfig(customView: customView, viewFrame: frame, delegate: self, enableBackgroundTap: true)
                LarkGuideUI.GuideUITool.displayCustomView(hostProvider: self, customConfig: customConfig, dismissHandler:{ [weak self] in
                    self?.isNotifyBotCustomOnboardingShowing = false
                })
            }
        }
    }
    
    func showNotifyBotOnboardingIfNeeded() {
        if !isShowing { return }
        guard !Store.settingData.mailClient else { return }
        let guideKey = "other_email_service_newemail_notification_bot"
        guard let guide = userContext.provider.guideServiceProvider?.guideService,
              guide.checkShouldShowGuide(key: guideKey) else {
            return
        }
        guard let setting = Store.settingData.getCachedCurrentSetting() else { return }
        guard let firstData = viewModel.datasource.first else { return }
        if !firstData.isUnread { return }
        
        if (!setting.newMailNotification || setting.newMailNotificationChannel >> 1 & 1 == 0) {
            let customView = MailNotifyBotGuideView(delegate: self, notifyBotDelegate: self)
            if let window = currentWindow() {
                let x = (window.frame.width - customView.intrinsicContentSize.width)/2.0
                let y = (window.frame.height - customView.intrinsicContentSize.height)/2.0
                let frame = CGRect(x: x, y: y, width: customView.intrinsicContentSize.width, height: customView.intrinsicContentSize.height)
                let customConfig = GuideCustomConfig(customView: customView, viewFrame: frame, delegate: self, enableBackgroundTap: true)
                userContext.provider.guideServiceProvider?.guideService?.showCustomGuideIfNeeded(guideKey: guideKey, customConfig: customConfig, dismissHandler: { [weak self] in
                    self?.isNotifyBotCustomOnboardingShowing = false
                })
                self.isNotifyBotCustomOnboardingShowing = true
            }
        }
    }
    
    func didNotifyBotClickSkip(dialogView: GuideCustomView) {
        
    }
    
    func didNotifyBotClickOpen(dialogView: GuideCustomView) {
        Store.settingData.updateCurrentSettings(.allNewMailNotificationSwitch(enable: true),.newMailNotification(enable: true),.newMailNotificationChannel(MailChannelPosition.bot, enable: true)) { [weak self] in
                guard let `self` = self else {
                    return
                }
                ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_Bot_Enabled,
                                         on: self.view,
                                         action: nil,
                                         autoDismiss: true,
                                         dissmissOnTouch: true) { 
                ActionToast.removeToast(on: self.view.window ?? self.view)
            }
        } onError: { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            ActionToast.showFailureToast(with: BundleI18n.MailSDK.Mail_Inbox_ActionFailed,
                                         on: self.view,
                                         action: nil,
                                         autoDismiss: true,
                                         dissmissOnTouch: true) {
                ActionToast.removeToast(on: self.view.window ?? self.view)
            }
        }
    }
}

extension MailHomeController: MailAIGuideViewDelegate {
    func showAIOnboardingIfNeeded() {
        if !isShowing { return }
        let guideKey = "all_email_myai"
        guard let guide = userContext.provider.guideServiceProvider?.guideService,
              guide.checkShouldShowGuide(key: guideKey) else {
            return
        }
        let enable = userContext.provider.myAIServiceProvider?.isAIEnable ?? false
        let larkAIFG = userContext.featureManager.open(FeatureKey(fgKey: .larkAI, openInMailClient: false))
        let mailAIFG = userContext.featureManager.open(FeatureKey(fgKey: .mailAI, openInMailClient: false))
        let onboardFG = userContext.featureManager.open(FeatureKey(fgKey: .mailAIOnboard, openInMailClient: false))
        let canShow = enable && larkAIFG && mailAIFG && onboardFG
        if (canShow) {
            let aiDefaultName = userContext.provider.myAIServiceProvider?.aiNickName ??  userContext.provider.myAIServiceProvider?.aiDefaultName ?? ""
            let customView = MailAIGuideView(delegate: self,
                                             aiDelegate: self,
                                             defaultName: aiDefaultName)
            if let window = currentWindow() {
                let x = (window.frame.width - customView.intrinsicContentSize.width)/2.0
                let y = (window.frame.height - customView.intrinsicContentSize.height)/2.0
                let frame = CGRect(x: x, y: y, width: customView.intrinsicContentSize.width, height: customView.intrinsicContentSize.height)
                let customConfig = GuideCustomConfig(customView: customView, viewFrame: frame, delegate: self, enableBackgroundTap: false)
                userContext.provider.guideServiceProvider?.guideService?.showCustomGuideIfNeeded(guideKey: guideKey, customConfig: customConfig, dismissHandler: nil)
                let event = NewCoreEvent(event: .email_myai_onboard_window_view)
                event.post()
            }
        }
    }
    func didAIGuideViewClickOpen(dialogView: GuideCustomView) {
        createDraft()
        let event = NewCoreEvent(event: .email_myai_onboard_window_click)
        event.params = ["click": "try_now"]
        event.post()
    }
    func didAIGuideViewClickOk(dialogView: GuideCustomView) {
        let event = NewCoreEvent(event: .email_myai_onboard_window_click)
        event.params = ["click": "i_know"]
        event.post()
    }
}

extension MailHomeController: GuideCustomViewDelegate, GuideSingleBubbleDelegate {
    func showConversationModeSortGuideIfNeeded(){
        guard let mailAccount = self.viewModel.currentAccount else{ return }
        let accountSetting = mailAccount.mailSetting
        //onboarding逻辑：本次更新前已开启会话模式∧已在PC端设置新邮件在顶部 + FG的判断
        if !((accountSetting.enableConversationMode) && (accountSetting.messageDisplayRankMode)) {
            return
        }
        let targetAnchor = TargetAnchor(targetSourceType: .targetView(self.navMoreButton))
        let textConfig = TextInfoConfig(title: "",
                                        detail: BundleI18n.MailSDK.Mail_Order_ArrangeOrderOnboarding)
        let leftButtonInfo = ButtonInfo(title: "", skipTitle: BundleI18n.MailSDK.Mail_Order_GotIt, buttonType: .skip)
        let rightButtonInfo = ButtonInfo(title: "", skipTitle: BundleI18n.MailSDK.Mail_Order_GoToSettings, buttonType: .finished)
        let bottomConfig = BottomConfig(leftBtnInfo: leftButtonInfo, rightBtnInfo: rightButtonInfo, leftText: nil)
        let bubbleConfig = SingleBubbleConfig(delegate: self,
                                              bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor,
                                                                             textConfig: textConfig,
                                                                             bottomConfig: bottomConfig),
                                              maskConfig: MaskConfig(shadowAlpha: 0.0, windowBackgroundColor: .clear, maskInteractionForceOpen: true))
        let guideKey = "mobile_setting_display_order"
        userContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                            bubbleType: .single(bubbleConfig)) { [weak self] in
            self?.userContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
        }
    }

    func didClickLeftButton(bubbleView: GuideBubbleView){
        userContext.provider.guideServiceProvider?.guideService?.closeCurrentGuideUIIfNeeded()
    }
    // 点击右边按钮
    func didClickRightButton(bubbleView: GuideBubbleView){
        if bubbleView.bubbleConfig.textConfig.detail == BundleI18n.MailSDK.Mail_EmailMigration_Mobile_PublicMailboxMigrationEnabled_Onboarding_Desc {
            GuideUITool.closeGuideIfNeeded(hostProvider: self)
            userContext.provider.guideServiceProvider?.guideService?.closeCurrentGuideUIIfNeeded()
            return
        }
        if bubbleView.bubbleConfig.textConfig.detail != BundleI18n.MailSDK.Mail_Order_ArrangeOrderOnboarding {
            return
        }
        //前往设置页中的会话模式相关设置
        if let settingController = showMailSettings() as? MailSettingViewController {
            settingController.setupViewModel()
            settingController.jumpConversationPage()
        }
        userContext.provider.guideServiceProvider?.guideService?.closeCurrentGuideUIIfNeeded()
    }
    // 点击气泡事件
    func didTapBubbleView(bubbleView: GuideBubbleView){
        
    }
    func didCloseView(customView: GuideCustomView) {}
}

extension MailHomeController {
    func showStrangerOnboardingIfNeeded() {
        guard !Store.settingData.mailClient else {
            return
        }
        let guideKey = "all_email_stranger_new"
        let showGuide = userContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: guideKey)
        guard let shouldShowGuide = showGuide, shouldShowGuide, !viewModel.didShowStrangerOnboard else {
            return
        }
        MailLogger.info("[mail_stranger] showStrangerOnboardingIfNeeded shouldShowGuide")
        let onboardView = MailStrangerOnboardView(delegate: self)
        onboardView.closeHandler = { [weak self] in
            onboardView.removeFromSuperview()
            self?.userContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
        }
        if let mainTabbar = self.animatedTabBarController {
            if view.window != nil {
                mainTabbar.view.addSubview(onboardView)
                onboardView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                viewModel.didShowStrangerOnboard = true
                viewModel.shouldShowStrangerOnboard = false
            } else {
                viewModel.shouldShowStrangerOnboard = true
            }
        }
    }
}

extension MailHomeController {
    func getTopViewController() -> UIViewController? {
        var vc = self.view.window?.rootViewController
        while (vc is UINavigationController) || (vc is UITabBarController) {
            if vc is UINavigationController {
                vc = (vc as? UINavigationController)?.topViewController
            }
            if vc is UITabBarController {
                vc = (vc as? UITabBarController)?.selectedViewController
            }
            if vc?.presentedViewController != nil {
                vc = vc?.presentedViewController
            }
        }
        return vc
    }
}
