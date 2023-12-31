//
//  MailHomeController+VM.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/12/3.
//

import Foundation
import LarkUIKit
import EENavigator
import Reachability
import LKCommonsLogging
import RxSwift
import Homeric
import LarkAlertController
import RustPB
import LarkKeyCommandKit
import LarkFoundation
import ESPullToRefresh
import RxRelay
import UniverseDesignIcon
import LarkGuideUI

/// 抽离VM未完成解耦，其中与VC耦合的部分放这里
extension MailHomeController {
    func didSelectFilter(filterType: MailThreadFilterType, loadData: Bool, showLoading: Bool = true) {
        MailLogger.info("[mail_home] didSelectFilter filterType: \(filterType) loadData: \(loadData)")
        /// UI change
        if filterType == .unread {
            updateTableViewHeader(with: tableHeaderView.showFilterTips())
        } else {
            updateTableViewHeader(with: tableHeaderView.dismissFilterTips())
        }
        /// filter button
        setFilterButtonType(seleted: filterType != .allMail)
        if loadData {
            if filterType == .allMail {
                viewModel.apmMarkThreadListStart(sence: .sence_filter_all)
            } else {
                viewModel.apmMarkThreadListStart(sence: .sence_filter_unread)
            }
            let title = viewModel.currentLabelName.isEmpty ? BundleI18n.MailSDK.Mail_Folder_Inbox : viewModel.currentLabelName
            switchLabelAndFilterType(viewModel.currentLabelId, labelName: title, filterType: filterType)
            /// load data
            refreshListDataReady.accept((.switchFilter, false))
            loadThreadListData(labelId: viewModel.currentLabelId, filterType: filterType, title: title, showLoading: showLoading)
        }
    }

    func updateLabelListFgDataError(_ error: Bool) {
        self.labelListFgDataError = error
        self.labelsMenuController?.fgDataError = error
    }

    func updateLabelListSmartInboxFlag(_ enable: Bool) {
        self.labelsMenuController?.smartInboxModeEnable = enable
    }

    func updateTitle(_ title: String) {
        DispatchQueue.main.async { // 5.1暂时这样写，保证lazy的behavior变量线程安全
            self._updateTitle(title)
        }
    }

    func setFilterButtonType(seleted: Bool) {
        if seleted {
            navFilterButton.tintColor = UIColor.ud.primaryContentDefault
            navFilterButton.setImage(UDIcon.filterOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault), for: .normal)
        } else {
            navFilterButton.tintColor = UIColor.ud.iconN2
            navFilterButton.setImage(UDIcon.filterOutlined.ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        }
        navFilterButton.layoutIfNeeded()
        navFilterButton.setNeedsLayout()
        if !seleted {
            reloadNavbar()
        }
    }

    /// show filter popup menu
    func showFilterPopupMenu(filterTypes: [MailThreadFilterType]) {
        var vc: UIViewController
        var items: [PopupMenuActionItem] = []
        for filterType in filterTypes {
            if let item = createPopupMenu(filterType: filterType) {
                items.append(item)
            }
        }
        if rootSizeClassIsSystemRegular {
            vc = PopupMenuPoverViewController(items: items)
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            vc.popoverPresentationController?.sourceView = navFilterButton
            vc.popoverPresentationController?.sourceRect = navFilterButton.bounds
        } else {
            vc = PopupMenuViewController(items: items)
            vc.modalPresentationStyle = .overFullScreen
        }
        navigator?.present(vc, from: self, animated: false)
    }

    // Share Accounts
    func updateMultiAccountView(_ account: MailAccount, showBadge: (count: Int64, isRed: Bool)) {
        var address = account.accountAddress
        if account.accountAddress.isEmpty || account.mailSetting.userType == .newUser {
            address = BundleI18n.MailSDK.Mail_Mailbox_BusinessEmailDidntLink
        }
        if !multiAccountView.isDescendant(of: view) {
            view.addSubview(multiAccountView)
            multiAccountView.snp.makeConstraints { (make) in
                make.top.equalTo(statusAndNaviHeight)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(MailThreadListConst.mulitAccountViewHeight)
            }
            if shouldAdjustPullRefresh {
                let inset = tableView.contentInset
                tableView.contentInset = UIEdgeInsets(top: inset.top + MailThreadListConst.mulitAccountViewHeight, left: 0,
                                                      bottom: inset.bottom, right: 0)
                let esInset = esHeaderView?.scrollViewInsets ?? .zero
                esHeaderView?.scrollViewInsets = UIEdgeInsets(top: esInset.top + MailThreadListConst.mulitAccountViewHeight, left: 0, bottom: esInset.bottom - MailThreadListConst.mulitAccountViewHeight, right: 0)
                tableView.btd_scrollToTop()
            } else {
                tableView.snp.remakeConstraints { (make) in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.top.equalTo(naviHeight + statusHeight + MailThreadListConst.mulitAccountViewHeight)
                }
            }
        }
        multiAccountView.update(address: address, showBadge: showBadge)
    }

    func dismissMultiAccount() {
        guard multiAccountView.isDescendant(of: view) else { return }
        multiAccountView.removeFromSuperview()
        if shouldAdjustPullRefresh {
            let inset = tableView.contentInset
            tableView.contentInset = UIEdgeInsets(top: inset.top - MailThreadListConst.mulitAccountViewHeight, left: 0,
                                                  bottom: inset.bottom, right: 0)
            let esInset = esHeaderView?.scrollViewInsets ?? .zero
            esHeaderView?.scrollViewInsets = UIEdgeInsets(top: esInset.top - MailThreadListConst.mulitAccountViewHeight, left: 0,
                                                          bottom: esInset.bottom, right: 0)
            tableView.btd_scrollToTop()
        } else {
            tableView.snp.remakeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(naviHeight + statusHeight)
            }
        }
    }
    
    func showCleanTrashTip() -> Bool {
        if Store.settingData.mailClient {
            // 三方不展示
            return false
        }
        if let setting = Store.settingData.getCachedCurrentSetting() {
            let isSmtpActive = setting.mailOnboardStatus == .forceInput ||
            setting.mailOnboardStatus == .smtpActive
            let isAPIMigration = setting.userType == .gmailApiClient ||
            setting.userType == .exchangeApiClient
            let isMigration = isSmtpActive || isAPIMigration
            let isGC = setting.userType == .oauthClient ||
            setting.userType == .newUser
            return !isMigration && !isGC && userContext.featureManager.open(.cleanTrashTip)
        }
        return false
    }

    func updateUIElementCurrentLabelID(_ labelID: String) {
        threadActionBar.fromLabelID = labelID
        navFilterButton.isHidden = !viewModel.filterViewModel.shouldShowFilter(labelID)
        
        if showCleanTrashTip() {
            if labelID == Mail_LabelId_Trash ||
                labelID == Mail_LabelId_Spam {
                self.viewModel.updateLabelToTrash = true
                headerViewManager.tableHeaderView.showClearTrashTipsView(label: labelID)
            } else {
                headerViewManager.tableHeaderView.dismissClearTrashTipsView()
            }
        } else {
            headerViewManager.tableHeaderView.dismissClearTrashTipsView()
        }
    }

    func closeTableViewHeader() {
        guard !shouldAdjustPullRefresh else { return }
        headerViewManager.tempHeaderView = self.tableView.tableHeaderView as? MailThreadListHeaderView
        updateTableViewHeader(with: MailThreadListHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: CGFloat.leastNormalMagnitude)))
    }

    func resetAllRefresh() {
//        if !firstLoad {
//            return
//        }
        tableView.es.stopPullToRefresh()
        tableView.es.stopLoadingMore()
        tableView.es.resetNoMoreData()
    }

    func VMtrackPageViewEvent() {
        self.trackPageViewEvent()
    }

    // auth
    func updateOauthStatus(viewType: OAuthViewType) {
        guard viewModel.authStatusHelper.authStatus() else {
            MailLogger.info("[mailTab] authStatus is false, no need to update")
            return
        }
        MailLogger.info("[mailTab] updateOauthStatus \(viewType)")
        asyncRunInMainThread { [weak self] in
            guard let `self` = self else { return }
            let accountInfos = Store.settingData.getAccountInfos()
            self.showOauthPlaceholderPage(viewType: viewType, accountInfos: accountInfos)
        }
    }

    // MARK: auth page
    func showOauthPlaceholderPage(viewType: OAuthViewType, accountInfos: [MailAccountInfo]?) {
        MailLogger.info("[mailTab] show oauth placeholder page \(viewType)")

        /// 展示授权相关页面时，取消读信页展示
        enterThread(with: nil)

        if let page = oauthPlaceholderPage {
            hideContentController(page)
        }
        if viewType == .typeNoOAuthView {
            hideOauthPlaceholderPage()
            return
        }
        if viewType == .typeOauthDeleted {
            // 移除权限时dismiss除弹窗外的其他界面
            if self.presentedViewController?.isKind(of: LarkAlertController.self) == false {
                self.presentedViewController?.dismiss(animated: false)
            }
            if let vc = self.navigationController?.topViewController as? MailMessageListController {
                if !vc.isFeedCard {
                    self.navigationController?.popToRootViewController(animated: false)
                }
            } else {
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
        shouldShowOauthPage = true
        oauthPageViewType = viewType

        createOauthPageIfNeeded()
        oauthPlaceholderPage?.view.frame = view.frame
        oauthPlaceholderPage?.setupViewType(viewType: viewType)
        oauthPlaceholderPage?.delegate = self

        if let infos = accountInfos, infos.count > 1 {
            let badge = Store.settingData.getOtherAccountUnreadBadge()
            var address = infos.first { $0.isSelected }?.address ?? ""
            if address.isEmpty || viewType == .typeNewUserOnboard {
                address = BundleI18n.MailSDK.Mail_Mailbox_BusinessEmailDidntLink
            }
            self.oauthPlaceholderPage?.showMultiAccount(address: address, showBadge: badge)
        } else {
            self.oauthPlaceholderPage?.hideMultiAccount()
        }

        view.addSubview(oauthPlaceholderPage!.view)
        view.bringSubviewToFront(oauthPlaceholderPage!.view)

        if viewType == .typeNewUserOnboard {
            checkIfShowNewUserPopupAlert()
        }
        // 如果有搬家鉴权界面，移除
        removeIMAPAuthFlow()
    }

    func hideOauthPlaceholderPage() {
        shouldShowOauthPage = false
        oauthPageViewType = .typeNoOAuthView
        guard let page = oauthPlaceholderPage else {
            return
        }
        /// 未可见时子 VC 的视图可能是在 transitionVC 上，会导致移除失败
        if page.view.superview != view {
            MailLogger.info("[mail_client] oauthPlaceholderPage is not inside home yet")
        } else {
            page.currentGuideVC?.dismiss(animated: false)
            hideContentController(page)
        }
    }

    func refreshAuthPageIfNeeded(_ setting: Email_Client_V1_Setting, isUIChange: Bool = false) {
        MailLogger.info("[mail_client] refresh auth page with setting user type: \(setting.userType), isUIChange: \(isUIChange)")
        if userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false),
           setting.userType == .newUser,
           !isUIChange {
            /// 新的绑定模式，解绑后直接跳到登录页
            displayDelegate?.switchContent(inHome: false, insert: false, initData: true)
        } else {
            viewModel.authStatusHelper.refreshAuthPageIfNeeded(setting, vc: self)
        }
    }

    /// Onboard
    func showSmartInboxTips(_ tipType: SmartInboxTipsView.TipType) {
        MailLogger.info("showSmartInboxTips type: \(tipType)")
        // 最顶层VC不等于MailHome则保存展示的逻辑，在ViewWillAppear处再重新调用
        let guideKey = tipType == .previewCardPop ? "all_email_previewcard" : "all_email_smartinbox_intro"
        if self.view?.window == nil || userContext.provider.guideServiceProvider?.guideService?.checkIsCurrentGuideShowing() == true {
            if !appendGuide.contains(tipType) {
                appendGuide += [tipType]
            }
            MailLogger.info("showSmartInboxTips return by currentVC not in home or not in tab: \(isInMailTab()) or other guide is showing.")
            return
        }
        if tipType == .previewCardPop && tableHeaderView.previewCardisHidden() {
            return
        }
        MailLogger.info("showSmartInboxTips by LarkGuide")
        guard let larkNaviBar = navbarBridge?.getLarkNaviBar() else { return }
        let targetView = tipType == .labelPop ? larkNaviBar.titleView : tableHeaderView.getPreviewCardView()
        // 简单做一层保护，上方有弹窗（ipad设置页）或 targetView 还没到位的时候不显示 onboard，防止显示重叠/错位
        if self.presentedViewController != nil || targetView.frame.width == 0 || targetView.frame.height == 0 { return }
        let targetAnchor = TargetAnchor(targetSourceType: .targetView(targetView))
        let rightButtonInfo = ButtonInfo(title: "", skipTitle: BundleI18n.MailSDK.Mail_SmartInbox_OnboardingGotIt, buttonType: .close)
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_Setting_SmartSortEmails,
                                        detail: tipType == .labelPop
                                        ? BundleI18n.MailSDK.Mail_SmartInbox_OnboardingTipContent
                                        : BundleI18n.MailSDK.Mail_SmartInbox_OnboardingOthersEmail)
        let bottomConfig = BottomConfig(leftBtnInfo: nil, rightBtnInfo: rightButtonInfo, leftText: nil)
        let itemConfig = BubbleItemConfig(guideAnchor: targetAnchor, textConfig: textConfig, bottomConfig: bottomConfig)
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear)
        let bubbleConfig = SingleBubbleConfig(bubbleConfig: itemConfig, maskConfig: maskConfig)
        userContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                            bubbleType: .single(bubbleConfig),
                                                                                            dismissHandler: nil)
        
    }

    func showNewFilterOnboardingIfNeeded() {
        guard !Store.settingData.mailClient else { return }
        let guideKey = "mobile_email_feedfilter"
        guard let guide = userContext.provider.guideServiceProvider?.guideService,
              guide.checkShouldShowGuide(key: guideKey) else {
            return
        }

        MailDataServiceFactory.commonDataService?.mailLastVersionIsNewUser().subscribe(onNext: { [weak self] (flag) in
            guard let self = self else {
                return
            }

            if flag {
                // 新用户不需要
                return
            }
            let targetAnchor = TargetAnchor(targetSourceType: .targetView(self.navFilterButton))
            let textConfig = TextInfoConfig(title: nil, detail: BundleI18n.MailSDK.Mail_Label_FilterUnreadOnboarding)
            let bubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor, textConfig: textConfig))
            self.userContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                                bubbleType: .single(bubbleConfig),
                                                                                                dismissHandler: nil,
                                                                                                didAppearHandler: nil,
                                                                                                willAppearHandler: nil)
        }).disposed(by: disposeBag)
    }
}
