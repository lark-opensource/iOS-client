//
//  MainSettingLogoutModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/19.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LarkGuide
import LarkGuideUI
import LarkAlertController
import UniverseDesignToast
import LKCommonsTracker
import Homeric
import UniverseDesignActionPanel
import LarkUIKit
import LarkNavigation
import EENavigator
import LarkSetting
import LarkOpenSetting
import LarkSettingUI

final class MainSettingLogoutModule: BaseModule {
    @InjectedSafeLazy var accountService: AccountService
    @InjectedSafeLazy var guideService: NewGuideService // user:checked (global-resolve)
    @InjectedSafeLazy var passportService: PassportService

    let popoverWidth: CGFloat = 350.0

    private static let eraseDataNoticeTitle: String = "• " + I18N.Lark_Accounts_LogOutAllAccountsConfirmPCDesc + "\n\n" + "• " + I18N.Lark_ClearLocalCacheAtLogOut_EraseLocalCacheButNotCloudDescrip

    private static var eraseDataIsON: Bool {
        FeatureGatingManager.realTimeManager.featureGatingValue(with: "lark.security.logout_all.eraser")
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        let item = TapCellProp(title: I18N.Lark_Legacy_LarkLogout,
                                      color: UIColor.ud.colorfulRed,
                                      onClick: { [weak self] cell in
            self?.relogin(sourceView: cell)
        })
        return [item]
    }

    private func relogin(sourceView: UIView) {
        let userList = accountService.userList
        let currentTenantName = accountService.currentTenant.tenantName // user:checked
        let quitCurrent = I18N.Lark_Accounts_LogOutNameAccountButton(currentTenantName)
        let quitAll = I18N.Lark_Accounts_LogOutAllAccountsButton

        if userList.filter({ $0.userStatus == .normal }).count > 1 {
            showLogoutMultiUsersAlert(currentTenantName: currentTenantName, quitCurrent: quitCurrent, quitAll: quitAll, sourceView: sourceView)
        } else {
            if Self.eraseDataIsON {
                showLogoutAlert(title: Self.eraseDataNoticeTitle,
                                titleAlignment: .left,
                                acceptText: quitCurrent,
                                isShowTitle: true,
                                currentTenantName: nil, all: true, needAutoSwitch: false, sourceView: sourceView)
            } else {
                showLogoutAlert(title: I18N.Lark_Accounts_LogOutNameAccountConfirmPCDesc, acceptText: quitCurrent,
                                isShowTitle: false,
                                currentTenantName: nil, all: true, needAutoSwitch: false, sourceView: sourceView)
            }
        }
    }

    private func showLogoutMultiUsersAlert(currentTenantName: String,
                                           quitCurrent: String,
                                           quitAll: String,
                                           sourceView: UIView) {
        guard let vc = self.context?.vc else { return }
        // 退出当前
        let popSource = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceView.bounds, preferredContentWidth: popoverWidth)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .autoPopover(popSource: popSource), isShowTitle: false))
        actionSheet.addItem(.init(title: quitCurrent, action: { [weak self] in
            self?.showLogoutAlert(title: I18N.Lark_Accounts_LogOutNameAccountConfirmPCDesc, acceptText: quitCurrent,
                                  isShowTitle: true,
                                  currentTenantName: currentTenantName, all: false, needAutoSwitch: true, sourceView: sourceView)
        }))
        // 退出所有
        actionSheet.addItem(.init(title: quitAll, action: { [weak self] in

            let alertTitle: String
            let alertTitleAlignment: NSTextAlignment
            if Self.eraseDataIsON {
                alertTitle = Self.eraseDataNoticeTitle
                alertTitleAlignment = .left
            } else {
                alertTitle = I18N.Lark_Accounts_LogOutAllAccountsConfirmPCDesc
                alertTitleAlignment = .center
            }

            self?.showLogoutAlert(title: alertTitle,
                                  titleAlignment: alertTitleAlignment,
                                  acceptText: quitAll,
                                  isShowTitle: true,
                                  currentTenantName: nil, all: true, needAutoSwitch: false, sourceView: sourceView)
        }))
        actionSheet.setCancelItem(text: I18N.Lark_Legacy_Cancel)
        actionSheet.view.accessibilityIdentifier = "LarkMine.Logout.alert.view"
        Navigator.shared.present(actionSheet, from: vc) // user:checked (navigator)
    }

    private func showLogoutAlert(title: String,
                                 titleAlignment: NSTextAlignment = .center,
                                 acceptText: String,
                                 isShowTitle: Bool,
                                 currentTenantName: String?,
                                 all: Bool,
                                 needAutoSwitch: Bool,
                                 sourceView: UIView) {
        guard let vc = self.context?.vc else { return }
        let popSource = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceView.bounds, preferredContentWidth: popoverWidth)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .autoPopover(popSource: popSource), isShowTitle: isShowTitle))
        actionSheet.setTitle(title, alignment: titleAlignment)
        actionSheet.addDestructiveItem(text: acceptText, action: { [weak self] in
            self?.quitAction(currentTenantName, all, needAutoSwitch)
        })
        actionSheet.setCancelItem(text: I18N.Lark_Legacy_Cancel, action: { [weak self] in
            self?.cancelAction(currentTenantName, all)
        })
        actionSheet.view.accessibilityIdentifier = "LarkMine.Logout.alert.view"
        Navigator.shared.present(actionSheet, from: vc, animated: true) // user:checked (navigator)
    }

    private func quitAction(_ currentTenantName: String?, _ all: Bool, _ needAutoSwitch: Bool) {
        guard let vc = self.context?.vc, let window = vc.view.window else { return }
        let hud = UDToast.showDefaultLoading(with: I18N.Lark_Accounts_LoggingOut, on: window, disableUserInteraction: true)

        let params: [String: Any] = ["click": currentTenantName == nil ? "logout_all_account" : "logout_single_account",
                                     "target": "none",
                                     "is_confirm": true]
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
        let logoutConfig: LogoutConf = all ? .default : .foreground
        logoutConfig.trigger = .setting
        //如果是登出全部并且是回到登录页，需要判断擦除数据的fg是否开启
        if .all == logoutConfig.type && .login == logoutConfig.destination {
            logoutConfig.needEraseData = Self.eraseDataIsON
        }

        self.passportService.logout(conf: logoutConfig) {
            hud.remove()
            var errorString = I18N.Lark_Accounts_CantLogOutRetry
            if let currentTenantName = currentTenantName {
                errorString = I18N.Lark_Accounts_CantLogOutCompanyRetry(currentTenantName)
            }
            UDToast.showFailure(with: errorString, on: window)
        } onError: { [weak self] message in
            hud.remove()
            UDToast.showFailure(with: message, on: window)
        } onSuccess: { _, message in
            hud.remove()
            if let message = message, !message.isEmpty {
                UDToast.showFailure(with: message, on: window)
            }
        } onSwitch: { [weak self] completed in
            guard completed else { return }
            self?.autoSwitch()
        }
    }

    private func cancelAction(_ currentTenantName: String?, _ all: Bool) {
        let params: [String: Any] = ["click": currentTenantName == nil ? "logout_all_account" : "logout_single_account",
                                     "target": "none",
                                     "is_confirm": false]
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
    }

    private func showErrorAlert(message: String) {
        // 这里如果登出失败，settingVC 会被释放，所以只能取topVC来展示错误信息
        guard let vc = self.context?.vc,
              let window = vc.view.window,
              let topVC = window.lu.visibleViewController() as? BaseUIViewController else { return }
        let alertController = LarkAlertController()
        alertController.setTitle(text: I18N.Lark_Legacy_MineMainSystemMessage)
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: BundleI18n.LarkAccount.Lark_Legacy_Sure)
        Navigator.shared.present(alertController, from: topVC) // user:checked (navigator)
    }

    private func autoSwitch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let avatar = (RootNavigationController.shared.viewControllers.first as? MainTabbarProtocol)?
                .naviBar?
                .getAvatarContainer()
            self.guideService.closeCurrentGuideUIIfNeeded()
            currentSideBarMenu?.showSideBar(avatarView: avatar, completion: {
                DispatchQueue.main.async {
                    guard let addView = (currentSideBarMenu?.currentSubVC)?.tenantAddView() else { return }
                    self.showGuide(targetView: addView, guideService: self.guideService)
                }
            })
        }
    }
}

extension MainSettingLogoutModule: GuideSingleBubbleDelegate {
    func showGuide(targetView: UIView, guideService: NewGuideService) {
        let guideKey = "all_sidebar_new_exit_single"

        let itemConfig = BubbleItemConfig(guideAnchor: .init(targetSourceType: .targetView(targetView)),
                                          textConfig: .init(detail: I18N.Lark_Accounts_LogBackInToastOnboarding),
                                          bottomConfig: .init(rightBtnInfo: ButtonInfo(title:
                                                                I18N.Lark_Accounts_OnboardWelcomeToTenantButton)))
        let singleBubbleConfig = SingleBubbleConfig(delegate: StaticGuideSingleBubbleDelegate.shared,
                                                    bubbleConfig: itemConfig,
                                                    maskConfig: nil)
        guideService.showBubbleGuideIfNeeded(guideKey: guideKey,
                                             bubbleType: .single(singleBubbleConfig),
                                             dismissHandler: nil,
                                             didAppearHandler: nil,
                                             willAppearHandler: { _ in
                                                Tracker.post(TeaEvent(Homeric.NAVIGATION_BUBBLE_POPUP_LOGOUT_GUIDE_VIEW))
                                             })
    }

    func didClickRightButton(bubbleView: GuideBubbleView) {
        guideService.closeCurrentGuideUIIfNeeded()
    }
}

final class StaticGuideSingleBubbleDelegate: GuideSingleBubbleDelegate {
    static let shared = StaticGuideSingleBubbleDelegate()

    @InjectedLazy private var guideService: NewGuideService // user:checked (global-resolve)

    func didClickRightButton(bubbleView: GuideBubbleView) {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_BUBBLE_POPUP_LOGOUT_GUIDE_CLICK, params: ["click": "login_or_create_team", "target": "none"]))
        guideService.closeCurrentGuideUIIfNeeded()
    }
}
