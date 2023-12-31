//
//  MailSDK+Interface.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/28.
//

import Foundation
import EENavigator
import RxSwift
import LarkUIKit
import Homeric
import RustPB
import LarkAlertController
import LarkNavigation
import LarkTab
import Reachability
import LarkAppConfig

// 需要提供给外部使用的方法在这里添加
extension MailSDKManager {
    public func getMailUnreadCount() -> Observable<RustPB.Email_Client_V1_MailGetUnreadCountResponse> {
        guard let dataService = dataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.getMailUnreadCount().map { (resp) -> RustPB.Email_Client_V1_MailGetUnreadCountResponse in
            return resp
        }
    }

    public func openEml(emlPath: URL, from: NavigatorFrom, switchToMail: Bool) {
        let vc = EmlPreviewViewController.localEmlPreview(accountContext: userContext.getCurrentAccountContext(), localPath: emlPath)
        let showEMLVC = { [weak self] in
            guard let self = self else { return }
            if Display.pad {
                self.userContext.navigator.showDetail(vc, wrap: MailMessageListNavigationController.self, from: from)
            } else {
                self.userContext.navigator.push(vc, from: from)
            }
        }
        
        if switchToMail {
            userContext.navigator.switchTab(Tab.mail.url, from: from, animated: true) { _ in
                showEMLVC()
            }
        } else {
            showEMLVC()
        }
    }

    public func openEmlFromIM(provider: EMLFileProvider, from: NavigatorFrom) {
        userContext.navigator.push(EmlPreviewViewController.emlPreviewFromIM(accountContext: userContext.getCurrentAccountContext(), provider: provider), from: from)
    }

    public static func markActiveMailPage() -> Observable<Void> {
        guard let dataService = MailDataServiceFactory.commonDataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.noticeClientEvent(event: .mailPageActive)
    }

    public static func markInActiveMailPage() -> Observable<Void> {
        guard let dataService = MailDataServiceFactory.commonDataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.noticeClientEvent(event: .mailPageInactive)
    }
    
    public func makeEMLPreviewController(_ emlPath: URL) -> UIViewController {
        return EmlPreviewViewController.localEmlPreview(accountContext: userContext.getCurrentAccountContext(), localPath: emlPath)
    }

    public func makeMailSearchViewController(_ query: String?, _ searchNavBar: SearchNaviBar?) -> UIViewController {
        return MailSearchViewController(accountContext: userContext.getCurrentAccountContext(), query: query, searchNavBar: searchNavBar)
    }
}

extension MailSDKManager: MailApmHolderAble {}

public struct MailDetailRouterInfo {
    var threadId: String
    var messageId: String
    let sendMessageId: String? // 自己发自己时，需要发信messageId
    let sendThreadId: String? // 自己发自己时，需要发信threadId
    var labelId: String
    let accountId: String?
    let cardId: String?
    let ownerId: String?
    let tab: URL?
    let from: NavigatorFrom
    let multiScene: Bool
    /// 打点信息，标注从哪进入读信
    let statFrom: String
    let fromChat: Bool
    let keyword: String
    let startTime: TimeInterval
    let feedCardId: String
    
    public init(threadId: String, messageId: String, sendMessageId: String?, sendThreadId: String?, labelId: String, accountId: String?, cardId: String?, ownerId: String?, tab: URL?, from: NavigatorFrom, multiScene: Bool = false, statFrom: String, fromChat: Bool = false, keyword: String = "", feedCardId: String = "") {
        self.threadId = threadId
        self.messageId = messageId
        self.sendMessageId = sendMessageId
        self.sendThreadId = sendThreadId
        self.labelId = labelId
        self.accountId = accountId
        self.cardId = cardId
        self.ownerId = ownerId
        self.tab = tab
        self.from = from
        self.multiScene = multiScene
        self.statFrom = statFrom
        self.fromChat = fromChat
        self.keyword = keyword
        self.startTime = Date().timeIntervalSince1970
        self.feedCardId = feedCardId
    }
}

public enum MailBotAction {
    case shareCard
    case trash
    case spam

    func actionType() -> String {
        switch self {
        case .shareCard:
            return "email_share"
        case .trash:
            return "trash"
        case .spam:
            return "spam"
        }
    }
}

// router
extension MailSDKManager {
    // 发送邮件
    public func showSendMail(emailAddress: String = "",
                             subject: String = "",
                             body: String = "",
                             cc: String = "",
                             bcc: String = "",
                             originUrl: String = "",
                             from: NavigatorFrom) {
        // 如果用户没有开启Lark mail，包括未绑定、关闭Email tab等，这些情况下就跳转到系统。
        if Store.settingData.hasEmailService {
            let vc = MailSendController.makeSendNavController(accountContext: userContext.getCurrentAccountContext(), action: .fromAddress, labelId: Mail_LabelId_Inbox, statInfo: MailSendStatInfo(from: .routerPullUp, newCoreEventLabelItem: "none"), trackerSourceType: .mailTo, sendToAddress: emailAddress, subject: subject.isEmpty ? nil: subject, body: body.isEmpty ? nil : body, cc: cc.isEmpty ? nil : cc, bcc: bcc.isEmpty ? nil : bcc, fileBannedInfos: nil)
            userContext.navigator.present(vc, from: from)
        } else {
            var urlString = emailAddress
            if !urlString.hasPrefix("mailto:") {
                urlString = "mailto:" + emailAddress
            }
            if originUrl.hasPrefix("mailto:") {
                urlString = originUrl
            }
            guard let url = URL.init(string: urlString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    public func showRecallAlert(tab: URL, from: NavigatorFrom) {
        func showRecallAlert(from: NavigatorFrom) {
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_Recall_DilaogHasBeenRecalled)
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK)
            userContext.navigator.present(alert, from: from)
            InteractiveErrorRecorder.recordError(event: .has_been_recall,
                                                 tipsType: .alert,
                                                 userCause: false,
                                                 scene: .notification)
        }

        if manager.delegate?.isInMailTab != true {
            userContext.navigator.switchTab(tab, from: from, animated: true) { _ in
                showRecallAlert(from: from)
            }
        } else {
            showRecallAlert(from: from)
        }
    }

    // show mail list or send
    public func showMailDetail(routerInfo: MailDetailRouterInfo) {
        let accountId = routerInfo.accountId ?? ""
        let threadId = routerInfo.threadId
        let messageId = routerInfo.messageId
        if routerInfo.statFrom == "deleteMail" {
            guard userContext.featureManager.open(FeatureKey(fgKey: .applinkDelete, openInMailClient: false)) else {
                return
            }
        }

        MailLogger.info("enter showMailDetail: threadId: \(routerInfo.threadId), messageId: \(routerInfo.messageId), sendMessageId: \(routerInfo.sendMessageId ?? ""), sendThreadId:\(routerInfo.sendThreadId ?? ""), labelId: \(routerInfo.labelId), accountId: \(routerInfo.accountId ?? ""), statFrom: \(routerInfo.statFrom) fromChat: \(routerInfo.fromChat)")

        if routerInfo.fromChat {
            MailTracker.log(event: "email_bot_card_action_click", params: ["click": "card_click", "thread_id": routerInfo.threadId, "target": "none",
                                                                           "mail_message_id": routerInfo.messageId, "action_type": "mail_detail"])
        }

        // 从push进入，需要标记给HomeVC，不触发切换lms账号逻辑
        self.tabVC?.mailHomeVC?.shouldChecklmsStatus = false

        switchToMailTabIfNeeded(routerInfo: routerInfo) { [weak self] in
            self?.dismissAccountMenu {
                self?.switchAccountIfNeeded(accountID: routerInfo.accountId, from: routerInfo.from, completion: { [weak self] in
                    self?.swapThreadIDAndMessageIDIfNeeded(routerInfo: routerInfo) { [weak self] (newThreadID, newMessageID) in
                        var newInfo = routerInfo
                        newInfo.threadId = newThreadID
                        newInfo.messageId = newMessageID
                        self?.showMailWrapper(routerInfo: newInfo)
                    }
                })
            }
        }
    }

    public func handleMailBotCard(routerInfo: MailDetailRouterInfo, action: MailBotAction) {
        guard let vc = routerInfo.from.fromViewController else {
            MailLogger.error("[mail_bot_card] NavigatorFrom fromViewController is nil")
            return
        }
        if let reachability = Reachability(), reachability.connection == .none {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_InternetCutOff_TryAgainLater_Text, on: vc.view)
            return
        }
        var scene: Email_Client_V1_MailGetMessageSuitableInfoRequest.Scene = .readMessage
        if action == .trash {
            scene = .delete
        } else if action == .spam {
            scene = .report
        }
        /// 500ms内不返回结果，则展示loading
        Observable.just(())
            .delay(.milliseconds(timeIntvl.normalMili), scheduler: MainScheduler.instance)
                .subscribe(onNext: { _ in
                    if let fromView = routerInfo.from.fromViewController?.view {
                        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_MailAssistant_Processing_Toast, on: fromView)
                    }
                    MailLogger.info("[mail_home] [mail_loading] did showing mailloading")
                }).disposed(by: loadingDisposeBag)

        switchAccountIfNeeded(accountID: routerInfo.accountId, skipFailPage: true, from: routerInfo.from, completion: { [weak self] in
            self?.swapThreadIDAndMessageIDIfNeeded(routerInfo: routerInfo, completion: { [weak self] (newThreadID, newMessageID) in
                var newInfo = routerInfo
                newInfo.threadId = newThreadID
                newInfo.messageId = newMessageID
                self?.getSuitableInfo(routerInfo: newInfo, scene: scene) { [weak self] (labelAndThread, resp) in
                    self?.loadingDisposeBag = DisposeBag()
                    if let fromView = newInfo.from.fromViewController?.view {
                        MailRoundedHUD.remove(on: fromView)
                    }
                    let labelID = labelAndThread.0
                    newInfo.labelId = labelID
                    newInfo.threadId = labelAndThread.1
                    guard let `self` = self else { return }
                    self.handleActions(action: action, vc: vc, labelID: labelID, newInfo: newInfo, resp: resp)
                }
            })
        })
    }

    private func handleActions(action: MailBotAction,
                               vc: UIViewController,
                               labelID: String,
                               newInfo: MailDetailRouterInfo,
                               resp: Email_Client_V1_MailGetMessageSuitableInfoResponse?) {
        MailTracker.log(event: "email_bot_card_action_click", params: ["click": "card_click", "thread_id": newInfo.threadId, "target": "none",
                                                                       "mail_message_id": newInfo.messageId, "action_type": action.actionType()])
        switch action {
        case .shareCard:
            guard !labelID.isEmpty else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MailAssistant_NoExistCantShare_Toast, on: vc.view)
                return
            }
            guard labelID != Mail_LabelId_Trash else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MailAssistant_DeletedCantShare_Toast, on: vc.view)
                return
            }
            guard labelID != Mail_LabelId_Spam else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MailAssistant_SpamCantShare_Toast, on: vc.view)
                return
            }
            self.userContext.provider.routerProvider?.forwardMailMessageShareBody(threadId: newInfo.threadId,
                                                                                  messageIds: [newInfo.messageId],
                                                                                  summary: newInfo.keyword, fromVC: vc)
        case .trash:
            guard !labelID.isEmpty else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MailAssistant_NoExistCantDelete_Toast, on: vc.view)
                return
            }
            if let replyDraftIDs = resp?.deleteInfo.replyDraftID, !replyDraftIDs.isEmpty {
                MailDataServiceFactory
                    .commonDataService?
                    .multiDeleteDraftForThread(threadIds: replyDraftIDs, fromLabelID: labelID)                                    .subscribe(onError: {_ in
                        InteractiveErrorRecorder.recordError(event: .thread_delete_forever_fail)
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MailAssistant_NoExistCantDelete_Toast, on: vc.view)
                    }, onCompleted: {
                        //MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DeleteThreadsSuccess, on: vc.view)
                    }).disposed(by: self.commonDisposeBag)
            }
            if labelID == Mail_LabelId_Trash || labelID == Mail_LabelId_Spam {
                /// 在已删除/垃圾邮件的时候执行永久删除
                let alert = LarkAlertController()
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThreadAction_DeleteForeverConfirm, alignment: .center)
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
                alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Delete, dismissCompletion: {
                    MailRoundedHUD.showLoading(on: vc.view, disableUserInteraction: false)
                    MailDataServiceFactory
                        .commonDataService?.deletePermanently(labelID: labelID, threadIDs: [newInfo.threadId])
                        .subscribe(onError: {_ in
                            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: vc.view,
                                                       event: ToastErrorEvent(event: .thread_delete_forever_fail,
                                                                              scene: .notification))
                        }, onCompleted: {
                            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DeleteThreadsSuccess, on: vc.view)
                        }).disposed(by: self.commonDisposeBag)
                })
                self.userContext.navigator.present(alert, from: newInfo.from)
            } else {
                MailDataServiceFactory
                    .commonDataService?
                    .multiMutLabelForThread(threadIds: [newInfo.threadId],
                                            messageIds: [newInfo.messageId],
                                            addLabelIds: [Mail_LabelId_Trash],
                                            removeLabelIds: [],
                                            fromLabelID: labelID,
                                            ignoreUnauthorized: false)
                    .subscribe(onNext: { (response) in
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_TrashToast, on: vc.view)
                    }, onError: { (error) in
                        MailLogger.error("[mail_bot_card] Send multiMutLabelForThread trash request failed error: \(error).")
                    }).disposed(by: self.commonDisposeBag)
            }
        case .spam:
            guard !labelID.isEmpty else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MailAssistant_NoExistCantSpam_Toast, on: vc.view)
                return
            }
            guard labelID != Mail_LabelId_Trash else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MailAssistant_DeletedCantSpam_Toast, on: vc.view)
                return
            }
            let isFromAuthorized = resp?.reportInfo.isFromAuthorized ?? false
            if isFromAuthorized {
                self.spamMail(threadID: newInfo.threadId, labelID: labelID, view: vc.view)
            } else {
                let content = SpamAlertContent(threadIDs: [newInfo.threadId], fromLabelID: labelID, isAllAuthorized: isFromAuthorized)
                LarkAlertController.showSpamAlert(type: .markSpam, content: content, from: newInfo.from, navigator: self.userContext.navigator, userStore: self.userContext.userKVStore, action: { [weak self] _ in
                    self?.spamMail(threadID: newInfo.threadId, labelID: labelID, view: vc.view)
                })
            }
        }
    }
    private func spamMail(threadID: String, labelID: String, view: UIView) {
        MailDataServiceFactory
            .commonDataService?
            .spam(threadID: threadID, fromLabelID: labelID, ignoreUnauthorized: false)
            .subscribe(onNext: { (_) in
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_MarkedAsSpam_Toast, on: view)
            }, onError: { (error) in
                MailLogger.error("[mail_bot_card] Send spam request failed error: \(error).")
            }).disposed(by: self.commonDisposeBag)
    }

    // 到设置页
    public func goSettingPage(from: NavigatorFrom, item: String) {
        if item == "notification" {
            let accountContext = userContext.getCurrentAccountContext()
            let pushSettingVC = MailPushSettingViewController(viewModel: MailSettingViewModel(accountContext: accountContext), accountContext: accountContext)
            userContext.navigator.push(pushSettingVC, from: from)
        } else {
            userContext.navigator.push(MailSettingWrapper.getSettingController(userContext: userContext), from: from)
        }
    }

    public func goSettingPage(from: NavigatorFrom) {
        userContext.navigator.push(MailSettingWrapper.getSettingController(userContext: userContext), from: from)
    }

    private func autoJumpSettingPageIfNeeded(from: NavigatorFrom, completion: @escaping () -> Void) {
        if !isInMailSetting() && !(manager.delegate?.isInMailTab ?? false) {
            /// 先切换到 mail setting, 再展示loading
            MailLogger.info("[mail_client_token] autoJumpSettingPage")
            let settingNav = LkNavigationController(rootViewController: MailSettingWrapper.getSettingController(userContext: userContext))
            settingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            userContext.navigator.present(settingNav, from: from, animated: true) {
                completion()
            }
        } else {
            MailLogger.info("[mail_client_token] no need to JumpSettingPage")
            /// 直接展示loading
            completion()
        }
    }

    private func isInMailSetting() -> Bool {
        let viewControllers = userContext.navigator.navigation?.viewControllers ?? []
        let presentViewControllers = (UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? LkNavigationController)?.viewControllers ?? []
        let presentingSettingOrMailClient = presentViewControllers.filter({ $0.isKind(of: MailSettingViewController.self) || $0.isKind(of: MailClientViewController.self) }).count > 0
        MailLogger.info("[mail_client_token] presentingSettingOrMailClient: \(presentingSettingOrMailClient)")
        return viewControllers.filter({ $0.isKind(of: MailSettingViewController.self) }).count > 0 || presentingSettingOrMailClient
    }

    public func handleTriClientOAuth(from: NavigatorFrom, state: String, urlString: String) {
        guard let info = Store.settingData.getOauthStateInfo(state: state) else {
            MailLogger.info("[mail_client_token] state info is lost")
            return
        }
        Store.settingData.deleteOauthState(state: state)
        autoJumpSettingPageIfNeeded(from: from) { [weak self] in
            self?.processTriClientOAuth(from: from, info: info, urlString: urlString)
        }
    }
    
    private func processTriClientOAuth(from: NavigatorFrom, info: MailClientAccountInfo, urlString: String) {
        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                if case .shareAccountChange(let change) = push {
                    if change.isBind {
                        self?.oauthLoadingVC?.dismiss(animated: false)
                        self?.oauthLoadingVC = nil
                    }
                }
            }).disposed(by: self.commonDisposeBag)

        let taskID = UUID().uuidString
        if !urlString.contains("error=access_denied") { // 取消跳转飞书不出loading
            if let oauthLoadingVC = oauthLoadingVC {
                MailRoundedHUD.showWarning(with: BundleI18n.MailSDK.Mail_ThirdClient_Second_AddAnotherLater_Toast, on: oauthLoadingVC.view)
                MailLogger.info("[mail_client_token] oauthLoadingVC is showing, no need to oauth verify")
                return
            } else {
                oauthLoadingVC = MailClientOAuthLoadingViewController() //contentHeight: Display.height)
                oauthLoadingVC?.modalPresentationStyle = .overFullScreen
                oauthLoadingVC?.taskID = taskID
                Observable.just(())
                    .delay(.milliseconds(timeIntvl.ultraShortMili), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        if let loading = self?.oauthLoadingVC {
                            self?.userContext.navigator.present(loading, from: from)
                        }
                    }).disposed(by: self.authLoadingDisposeBag)
            }
        }
        oauthLoadingVC?.closeHandler = { [weak self] in
            MailLogger.info("[mail_client_token] oauthLoadingVC closeHandler")
            guard let `self` = self else { return }
            if self.oauthLoadingVC?.needShowErrorAlert ?? false {
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_LoginFailed)
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_PleaseLogIntoAgain, alignment: .center)
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Close, dismissCompletion: nil)
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn, numberOfLines: 2, dismissCompletion: {
                    Store.settingData.tokenRelink(provider: info.provider, navigator: self.userContext.navigator, from: from)
                })
                self.userContext.navigator.present(alert, from: from)
            }
            self.oauthLoadingVC = nil
        }

        var account = MailClientTripartiteProviderHelper.makeDefaultAccount(type: info.provider, address: info.address, protocolConfig: info.protocolConfig)
        var pass = Email_Client_V1_LoginPass()
        pass.type = .token
        account.pass = pass
        let oauthParams = urlString
        if info.accountID.isEmpty { // 新登录账号，AccountID为空字符串
            if let presentVC = (UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? LkNavigationController)?.viewControllers.last ?? userContext.navigator.navigation?.viewControllers.first,
            let count = Store.settingData.getCachedAccountList()?.filter({ $0.mailSetting.userType == .tripartiteClient }).count {
                guard count < 5 else {
                    self.oauthLoadingVC?.dismiss(animated: false)
                    self.oauthLoadingVC = nil
                    MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ThirdClient_AddEmailAccountsDesc, on: presentVC.view)
                    return
                }
            }
            let event = MailAPMEvent.MailClientCreateAccount()
            event.markPostStart()
            apmHolder[MailAPMEvent.MailClientCreateAccount.self] = event
            MailLogger.info("[mail_client_token] handleTriClientOAuth - createTripartiteAccount oauthParams: \(oauthParams) protocolConfig: \(info.protocolConfig)")
            Store.fetcher?.createTripartiteAccount(taskID: taskID, account: account, oauthParams: oauthParams)
                .subscribe(onNext: { [weak self] (response) in
                    if response.status == .success {
                        MailLogger.info("[mail_client_token] login success")
                        self?.clientBaseApmInfoFill(pass, account)
                        event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                        event.postEnd()
                        self?.oauthLoadingVC?.dismiss(animated: false)
                        self?.oauthLoadingVC = nil
                        MailTracker.log(event: "email_tripartite_service_login_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "protocol": info.protocolConfig == .exchange ? "eas" : "imap", "target": "none", "login_result": "success"])
                    } else {
                        MailLogger.error("[mail_client_token] login fail status: \(response.status)")
                        self?.clientBaseApmInfoFill(pass, account)
                        event.endParams.appendError(errorCode: response.status.errorCode(), errorMessage: response.msg)
                        event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                        event.postEnd()
                        MailTracker.log(event: "email_tripartite_service_login_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "protocol": info.protocolConfig == .exchange ? "eas" : "imap", "target": "none", "login_result": "failed"])
                        self?.handleCreateTripartiteAccountErr(from: from, info: info, errorStatus: response.status, msg: response.msg)
                    }
            }, onError: { [weak self] (error) in
                MailLogger.error("[mail_client_token] login fail", error: error)
                self?.clientBaseApmInfoFill(pass, account)
                event.endParams.appendError(error: error)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event.postEnd()
                MailTracker.log(event: "email_tripartite_service_login_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "protocol": info.protocolConfig == .exchange ? "eas" : "imap", "target": "none", "login_result": "failed"])
                self?.handleCreateTripartiteAccountErr(from: from, info: info, errorStatus: nil, msg: error.debugMessage)
            }).disposed(by: self.commonDisposeBag)
        } else {
            MailLogger.info("[mail_client_token] handleTriClientOAuth - updateTripartiteConfig accountID: \(info.accountID) oauthParams: \(oauthParams)")
            Store.fetcher?.updateTripartiteAccountConfig(accountID: info.accountID, taskID: taskID, oauthParams: oauthParams)
                .subscribe(onNext: { [weak self] (response) in
                    if response.status == .success {
                        MailLogger.info("[mail_client_token] update OAuth success")
                        self?.oauthLoadingVC?.dismiss(animated: false)
                        self?.oauthLoadingVC = nil
                    } else {
                        MailLogger.error("[mail_client_token] update OAuth fail status: \(response.status)")
                        self?.oauthLoadingVC?.dismiss(animated: false, completion: { [weak self] in
                            let alert = LarkAlertController()
                            if response.status == .failForInconsistentAddress {
                                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_LoginExpired)
                                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_UsingDifferentAccountAddress(info.address), alignment: .center)
                            } else if response.status == .cancel {
                                MailLogger.info("[mail_client_token] update OAuth cancel")
                                return
                            } else if response.status == .failForUserReject {
                                return
                            } else {
                                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_LoginFailed)
                                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_PleaseLogIntoAgain, alignment: .center)
                            }
                            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Close, dismissCompletion: nil)
                            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn, numberOfLines: 2, dismissCompletion: {
                                guard let self = self else { return }
                                Store.settingData.tokenRelink(provider: info.provider, navigator: self.userContext.navigator, from: from, accountID: info.accountID)
                            })
                            self?.userContext.navigator.present(alert, from: from)
                        })
                        self?.oauthLoadingVC = nil
                    }
            }, onError: { [weak self] (error) in
                MailLogger.error("[mail_client_token] update OAuth fail", error: error)
                self?.oauthLoadingVC?.dismiss(animated: false, completion: { [weak self] in
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_LoginFailed)
                    alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_PleaseLogIntoAgain, alignment: .center)
                    alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Close, dismissCompletion: nil)
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn, numberOfLines: 2, dismissCompletion: {
                        guard let self = self else { return }
                        Store.settingData.tokenRelink(provider: info.provider, navigator: self.userContext.navigator, from: from, accountID: info.accountID)
                    })
                    self?.userContext.navigator.present(alert, from: from)
                })
                self?.oauthLoadingVC = nil
            }).disposed(by: self.commonDisposeBag)
        }
    }
    
    private func handleCreateTripartiteAccountErr(from: NavigatorFrom, info: MailClientAccountInfo, errorStatus:  Email_Client_V1_MailCreateTripartiteAccountResponse.Status?, msg: String?) {
        self.oauthLoadingVC?.dismiss(animated: false, completion: { [weak self] in
            guard let self = self else { return }
            let alert = LarkAlertController()
            var confirmText = ""
            if errorStatus == .failForDuplicatedAddress {
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_ErrorTitle)
                var tipAddress = info.address
                if let errorAddress = msg {
                    MailLogger.error("[mail_client_token] login with repeat address")
                    tipAddress = errorAddress
                }
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_EmailAccountAlreadyInUse_Text(tipAddress), alignment: .center)
                confirmText = BundleI18n.MailSDK.Mail_ThirdClient_EmailAccountAlreadyInUse_OK_Button
                alert.addPrimaryButton(text: confirmText, numberOfLines: 2, dismissCompletion: nil)
            } else if errorStatus == .cancel {
                MailLogger.info("[mail_client_token] login cancel")
                return
            } else if errorStatus == .failForUserReject {
                self.authLoadingDisposeBag = DisposeBag()
                return
            } else {
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_LoginFailed)
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_PleaseLogIntoAgain, alignment: .center)
                confirmText = BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Close, dismissCompletion: nil)
                alert.addPrimaryButton(text: confirmText, numberOfLines: 2, dismissCompletion: { [weak self] in
                    guard let self = self else { return }
                    Store.settingData.tokenRelink(provider: info.provider, navigator: self.userContext.navigator, from: from)
                })
            }
            self.userContext.navigator.present(alert, from: from)
        })
        self.oauthLoadingVC = nil
    }
    
    private func clientBaseApmInfoFill(_ pass: Email_Client_V1_LoginPass, _ account: Email_Client_V1_TripartiteAccount) {
        let provider = MailAPMEvent.MailClientCreateAccount.EndParam.provider(account.provider.apmValue() )
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(provider)
        let loginPassType = MailAPMEvent.MailClientCreateAccount.EndParam.login_pass_type(pass.type.apmValue() )
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(loginPassType)
        let protocolType = MailAPMEvent.MailClientCreateAccount.EndParam.client_protocol(account.apmProtocolValue())
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(protocolType)
        let receiverEncryptionType = MailAPMEvent.MailClientCreateAccount.EndParam.client_protocol(account.receiver.apmEncryptionValue())
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(receiverEncryptionType)
        let senderEncryptionType = MailAPMEvent.MailClientCreateAccount.EndParam.client_protocol(account.sender.apmEncryptionValue())
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(senderEncryptionType)
    }

    private static var lastThreadWrapperTimeStamp: TimeInterval?
    func goToMsgListVCFromFeedCard(feedCardId: String, name: String, address: String, from: NavigatorFrom, avatar: String, fromNotice: Int, fromScene: Bool) {
        vcDisposeBag = DisposeBag()
        MailDataSource.shared.fetcher?.getFollowingListByID(feedCardId: feedCardId)
            .observeOn(MainScheduler.instance)
            .subscribe { (getName, getAddress) in
                jumpToMailMessageListcontroller(feedCardId: feedCardId, name: getName, address: getAddress, from: from, avatar: avatar)
            } onError: { e in
                MailLogger.info("getFollowingListByID, error: \(e)")
                jumpToMailMessageListcontroller(feedCardId: feedCardId, name: name, address: address, from: from, avatar: avatar)
        }.disposed(by: self.vcDisposeBag)
        
        func jumpToMailMessageListcontroller(feedCardId: String, name: String, address: String, from: NavigatorFrom, avatar: String) {
            MailLogger.info("[Mail jumpToFeed] fromNotice:\(fromNotice)")
            let vc = MailMessageListController.makeForFeed(accountContext: userContext.getCurrentAccountContext(),
                                                           messageListFeedInfo: MessageListFeedInfo(feedCardId: feedCardId, name: name, address: address, avatar: avatar),
                                                           statInfo: MessageListStatInfo(from: .feed, newCoreEventLabelItem: "none"),
                                                           forwardInfo: nil,
                                                           fromNotice: fromNotice)
            if Display.pad && !fromScene  {
                userContext.navigator.showDetail(vc, from: from)
            } else {
                userContext.navigator.push(vc, from: from)
            }
        }
    }

    func goToMsgListVCFromSendChatCard(threadId: String, cardId: String, ownerId: String, from: NavigatorFrom) {
        let vc = MailMessageListController.makeForRouter(accountContext: userContext.getCurrentAccountContext(),
                                                         threadId: threadId,
                                                         labelId: Mail_LabelId_SEARCH,
                                                         statInfo: MessageListStatInfo(from: .chat, newCoreEventLabelItem: "none"),
                                                         forwardInfo: DataServiceForwardInfo(cardId: cardId, ownerUserId: ownerId))
        userContext.navigator.push(vc, from: from)
        // product statistic
        MailTracker.log(event: Homeric.EMAIL_SEND2CHAT_CLICK, params: ["message_card_id": cardId])
    }

    public func goToMailApprovalFromChat(instanceCode: String, from: NavigatorFrom) {
        // go to msgList
        let vc = EmlPreviewViewController.approvalReview(accountContext: userContext.getCurrentAccountContext(), instanceCode: instanceCode)
        if Display.pad {
            userContext.navigator.showDetail(vc, wrap: MailMessageListNavigationController.self, from: from)
        } else {
            userContext.navigator.push(vc, from: from)
        }
    }
    
    public func jumpToFeedMailReadViewController(feedCardId: String, name: String = "", address: String = "", from: NavigatorFrom, avatar: String = "", fromNotice: Int = 0, fromScene: Bool = false) {
        self.switchToMainAccount().subscribe(onError: { [weak self] err in
                self?.goToMsgListVCFromFeedCard(feedCardId: feedCardId, name: name, address: address, from: from, avatar: avatar, fromNotice: fromNotice, fromScene: fromScene)
                MailLogger.info("[Mail jumpToFeed] fromNotice:\(fromNotice)")
                MailLogger.error("jumpToMailMessageListViewController", error: err)
            }, onCompleted: { [weak self] in
                MailLogger.info("jumpToMailMessageList onCompleted")
                MailLogger.info("[Mail jumpToFeed] fromNotice:\(fromNotice)")
                self?.goToMsgListVCFromFeedCard(feedCardId: feedCardId, name: name, address: address, from: from, avatar: avatar, fromNotice: fromNotice, fromScene: fromScene)
            }).disposed(by: self.vcDisposeBag)
    }
    
    enum MailAccountError : Error {
        case noPrimaryAddress
    }
    
    func switchToMainThenCheckValid() -> Observable<Void> {
        return self.switchToMainAccount().flatMap { (_) -> Observable<Void> in
            if let setting = Store.settingData.getCachedCurrentSetting(),
                setting.userType == .newUser ||
            setting.userType == .exchangeClientNewUser ||
            setting.userType == .noPrimaryAddressUser {
                return Observable.error(MailAccountError.noPrimaryAddress)
            }
            return Observable.empty()
        }
    }
    func showTips(text: String, successTips: Bool, from: NavigatorFrom) {
        if let view = from.fromViewController?.view {
            self.dismissProcessLoading(from)
            if successTips {
                MailRoundedHUD.showSuccess(with: text, on: view)
            } else {
                MailRoundedHUD.showFailure(with: text, on: view)
            }
        }
    }
    
    func switchToMainAccount() -> Observable<Void> {
        return Store.settingData.getAccountList()
            .flatMap { (_, lists) -> Observable<Void> in
                guard let primaryAccountID = lists.first?.mailAccountID else {
                    mailAssertionFailure("switchToMainAccount missing id")
                    return Observable.empty()
                }
                guard let primaryAccount = lists.first(where: { !$0.isShared }) else {
                    mailAssertionFailure("switchToMainAccount primaryAccount is nil accountList: \(lists.map({ $0.mailAccountID }))")
                    return Observable.empty()
                }
                // 若未启动mailtab业务，需要先手动更新共存状态
                Store.settingData.updateCachedCurrentAccount(primaryAccount, accountList: primaryAccount.sharedAccounts)
                Store.settingData.updateClientStatusIfNeeded()
                // 切账号。
                return Store.settingData.switchMailAccount(to: primaryAccountID)
                    .map { _ in () }
                    .do(onNext: {
                        NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                })
            }
    }
    
    func showLoadingWithMaxDuration(from: NavigatorFrom, duration: Int) {
        guard let view = from.fromViewController?.view else { return }
        let processing = BundleI18n.MailSDK.Mail_MyAIInEmail_Processing_Toast
        MailRoundedHUD.showLoading(with: processing, on: view, disableUserInteraction: false)
        processingBag = DisposeBag()
        // 30s后去除loading，避免loading没有消除的case
        Observable.just(())
            .delay(.seconds(duration), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.dismissProcessLoading(from)
                }).disposed(by: processingBag)
    }
    
    public func aiCreateTask(id: String, from: NavigatorFrom) {
        MailLogger.info("[AIScene] create task id \(id)")
        let errMsg = self.checkIdValid(id: id, isTask: true)
        if !errMsg.isEmpty {
            self.showTips(text: errMsg, successTips: false, from: from)
            return
        }
        self.showLoadingWithMaxDuration(from: from, duration: timeIntvl.largeSecond)
        let noService = BundleI18n.MailSDK.Mail_MyAIInEmail_YouCurrentlyDoNotHavePermissionToAccessEmail_Toast
        self.switchToMainThenCheckValid().subscribe(onError: { [weak self] err in
            MailLogger.error("[AIScene] aiCreateTask switch account err: ", error: err)
            self?.showTips(text: noService, successTips: false, from: from)
        }, onCompleted: { [weak self] in
            MailLogger.info("[AIScene] aiCreateTask switch account onCompleted")
            self?.sendCreateTaskReq(id: id, from: from)
        }).disposed(by: self.vcDisposeBag)
    }
    
    private func sendCreateTaskReq(id: String, from: NavigatorFrom) {
        MailDataServiceFactory
            .commonDataService?.getAITaskId(id: id)
            .subscribe(onNext: { [weak self] (resp) in
                MailLogger.info("[AIScene] sendCreateTaskReq succ")
                self?.presentTodoTask(summary: resp.title, from: from)
            }, onError: { [weak self] (error) in
                MailLogger.info("[AIScene] sendCreateTaskReq error: \(error)")
                self?.showTips(text: BundleI18n.MailSDK.Mail_Toast_OperationFailed, successTips: false, from: from)
            }).disposed(by: commonDisposeBag)
    }
    private func presentTodoTask(summary: String, from: NavigatorFrom) {
        self.dismissProcessLoading(from)
        let domain = ConfigurationManager.shared.settings
        if let linkArray = domain["applink"] as? [String],
            let link = linkArray.first {
            let urlStr = "https://" + link + "/client/todo/create?summary=\(summary)"
            guard let encodedURLString  = urlStr.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed),
                    let url = URL(string: encodedURLString) else {
                        MailLogger.info("[AIScene] parseUrl fail)")
                        self.showTips(text: BundleI18n.MailSDK.Mail_Toast_OperationFailed, successTips: false, from: from)
                        return
                    }
            self.userContext.getCurrentAccountContext().navigator.push(url, from: from)
        }
    }
    private func checkIdValid(id: String, isTask: Bool) -> String {
        var errMsg = ""
        var invalid = false
        var outOfDate = false
        // id检查
        if let timeStr = id.split(separator: "_").first,
                    let timeInt = Int(timeStr) {
            if Int(Date().timeIntervalSince1970) > timeInt {
                //过期
                outOfDate = true
            }
        } else {
            invalid = true
        }
        if outOfDate || invalid {
            if isTask {
                return BundleI18n.MailSDK.Mail_MyAIInEmail_ContentExpiredPleaseCreateTaskManually_Toast
            } else {
                return BundleI18n.MailSDK.Mail_MyAIInEmail_ContentExpiredPleaseRegerateDraft_Toast
            }
        }
        return errMsg
    }
    public func aiCreateDraft(id: String, from: NavigatorFrom) {
        let errMsg = self.checkIdValid(id: id,isTask: false)
        if !errMsg.isEmpty {
            self.showTips(text: errMsg, successTips: false, from: from)
            return
        }
        self.showLoadingWithMaxDuration(from: from, duration: timeIntvl.largeSecond)
        let noService = BundleI18n.MailSDK.Mail_MyAIInEmail_YouCurrentlyDoNotHavePermissionToAccessEmail_Toast
        self.switchToMainThenCheckValid().subscribe(onError: { [weak self] err in
            MailLogger.error("[AIScene] aiCreateDraft switch account err: ", error: err)
            self?.showTips(text: noService, successTips: false, from: from)
        }, onCompleted: { [weak self] in
            MailLogger.info("[AIScene] aiCreateDraft switch account onCompleted")
            self?.sendCreateDraftReq(id: id, from: from)
        }).disposed(by: self.vcDisposeBag)
    }
    private func sendCreateDraftReq(id: String, from: NavigatorFrom) {
        MailDataServiceFactory
            .commonDataService?.getAIDraftContent(id: id)
            .subscribe(onNext: { [weak self] (resp) in
                MailLogger.info("[AIScene] sendCreateDraftReq succ")
                self?.dismissProcessLoading(from)
                self?.presentSendVC(resp: resp, from: from)
            }, onError: { [weak self] (error) in
                MailLogger.info("[AIScene] sendCreateDraftReq error: \(error)")
                self?.showTips(text: BundleI18n.MailSDK.Mail_Toast_OperationFailed, successTips: false, from: from)
            }).disposed(by: commonDisposeBag)
    }
    private func presentSendVC(resp: MailAIGetDraftResp, from: NavigatorFrom) {
        let vc = MailSendController.makeSendNavController(accountContext: userContext.getCurrentAccountContext(), action: .fromAIChat, labelId: Mail_LabelId_Inbox, statInfo: MailSendStatInfo(from: .routerPullUp, newCoreEventLabelItem: "none"), trackerSourceType: .mailAIChat, sendToAddress: nil, subject: resp.subject.isEmpty ? nil : resp.subject, body: resp.body.isEmpty ? nil : resp.body, cc: nil, bcc: nil, fileBannedInfos: nil)
        userContext.navigator.present(vc, from: from)
    }
    public func aiMarkAllRead(msgArray: [[String: Any]], from: NavigatorFrom) {
        MailLogger.info("[AIScene] mark all read msg=\(msgArray)")
        var array:[ThreadMsgsItem] = []
        for msg in msgArray {
            if let id = msg["thread_biz_id"] as? String,
               let msgIds = msg["message_biz_ids"] as? [String]  {
                var item = ThreadMsgsItem()
                item.threadID = id
                item.messageIds = msgIds
                array.append(item)
            }
        }
        
        if array.isEmpty {
            MailLogger.info("[AIScene] mark all read param err")
            let markReadFail = BundleI18n.MailSDK.Mail_MyAIInEmail_UnableToMarkPleaseTryAgainLater_Toast
            self.showTips(text: markReadFail, successTips: false, from: from)
            return
        }
        if let view = from.fromViewController?.view {
            MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_MyAIInEmail_Processing_Toast, on: view, disableUserInteraction: false)
        }
        MailLogger.info("[AIScene] mark all req begin")
        MailDataServiceFactory
            .commonDataService?.markAllRead(msgArray: array)
            .subscribe(onNext: {  [weak self] (_) in
                MailLogger.info("[AIScene] aiMarkAllRead succ")
                self?.showTips(text: BundleI18n.MailSDK.Mail_MyAIInEmail_MarkedAsRead_Toast, successTips: true, from: from)
            }, onError: { [weak self] (error) in
                MailLogger.info("[AIScene] aiMarkAllRead error: \(error)")
                self?.showTips(text: BundleI18n.MailSDK.Mail_MyAIInEmail_UnableToMarkPleaseTryAgainLater_Toast, successTips: false, from: from)
            }).disposed(by: commonDisposeBag)
    }

    public func canSwitchToMailTab(from: NavigatorFrom) -> Bool {
        if manager.delegate == nil || manager.delegate?.hasMailTab == true {
            return true
        }
        if let view = from.fromViewController?.view {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_MyAI_EnterAQuestion_UnableToAddEmailTabPleaseAddEmailTabToNavigationBarFirst_Toast,
                                       on: view)
        }
        return false
    }

    public func jumpToMailMessageListViewController(threadId: String, cardId: String, ownerId: String, from: NavigatorFrom) {
        Store.settingData.getAccountList()
            .flatMap { (currentAccountId, lists) -> Observable<Void> in
                guard let primaryAccountID = lists.first?.mailAccountID else {
                    mailAssertionFailure("missing id")
                    return Observable.empty()
                }
                guard let primaryAccount = lists.first(where: { !$0.isShared }) else {
                    mailAssertionFailure("primaryAccount is nil accountList: \(lists.map({ $0.mailAccountID }))")
                    return Observable.empty()
                }
                // 若未启动mailtab业务，需要先手动更新共存状态
                Store.settingData.updateCachedCurrentAccount(primaryAccount, accountList: primaryAccount.sharedAccounts)
                Store.settingData.updateClientStatusIfNeeded()
                // 纯三方场景，不支持打开sendToChat, 且不切主账号
                if Store.settingData.clientStatus == .mailClient {
                    return Observable.empty()
                } else if lists.count > 1 && lists.first?.accountSelected.isSelected != true {
                    return Store.settingData.switchMailAccount(to: primaryAccountID)
                        .map { _ in () }
                        .do(onNext: {
                            MailLogger.info("jumpToMailMessageList switch account onNext")
                            NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                        })
                } else {
                    return Observable.empty()
                }
            }.subscribe(onError: { [weak self] err in
                self?.goToMsgListVCFromSendChatCard(threadId: threadId, cardId: cardId, ownerId: ownerId, from: from)
                MailLogger.error("jumpToMailMessageListViewController", error: err)
            }, onCompleted: { [weak self] in
                MailLogger.info("jumpToMailMessageList onCompleted")
                self?.goToMsgListVCFromSendChatCard(threadId: threadId, cardId: cardId, ownerId: ownerId, from: from)
            }).disposed(by: self.vcDisposeBag)
    }

    public func presentMailDebugger() {
        #if ALPHA || DEBUG
        let vc = MailDebugViewController()
        vc.modalPresentationStyle = .fullScreen
        if let fromVC = userContext.navigator.mainSceneWindow?.fromViewController {
            userContext.navigator.present(UINavigationController(rootViewController: vc),from: fromVC)
        } else {
            MailLogger.error("presentMailDebugger mainScene window not found!")
        }
        #endif
    }
}

private extension MailSDKManager {
    func switchToMailTabIfNeeded(routerInfo: MailDetailRouterInfo, completion: @escaping () -> Void) {
        if let tab = routerInfo.tab, manager.delegate?.isInMailTab == false && needSwitchTab(routerInfo) {
            /// 先切换到 mail tab 再跳转到邮件内容页/草稿页
            MailLogger.info("mail notification switch mail tab first")
            userContext.navigator.switchTab(tab, from: routerInfo.from, animated: true) { _ in
                completion()
            }
        } else {
            /// 直接显示邮件内容页/草稿页面
            completion()
        }
    }

    private func needSwitchTab(_ routerInfo: MailDetailRouterInfo) -> Bool {
        return !routerInfo.multiScene && !routerInfo.fromChat && routerInfo.statFrom != "search"
    }

    func dismissAccountMenu(completion: @escaping () -> Void) {
        if let homeVC = self.tabVC?.mailHomeVC, let accountListMenu = homeVC.accountListMenu, homeVC.presentedViewController == accountListMenu {
            MailLogger.info("mail notification accountListMenu exist")
            accountListMenu.dismiss(animated: false) {
                MailLogger.info("mail notification accountListMenu dismiss and switchAccountThenShowMailWrapper")
                completion()
            }
        } else {
            completion()
        }
    }

    /// 切换到打开信所属账号
    func switchAccountIfNeeded(accountID: String?, skipFailPage: Bool = false, from: NavigatorFrom, completion: @escaping () -> Void) {
        if let theAccountId = accountID, !theAccountId.isEmpty {
            accountDisposeBag = DisposeBag()
            MailLogger.info("mail notification get account list for account: \(theAccountId)")
            Store.settingData
                .getAccountList()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self](resp) in
                    guard let `self` = self else { return }
                    /// if is not current account id, switch
                    if resp.currentAccountId != theAccountId {
                        /// swift to main account
                        Store.settingData
                            .switchMailAccount(to: theAccountId)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { (_) in
                                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
                                MailLogger.info("mail notification switch account id \(theAccountId)")
                                completion()
                            },
                            onError: { [weak self] (error) in
                                guard let self = self else { return }
                                MailLogger.error("mail notification switch error account id \(theAccountId)")
                                if self.userContext.featureManager.open(FeatureKey(fgKey: .openBotDirectly, openInMailClient: false)) {
                                    self.dismissProcessLoading(from)
                                    self.userContext.navigator.push(MailMessageListLoadFailController(errorType: .accountError, accountContext: self.userContext.getCurrentAccountContext()), from: from)
                                } else {
                                    completion()
                                }
                            }).disposed(by: self.accountDisposeBag)
                    } else {
                        if self.userContext.featureManager.open(FeatureKey(fgKey: .openBotDirectly, openInMailClient: false)),
                           let setting = Store.settingData.getCachedCurrentSetting(),
                           setting.userType == .newUser || setting.userType == .exchangeClientNewUser || setting.userType == .noPrimaryAddressUser {
                            self.dismissProcessLoading(from)
                            if skipFailPage {
                                completion()
                            } else {
                                self.userContext.navigator.push(MailMessageListLoadFailController(errorType: .accountError, accountContext: self.userContext.getCurrentAccountContext()), from: from)
                            }
                        } else {
                            MailLogger.info("mail notification same accountId")
                            completion()
                        }
                    }
                }).disposed(by: accountDisposeBag)
        } else {
            completion()
        }
    }

    /// 会话模式需要将 threadID 替换为 messageID
    /// 自己发自己需要将 messageID 替换为 sendMessageID
    func swapThreadIDAndMessageIDIfNeeded(routerInfo: MailDetailRouterInfo, completion: @escaping (String, String) -> Void) {
        fetchCurrentSetting { currentSetting in
            if let setting = currentSetting {
                if routerInfo.labelId == Mail_LabelId_Stranger && !routerInfo.threadId.isEmpty {
                    completion(routerInfo.threadId, routerInfo.messageId)
                } else if !setting.enableConversationMode, !routerInfo.messageId.isEmpty { // 非会话模式下需要忽略thread id
                    MailLogger.info("mail notification not enableConversationMode change threadID \(routerInfo.threadId)")
                    completion(routerInfo.messageId, routerInfo.messageId)
                } else {
                    if let sendMessageId = routerInfo.sendMessageId, !sendMessageId.isEmpty,
                       let sendThreadId = routerInfo.sendThreadId, !sendThreadId.isEmpty {
                        completion(sendThreadId, sendMessageId)
                    } else {
                        completion(routerInfo.threadId, routerInfo.messageId)
                    }
                }
            } else {
                MailLogger.error("mail notification getCurrentSetting from net error threadId \(routerInfo.threadId)")
                completion(routerInfo.threadId, routerInfo.messageId)
            }
        }
    }

    func dismissProcessLoading(_ from: NavigatorFrom) {
        self.loadingDisposeBag = DisposeBag()
        if let fromView = from.fromViewController?.view {
            MailRoundedHUD.remove(on: fromView)
        }
    }

    func getSuitableInfo(routerInfo: MailDetailRouterInfo, scene: Email_Client_V1_MailGetMessageSuitableInfoRequest.Scene,
                         completion: @escaping ((String, String), Email_Client_V1_MailGetMessageSuitableInfoResponse?) -> Void) {
        vcDisposeBag = DisposeBag()
        Store.fetcher?.getMessageSuitableInfo(messageId: routerInfo.messageId, threadId: routerInfo.threadId, scene: scene)
            .subscribe(onNext: { (resp) in
                completion((resp.label, resp.threadID), resp)
            }, onError: { (error) in
                MailLogger.info("[mail_bot_card] mail getMessageSuitableLabel error: \(error)")
                completion(("", routerInfo.threadId), nil)
            }).disposed(by: vcDisposeBag)
    }

    func fetchCurrentSetting(completion: @escaping (MailSetting?) -> Void) {
        // 如果有setting，尽快返回
        if let currentSetting = Store.settingData.currentAccount.value?.mailSetting {
            MailLogger.info("mail notification getCurrentSetting from cache")
            completion(currentSetting)
        } else {
            Store.settingData.getCurrentSetting(fetchDb: false).subscribe(onNext: { (setting) in
                completion(setting)
            }, onError: { [weak self] (err) in
                guard let self = self else { return }
                MailLogger.error("mail notification getCurrentSetting from net error: \(err)")
                Store.settingData.getCurrentSetting(fetchDb: true).subscribe(onNext: { (setting) in
                    completion(setting)
                }, onError: { (err) in
                    MailLogger.error("mail notification getCurrentSetting from db error: \(err)")
                    completion(nil)
                }).disposed(by: self.vcDisposeBag)
            }).disposed(by: vcDisposeBag)
        }
    }

    func showMailWrapper(routerInfo: MailDetailRouterInfo) {
        vcDisposeBag = DisposeBag()

        var statInfo: MessageListStatInfo
        if let from = MessageListStatInfo.FromType.init(rawValue: routerInfo.statFrom) {
            statInfo = MessageListStatInfo(from: from, newCoreEventLabelItem: routerInfo.labelId)
        } else {
            statInfo = MessageListStatInfo(fromString: routerInfo.statFrom, from: .other, newCoreEventLabelItem: routerInfo.labelId)
        }
        statInfo.startTime = routerInfo.startTime

        tabVC?.mailHomeVC?.dismissAccountDropMenu()
        var delayPush = false
        if let vc = routerInfo.from.fromViewController,
           let topVC = WindowTopMostFrom(vc: vc).fromViewController,
           let sendVC = topVC.presentingViewController,
           sendVC.tkClassName == MailSDKManager.Keys.sendVCNavigator {
            topVC.dismiss(animated: false, completion: nil)
            delayPush = true
        }

        let forwardInfo: DataServiceForwardInfo?
        if let cardId = routerInfo.cardId, let ownerId = routerInfo.ownerId {
            forwardInfo = DataServiceForwardInfo(cardId: cardId, ownerUserId: ownerId)
        } else {
            forwardInfo = nil
        }
        var viewController : MailMessageListController
        if (routerInfo.feedCardId.isEmpty) {
            viewController = MailMessageListController.makeForRouter(accountContext: userContext.getCurrentAccountContext(),
                                                                         threadId: routerInfo.threadId,
                                                                         labelId: routerInfo.labelId,
                                                                         messageId: routerInfo.messageId,
                                                                         keyword: routerInfo.keyword,
                                                                         statInfo: statInfo,
                                                                         forwardInfo: forwardInfo)
        } else {
            let messageListFeedInfo = MessageListFeedInfo(feedCardId: routerInfo.feedCardId)
            viewController = MailMessageListController.makeForFeed(accountContext: userContext.getCurrentAccountContext(),
                                                                   messageListFeedInfo: messageListFeedInfo,
                                                                   statInfo: statInfo,
                                                                   forwardInfo: forwardInfo)
        }

        viewController.messageId = routerInfo.messageId

        if userContext.featureManager.open(FeatureKey(fgKey: .openBotDirectly, openInMailClient: false)) {
            if Display.pad && !routerInfo.multiScene && !routerInfo.fromChat {
                userContext.navigator.showDetail(viewController, wrap: MailMessageListNavigationController.self, from: routerInfo.from)
            } else {
                if delayPush {
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
                        self?.userContext.navigator.push(viewController, from: routerInfo.from)
                    }
                } else {
                    userContext.navigator.push(viewController, from: routerInfo.from)
                }
            }
            return
        }

        /// 以下为旧逻辑
        /// 结合以下两个函数的条件可以得到下表
        /// pad     &&  multiScene  &&  fromChat    ->  push
        /// pad     &&  multiScene  &&  !fromChat   ->  push
        /// pad     &&  !multiScene &&  fromChat    ->  push
        /// pad     &&  !multiScene &&  !fromChat   ->  showDetail
        /// !pad    &&  multiScene  &&  fromChat    ->  push
        /// !pad    &&  multiScene  &&  !fromChat   ->  push
        /// !pad    &&  !multiScene &&  fromChat    ->  push + switch   ->  push [本次修改]
        /// !pad    &&  !multiScene &&  !fromChat   ->  push

        if Display.pad && !routerInfo.multiScene {
            if routerInfo.fromChat {
                userContext.navigator.push(viewController, from: routerInfo.from)
            } else {
                userContext.navigator.showDetail(viewController, wrap: MailMessageListNavigationController.self, from: routerInfo.from)
            }
        } else {
            if delayPush {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
                    self?.userContext.navigator.push(viewController, from: routerInfo.from) { [weak self] in
                        self?.asyncSwitchTabIfNeeded(routerInfo: routerInfo)
                    }
                }
            } else {
                userContext.navigator.push(viewController, from: routerInfo.from) { [weak self] in
                    self?.asyncSwitchTabIfNeeded(routerInfo: routerInfo)
                }
            }
        }
    }

    func asyncSwitchTabIfNeeded(routerInfo: MailDetailRouterInfo) {
        if routerInfo.multiScene || Display.pad {
            return
        }
        MailLogger.info("mail notification switch mail tab async -- tab: \(routerInfo.tab?.safeURLString ?? "") fromChat: \(routerInfo.fromChat)")
        if let tab = routerInfo.tab, routerInfo.fromChat {
            let viewControllers = userContext.navigator.navigation?.viewControllers ?? []
            if viewControllers.count > 1 {
                userContext.navigator.navigation?.setViewControllers([viewControllers.first, viewControllers.last].compactMap { $0 }, animated: false)
            } else {
                MailLogger.error("mail notification switch mail tab async -- vc: \(viewControllers)")
            }
            if let url = URL(string: tab.safeURLString) {
                userContext.navigator.switchTab(url, from: routerInfo.from, animated: false, completion: nil)
            }
        }
    }
}

extension Email_Client_V1_MailCreateTripartiteAccountResponse.Status {
    func errorCode() -> Int {
        if self == .failForUserReject {
            return MailErrorCode.createTripartiteAccountReject
        } else if self == .failForDuplicatedAddress {
            return MailErrorCode.createTripartiteAccountDuplicated
        } else if self == .cancel {
            return MailErrorCode.createTripartiteAccountCancel
        } else {
            return 0
        }
    }
}
