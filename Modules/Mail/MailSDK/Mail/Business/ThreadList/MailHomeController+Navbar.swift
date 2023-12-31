//
//  MailHomeController+Navbar.swift
//  MailSDK
//
//  Created by majx on 2020/5/13.
//

import Foundation
import RxRelay
import LarkNavigation
import LarkUIKit
import Homeric
import LarkBadge
import RxSwift
import EENavigator

extension MailHomeController: MailNavBarDatasource {
    func customTitleArrowView(titleColor: UIColor) -> UIView? {
        let noticeFG = userContext.featureManager.open(FeatureKey.init(fgKey: .labelListNotice, openInMailClient: true))
        if noticeFG {
            arrowView.setArrowColor(titleColor)
            return arrowView
        } else {
            return nil
        }
    }

    var navbarShowLoading: BehaviorRelay<Bool> {
        return navBarLoading
    }

    var navbarEnable: Bool {
        return showLarkNavbar
    }

    var navbarTitle: BehaviorRelay<String> {
        return navBarTitleBehavior
    }

    var navbarSubTitle: BehaviorRelay<String?> {
        return BehaviorRelay(value: nil)
    }

    func navbar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        switch type {
        case .search:
            return navSearchButton
        case .first:
            return navFilterButton
        case .second:
            return navMoreButton
        }
    }

    func navbar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        return nil
    }

    func setNavBarBridge(_ bridge: MailNavBarBridge) {
        navbarBridge = bridge
    }
}

extension MailHomeController {
    func reloadNavbar() {
        guard displaying else {
            MailLogger.info("[mail_home] skip reload nav bar when home is not shown")
            return
        }
        navbarBridge?.reloadLarkNaviBar()
    }

    func getLarkNavbar() -> LarkNaviBar? {
        navbarBridge?.getLarkNaviBar()
    }

    func navbarTitleBadge(show: Bool) {
        if let larkNavibar = navbarBridge?.getLarkNaviBar() {
            if show {
                larkNavibar.titleView.uiBadge.addBadge(type: .dot(.pin))
                redDotDisposeBag = DisposeBag()
                larkNavibar.shouldShowGroup.subscribe(onNext: { [weak larkNavibar] (should) in
                    if should {
                        larkNavibar?.titleView.uiBadge.badgeView?.snp.remakeConstraints({ (make) in
                            make.size.equalTo(CGSize(width: 9, height: 9))
                            make.right.equalToSuperview().offset(-7)
                            make.top.equalToSuperview().offset(-2)
                        })
                    } else {
                        larkNavibar?.titleView.uiBadge.badgeView?.snp.remakeConstraints({ (make) in
                            make.size.equalTo(CGSize(width: 10, height: 10))
                            make.right.equalToSuperview().offset(-6)
                            make.top.equalToSuperview().offset(2)
                        })
                    }
                }).disposed(by: redDotDisposeBag)
            } else {
                larkNavibar.titleView.uiBadge.badgeView?.removeFromSuperview()
            }
            larkNavibar.titleView.accessibilityIdentifier = MailAccessibilityIdentifierKey.ViewNavTitleKey
            let noticeFG = userContext.featureManager.open(FeatureKey.init(fgKey: .labelListNotice, openInMailClient: true))
            if noticeFG {
                arrowView.setArrowColor(LarkNaviBar.titleColor)
            }
        }
    }

    func reloadListInMultiSelect(_ editing: Bool) {
        if editing {
            didChangeOffsetInMultiSelectMode = (false, false)
        }
        var topMargin = naviHeight + statusHeight
        var showMultiView = Store.settingData.getAccountInfos().count > 1
        if let accountList = Store.settingData.getCachedAccountList() {
            showMultiView = accountList.filter({ $0.isShared }).count > (Store.settingData.clientStatus == .mailClient ? 1 : 0)
        }
        var offset = tableView.contentOffset
        let parma: CGFloat = editing ? -1 : 1
        let needResetMultiAccountOffset = !editing && didChangeOffsetInMultiSelectMode.0
        let needResetHeaderOffset = !editing && didChangeOffsetInMultiSelectMode.1
        if showMultiView {
            if (offset.y > MailThreadListConst.mulitAccountViewHeight && editing) || needResetMultiAccountOffset {
                offset.y += MailThreadListConst.mulitAccountViewHeight * parma
                didChangeOffsetInMultiSelectMode.0 = true
            }
        }
        if (offset.y > headerViewManager.tableHeaderView.intrinsicContentSize.height && editing) || needResetHeaderOffset {
            offset.y += headerViewManager.tableHeaderView.intrinsicContentSize.height * parma
            didChangeOffsetInMultiSelectMode.1 = true
        }
        //MailLogger.info("[vv_debug] enterMultiSelect editing: \(editing) contentInsetTop: \(tableView.contentInset.top) headerInsetTop: \(esHeaderView?.scrollViewInsets.top) contentOffsetY: \(tableView.contentOffset.y)")
        if shouldAdjustPullRefresh {
            var diffInsetTop: CGFloat = 0.0
            var scrollToTop = false
            if showMultiView {
                diffInsetTop += (editing ? -1 : 1) * CGFloat(MailThreadListConst.mulitAccountViewHeight)
                scrollToTop = tableView.contentOffset.y < CGFloat(MailThreadListConst.mulitAccountViewHeight)
            }
            let lessThanOneScreen = {
                if viewModel.datasource.isEmpty {
                    return true
                } else if tableView.cellForRow(at: IndexPath(row: viewModel.datasource.count - 1, section: 0)) != nil {
                    let rect = tableView.rectForRow(at: IndexPath(row: viewModel.datasource.count - 1, section: 0))
                    return rect.origin.y + rect.size.height < tableView.bounds.height
                } else {
                    return false
                }
            }()
            diffInsetTop += (editing ? -1 : 1) * headerViewManager.tableHeaderView.intrinsicContentSize.height
            let insetTop = tableView.contentInset.top + diffInsetTop
            let insetBottom = tableView.contentInset.bottom
            tableView.contentInset = UIEdgeInsets(top: insetTop, left: 0,
                                                  bottom: insetBottom, right: 0)
            let esInset = esHeaderView?.scrollViewInsets ?? .zero
            esHeaderView?.scrollViewInsets = UIEdgeInsets(top: lessThanOneScreen ? 0 : (esInset.top + diffInsetTop), left: 0, bottom: esInset.bottom, right: 0)
            tableView.bounces = !editing
            if scrollToTop && !editing {
                if (tableView.tableHeaderView?.bounds.height ?? 0) > 0 {
                    tableView.scrollRectToVisible(tableView.tableHeaderView?.frame ?? .zero, animated: true)
                } else {
                    tableView.btd_scrollToTop()
                }
            }
        } else {
            self.tableView.contentOffset = offset
            if !editing && showMultiView {
                topMargin += CGFloat(MailThreadListConst.mulitAccountViewHeight)
            }
            tableView.snp.remakeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(topMargin)
            }
        }
    }
}

extension MailHomeController: MailNavBarDelegate {
    func onNavTitleTapped() {
        showDropMenu()
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_LABELS_COST_TIME, params: nil)
        MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_LABELS_MEMORY_DIFF, params: nil)
    }

    func onNavButtonTapped(type: LarkNaviButtonType) {
        switch type {
        case .search:
            onSelectSearch()
        case .second:
            showMoreAction()
        default:
            break
        }
    }
}

extension MailHomeController {
    func mailSyncEventChange(_ change: MailSyncEventChange) {
        let shouldLoading = (change.syncEvent == .sync)
        MailLogger.info("[mail_client_sync] change.syncEvent: \(change.syncEvent)")
        let title = {
            if shouldLoading {
                return BundleI18n.MailSDK.Mail_Label_Loading
            } else {
                return viewModel.currentLabelName
            }
        }()
        navBarTitleBehavior.accept(title)
        navBarLoading.accept(shouldLoading)

        if change.syncEvent == .end {
            viewModel.$initSyncFinish.accept(true)
            showNotifyBotOnboardingIfNeeded()
        }
    }

    func detectUnreadCountIfNeeded() {
			// 延迟3s做未读数检测
      Observable.just(())
          .delay(.seconds(timeIntvl.normalSecond), scheduler: MainScheduler.instance)
          .subscribe(onNext: { [weak self] _ in
              guard let `self` = self else { return }
              Store.fetcher?.getAllAccountUnreadCount().subscribe(onNext: { [weak self] (resp) in
                  guard let `self` = self else { return }
                  MailLogger.info("unread detect resp unreadCount: \(resp.unreadCount) tabUnreadColor: \(resp.tabUnreadColor.rawValue)")
                  guard let tabBarVC = self.tabBarController?.children.first(where: { $0 as? MailTabBarController != nil }) as? MailTabBarController else {
                      return
                  }
                  var accountLabelGap = 0
                  /// 上报事件 https://bytedance.us.feishu.cn/docx/TFzwdzHnKo2a5lxOCKZuIeNSsye
                  var tabCountGap = tabBarVC.unreadData.0 - Int(resp.unreadCount)
                  let tabColorGap = tabBarVC.unreadData.1 * 10 + resp.tabUnreadColor.rawValue
                  let syncStatus = self.navBarLoading.value ? 0 : 1
                  let tabActive = self.isInMailTab() ? 1 : 0
                  let event = MailAPMEvent.TabUnreadCount()
                  event.markPostStart()
                  if let setting = Store.settingData.getCachedCurrentSetting(),
                     setting.notificationScope != .default, !setting.allNewMailNotificationSwitch {
                      // setting 新邮件通知关闭 + 三期开启，只上报tab_count_gap（这里算所有账号之和）
                      tabCountGap = tabBarVC.unreadData.0 - Int(resp.unreadCountMap.values.reduce(0, +))
                  } else if self.userContext.featureManager.open(.tabUnreadCount, openInMailClient: true) {
                      // 二期开启，account_label_gap上报走历史逻辑
                      let unreadLabel = Store.settingData.getCachedCurrentAccount()?.mailSetting.smartInboxMode == true ? Mail_LabelId_Important : Mail_LabelId_Inbox
                      if let label = self.viewModel.labels.first(where: { $0.labelId == unreadLabel }), let badge = label.badge {
                          MailLogger.info("unread detect unreadLabel: \(unreadLabel) label.badge: \(badge))")
                          accountLabelGap = tabBarVC.unreadData.0 - badge
                          event.endParams.append(MailAPMEvent.TabUnreadCount.EndParam.account_label_gap(accountLabelGap))
                      }
                  }
                  event.endParams.append(MailAPMEvent.TabUnreadCount.EndParam.sync_status(syncStatus))
                  event.endParams.append(MailAPMEvent.TabUnreadCount.EndParam.tab_count_gap(tabCountGap))
                  event.endParams.append(MailAPMEvent.TabUnreadCount.EndParam.tab_color_gap(tabColorGap))
                  event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                  event.endParams.append(MailAPMEvent.TabUnreadCount.EndParam.tab_active(tabActive))
                  event.postEnd()
                  if self.userContext.featureManager.open(.tabUnreadCountApply, openInMailClient: true) {
                      EventBus.$larkmailEvent.accept(.unreadCountRecover(count: resp.unreadCount, color: resp.tabUnreadColor))
                  }
                  MailLogger.info("unread detect tabBarVC : \(tabBarVC.unreadData)")

              }).disposed(by: self.disposeBag)
          }).disposed(by: disposeBag)
    }
}

// MARK: - MailLabelsMenuDelegate
extension MailHomeController: MailTagListDelegate {
    func tagMenu(_ dropMenu: MailTagViewController, isShowing: Bool) {
        labelsMenuShowing = isShowing
        let noticeFG = userContext.featureManager.open(FeatureKey.init(fgKey: .labelListNotice, openInMailClient: true))
        if noticeFG {
            arrowView.setArrowPresentation(folded: !isShowing, animated: true)
        } else {
            navbarBridge?.changeLarkNaviBarTitleArrow(folded: !isShowing, animated: true)
        }
        if navbarShowTipsRedDot, isShowing {
            navbarShowTipsRedDot = false
            navbarTitleBadge(show: false)
            updateUserEngagementSetting(smartInboxAlertRendered: false, smartInboxPromptRendered: true, hasChange: (false, true))
        }

        if isShowing {
            MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_LABELS_COST_TIME, params: nil)
            MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_LABELS_CHANGE_MEMORY_DIFF, params: nil)

            let event = NewCoreEvent(event: .email_label_list_view)
            let value = NewCoreEvent.labelTransfor(labelId: dropMenu.viewModel.selectedID, allLabels: dropMenu.viewModel.labels)
            event.params = ["label_item": value,
                            "mail_display_type": Store.settingData.threadDisplayType(),
                            "mail_service_type": Store.settingData.getMailAccountListType()]
            event.post()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + DropMenuAnimation.showDuration, execute: { [weak self] in
                self?.viewModel.showBatchChangeLoadingIfNeeded()
            })
        }
    }

    func tagMenu(_ dropMenu: MailTagViewController, didSelect label: MailLabelModel) {
        if viewModel.currentLabelId == label.labelId {
            viewModel.apmMarkThreadListStart(sence: .sence_reload)
        } else {
            if label.tagType == .label {
                viewModel.apmMarkThreadListStart(sence: .sence_change_label)
            } else {
                viewModel.apmMarkThreadListStart(sence: .sence_change_folder)
            }
        }
        refreshListDataReady.accept((.switchLabel, false))
        didSelectedLabel(label.labelId, title: label.text, isSystemLabel: label.isSystem)

        let event = NewCoreEvent(event: .email_label_list_click)
        let value = NewCoreEvent.labelTransfor(labelId: label.labelId, allLabels: dropMenu.viewModel.labels)
        event.params = ["click": "label_item_click",
                        "target": "email_thread_list_view",
                        "target_label_item": value,
                        "mail_display_type": Store.settingData.threadDisplayType(),
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
        viewModel.updateUnreadDotAfterFirstScreenLoaded()
    }

    func tagMenu(_ dropMenu: MailTagViewController, retryReload labelId: String) {
        didRetryReloadData(labelId: labelId)
    }

    func tagMenu(_ dropMenu: MailTagViewController, touchesEndedAt location: CGPoint) {
        if let window = self.view.window, let point = navSearchButton.superview?.convert(location, from: window) {
            if navSearchButton.frame.contains(point) {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) {
                    self.onSelectSearch()
                }
            }
            if navMoreButton.frame.contains(point) {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) {
                    self.showMoreAction()
                }
            }
        }
    }

    func tagMenu(_ dropMenu: MailTagViewController, showManage: Bool) {
        labelsMenuShowing = showManage
        let noticeFG = userContext.featureManager.open(FeatureKey.init(fgKey: .labelListNotice, openInMailClient: true))
        if noticeFG {
            arrowView.setArrowPresentation(folded: !showManage, animated: true)
        } else {
            navbarBridge?.changeLarkNaviBarTitleArrow(folded: !showManage, animated: true)
        }
        if Store.settingData.mailClient {
            let manageVC = MailManageFolderController(accountContext: userContext.getCurrentAccountContext())
            manageVC.scene = .setting
            presentVC(manageVC)
        } else if Store.settingData.folderOpen() {
            let manageVC = MailManageTagViewController(accountContext: userContext.getCurrentAccountContext())
            presentVC(manageVC)
        } else {
            let manageVC = MailManageLabelsController(accountContext: userContext.getCurrentAccountContext(), showCreateButton: true)
            manageVC.scene = .setting
            presentVC(manageVC)
        }
    }

    private func presentVC(_ vc: MailBaseViewController) {
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        if #available(iOS 13.0, *) {
            nav.modalPresentationStyle = .automatic
            nav.navigationBar.barTintColor = ModelViewHelper.navColor()
        }
        navigator?.present(nav, from: self)
    }

    func delegateViewSize() -> CGSize {
        return self.tabBarController?.view.bounds.size ?? self.view.bounds.size
    }

    func updateUnreadDot(isHidden: Bool, isRed: Bool) {
        guard userContext.featureManager.open(FeatureKey.init(fgKey: .labelListNoticeRedDot, openInMailClient: true)) else { return }
        arrowView.setDot(isHidden: isHidden, isRed: isRed)
    }
}
