//
//  MineRouter.swift
//  Lark
//
//  Created by 姚启灏 on 2018/6/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkUIKit
import LarkModel
import Swinject
import EENavigator
import LarkCustomerService
import UniverseDesignToast
import LKCommonsLogging
import LarkNavigator
import Homeric
import LKCommonsTracker
import LarkAccountInterface
import LarkSDKInterface
import LarkNavigation
import LarkMessengerInterface
import AnimatedTabBar
import LarkTab
import LarkFocus
import LarkContainer
import UIKit

public protocol MineDependency {
    func showTimeZoneSelectController(with timeZone: TimeZone?,
                                      from: UIViewController,
                                      onTimeZoneSelect: @escaping (TimeZone) -> Void)
}

final class MineRouterFactory {
    static func create(with resolver: UserResolver) -> MineRouter {
        if Display.pad {
            return MineRouterForIPad(userResolver: resolver)
        } else {
            return MineRouter(userResolver: resolver)
        }
    }
}

/// 隐藏Mine页面
///
/// Mine页面消失时，在iPad Regular视图添加动画
/// 方法内部会判断是popover样式还是drawer样式
private func hide(controller: MineMainViewController, completion: (() -> Void)?) {
    if Display.pad && controller.view.window?
            .traitCollection.horizontalSizeClass == .regular {
        DispatchQueue.main.async {
            controller.hideSideBar(animate: true, completion: completion)
        }
    } else {
        controller.hideSideBar(animate: false, completion: completion)
    }
}

final class MineRouterForIPad: MineRouter {
    override func openCustomServiceChat(_ controller: MineMainViewController) {
        Tracker.post(TeaEvent(Homeric.HELP_FEEDBACK_APP))
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openCustomServiceChat can not find from vc")
            return
        }
        let routerParams = RouterParams(
            sourceModuleType: SourceModuleType.larkMine,
            needDissmiss: false,
            showBehavior: .present,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { (vc) in
                vc.modalPresentationStyle = .formSheet
            }
        )
        hide(controller: controller) { [weak self] in
            let customerService = try? self?.userResolver.resolve(type: LarkCustomerServiceAPI.self)
            customerService?.showCustomerServicePage(routerParams: routerParams, onSuccess: nil, onFailed: {
                DispatchQueue.main.async {
                    UDToast.showFailure(
                        with: BundleI18n.LarkMine.Lark_Legacy_NetworkErrorRetry,
                        on: from.view
                    )
                }
            })
        }
    }
}

//Router的实现
class MineRouter: MineMainRouter {
    static let log = Logger.log(MineRouter.self, category: "Module.Mine.Router")

    let userResolver: UserResolver

    var hostProvider: () -> UIViewController? = { return nil }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func getHostViewController() -> UIViewController? {
        guard let vc = hostProvider() else { return nil }
        if Display.pad,
           let tab = vc as? UITabBarController,
           let select = tab.selectedViewController {
            return select
        }
        return vc
    }

    private func presentAssetBrowser(avatarKey: String, entityId: String, supportReset: Bool, from: UIViewController) {
        self.userResolver.navigator
            .present(body: PreviewAvatarBody(avatarKey: avatarKey,
                                                         entityId: entityId,
                                                         supportReset: supportReset,
                                                         scene: .personalizedAvatar),
                                 from: from)
    }

    private func openLink(controller: UIViewController, linkURL: URL?, userInfo: [String: Any], isShowDetail: Bool = false) {
        guard let url = linkURL else {
            return
        }
        if isShowDetail {
            self.userResolver.navigator
                .showDetail(url, context: userInfo, wrap: LkNavigationController.self, from: controller)
        } else {
            self.userResolver.navigator.push(url, context: userInfo, from: controller)
        }
    }

    // MARK: - MineMainRouter

    func openFocusListController(_ controller: MineMainViewController, sourceView: UIView) {
        guard let hostProvider = getHostViewController() else {
            MineRouter.log.error("MineRouter openFocusListController can not find from vc")
            return
        }
        let userResolver = self.userResolver
        hide(controller: controller) { [weak self] in
            let focusListVC = FocusListController(userResolver: userResolver)
            self?.userResolver.navigator.present(focusListVC, from: hostProvider)
        }
    }

    func openPersonalInformationController(_ controller: MineMainViewController, chatter: Chatter, completion: @escaping (String) -> Void) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openPersonalInformationController can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            let body = MinePersonalInformationBody(completion: completion)
            self?.userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func openProfileDetailController(_ controller: MineMainViewController, chatter: Chatter) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openProfileDetailController can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            let body = PersonCardBody(chatterId: chatter.id, fromWhere: .none)
            self?.userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func openSetUserName(_ controller: MineMainViewController, oldName: String) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openSetUserName can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            let body = SetNameControllerBody(oldName: oldName, nameType: .name)
            self?.userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func openSetAnotherName(_ controller: MineMainViewController, oldName: String) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openSetAnotherName can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            let body = SetNameControllerBody(oldName: oldName, nameType: .anotherName)
            self?.userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    /// 打开飞书活跃奖励入口
    func openAwardActivityEntry(_ activityURL: String, controller: MineMainViewController) {
        Tracker.post(TeaEvent(Homeric.CLICK_ALL_ACTIVITY_PAGE, params: ["source": "photo"]))
        guard let url = URL(string: activityURL) else {
            MineRouter.log.error("activityURL无法转化", additionalData: ["url": activityURL])
            return
        }
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter push activity web can not find from vc", additionalData: ["activityURL": activityURL])
            return
        }
        if Display.pad {
            self.userResolver.navigator.showDetail(url, wrap: LkNavigationController.self, from: from)
        } else {
            self.userResolver.navigator.push(url, from: from, animated: true)
        }
    }

    func openWalletController(_ controller: MineMainViewController, walletUrl: String?) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openWalletController can not find from vc")
            return
        }
        MineRouter.log.info("open wallet walletUrl:\(String(describing: walletUrl))")
        hide(controller: controller) { [weak self] in
            self?.userResolver.navigator.presentOrPush(body: WalletBody(walletUrl: walletUrl), wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func openFavoriteController(_ controller: MineMainViewController) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openFavoriteController can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            self?.userResolver.navigator.presentOrPush(body: FavoriteListBody(), wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func openDataController(_ controller: MineMainViewController) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openDataController can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            self?.userResolver.navigator.presentOrPush(body: MineAccountBody(), wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func openSettingController(_ controller: MineMainViewController) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openSettingController can not find from vc")
            return
        }

        hide(controller: controller) { [weak self] in
            let body = MineSettingBody()
            self?.userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        }
    }

    func openCustomServiceChat(_ controller: MineMainViewController) {
        guard let vc = self.getHostViewController(),
              let window = vc.view.window else {
            assertionFailure()
            return
        }
        Tracker.post(TeaEvent(Homeric.HELP_FEEDBACK_APP))
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openCustomServiceChat can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            guard let self = self else { return }
            let routerParams = RouterParams(
                sourceModuleType: SourceModuleType.larkMine,
                needDissmiss: false,
                from: from,
                prepare: { $0.modalPresentationStyle = .formSheet })
            self.userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: false, completion: nil)
            try? self.userResolver.resolve(type: LarkCustomerServiceAPI.self).showCustomerServicePage(routerParams: routerParams, onSuccess: nil, onFailed: {
                DispatchQueue.main.async {
                    UDToast.showFailure(
                        with: BundleI18n.LarkMine.Lark_Legacy_NetworkErrorRetry,
                        on: window
                    )
                }
            })
        }
    }

    func openCustomServiceChatById(_ controller: MineMainViewController, id: String, reportLocation: Bool) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openCustomServiceChatById can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            let body = OncallChatBody(oncallId: id, reportLocation: reportLocation)
            self?.userResolver.navigator.switchTab(Tab.feed.url, from: from, animated: false, completion: nil)
            self?.userResolver.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: from)
        }
    }

    func openWorkDescription(_ controller: MineMainViewController, completion: @escaping (String) -> Void) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openWorkDescription can not find from vc")
            return
        }
        UIApplication.shared.keyWindow?.backgroundColor = .clear
        hide(controller: controller) { [weak self] in
            let body = WorkDescriptionSetBody(completion: completion)
            self?.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: from) { vc in
                vc.modalPresentationStyle = .formSheet
            }
        }
    }

    func presentAssetBrowser(_ controller: MineMainViewController, avatarKey: String, entityId: String) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter presentAssetBrowser can not find from vc")
            return
        }
        hide(controller: controller) { [weak self] in
            self?.presentAssetBrowser(avatarKey: avatarKey, entityId: entityId, supportReset: false, from: from)
        }
    }

    func openLink(_ mineMaincontroller: MineMainViewController, linkURL: URL?, isShowDetail: Bool) {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter openLink can not find from vc")
            return
        }
        hide(controller: mineMaincontroller) { [weak self] in
            self?.openLink(controller: from, linkURL: linkURL, userInfo: [:], isShowDetail: isShowDetail)
        }
    }

    func openTeamConversionController(_ controller: MineMainViewController) {
        hide(controller: controller) { [weak self] in
            guard let self, let nav = self.userResolver.navigator.navigation else {
                Self.log.error("pushTeamConversionController failed nav is nil")
                return
            }
            let passportService = try? self.userResolver.resolve(assert: PassportService.self)
            passportService?.pushToTeamConversion(
                fromNavigation: nav,
                trackPath: "mine"
            )
        }
    }
}

// MARK: - personal info
extension MineRouter: MinePersonalInformationRouter {

    func openLink(_ mineMaincontroller: MinePersonalInformationViewController, linkURL: URL?, isShowDetail: Bool) {
        openLink(controller: mineMaincontroller, linkURL: linkURL, userInfo: [:], isShowDetail: isShowDetail)
    }

    func presentAssetBrowser(_ controller: MinePersonalInformationViewController,
                             avatarKey: String,
                             entityId: String,
                             supportReset: Bool) {
        let fromVC = controller.presentingViewController ?? controller.navigationController
        let needDismiss = controller.presentingViewController != nil

        guard let from = fromVC else {
            MineRouter.log.error("MinePersonalInformationRouter presentAssetBrowser can not find from vc")
            return
        }
        if needDismiss {
            controller.dismiss(animated: false) { [weak self] in
                guard let `self` = self else {
                    return
                }
                self.presentAssetBrowser(avatarKey: avatarKey, entityId: entityId, supportReset: supportReset, from: from)
            }
        } else {
            self.presentAssetBrowser(avatarKey: avatarKey, entityId: entityId, supportReset: supportReset, from: from)
        }
    }

    func pushSetUserName(_ controller: MinePersonalInformationViewController, oldName: String) {
        let body = SetNameControllerBody(oldName: oldName, nameType: .name)
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: controller, prepare: { $0.modalPresentationStyle = .formSheet })
    }

    func pushSetAnotherName(_ controller: MinePersonalInformationViewController, oldName: String) {
        let body = SetNameControllerBody(oldName: oldName, nameType: .anotherName)
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: controller, prepare: { $0.modalPresentationStyle = .formSheet })
    }

    func openMyQrcodeController(_ controller: MinePersonalInformationViewController) {
        let body = ExternalContactsInvitationControllerBody(scenes: .myQRCode, fromEntrance: .edit_profile)
        self.userResolver.navigator.push(body: body, from: controller)
    }

    func openMedalController(_ controller: MinePersonalInformationViewController, userID: String) {
        let body = MedalVCBody(userID: userID)
        self.userResolver.navigator.push(body: body, from: controller)
    }

    func openWorkDescription(_ controller: MinePersonalInformationViewController, completion: @escaping (String) -> Void) {
        let body = WorkDescriptionSetBody(completion: completion)
        UIApplication.shared.keyWindow?.backgroundColor = .clear
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: controller) { vc in
            vc.modalPresentationStyle = Display.pad ? .formSheet : .pageSheet
        }
    }

    func pushSetTextViewController(_ controller: MinePersonalInformationViewController, key: String, pageTitle: String, text: String, successCallBack: @escaping (String) -> Void) {
        let body = SetTextBody(key: key, pageTitle: pageTitle, text: text, successCallBack: successCallBack)
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: controller, prepare: { $0.modalPresentationStyle = .formSheet })
    }

    func pushSetLinkViewController(_ controller: MinePersonalInformationViewController,
                                   key: String,
                                   pageTitle: String,
                                   text: String,
                                   link: String,
                                   successCallBack: @escaping (String, String) -> Void) {
        let body = SetWebLinkBody(key: key, pageTitle: pageTitle, text: text, link: link, successCallBack: successCallBack)
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: controller, prepare: {
            $0.modalPresentationStyle = .formSheet
        })
    }
}

// MARK: - 翻译设置
extension MineRouter: MineTranslateSettingRouter {
    /// 跳转翻译目标语言设置
    func pushTranslateTagetLanguageSettingController() {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter pushTranslateTagetLanguageSetting can not find from vc")
            return
        }
        self.userResolver.navigator.push(body: TranslateTargetLanguageSettingBody(), from: from)
    }

    /// 跳转不自动翻译语言设置
    func pushDisableAutoTranslateLanguagesSettingController() {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter pushDisableAutoTranslateLanguagesSetting can not find from vc")
            return
        }
        let body = DisableAutoTranslateLanguagesSettingBody()
        self.userResolver.navigator.push(body: body, from: from)
    }

    /// 跳转翻译效果高级设置
    func pushLanguagesConfigurationSettingController() {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter pushLanguagesConfigurationSetting can not find from vc")
            return
        }
        let body = LanguagesConfigurationSettingBody()
        self.userResolver.navigator.push(body: body, from: from)
    }

    /// 跳转源语言列表
    func pushLanguagesListSettingController(currGloabalScopes: Int?, detailModelType: DetailModelType) {
        guard let from = getHostViewController() else {
            assertionFailure()
            return
        }
        guard let userGeneralSettings = try? self.userResolver.resolve(assert: UserGeneralSettings.self) else {
            return
        }
        let viewModel = MineTranslateLanguageListViewModel(
            userResolver: self.userResolver,
            userNavigator: self.userResolver.navigator,
            userGeneralSettings: userGeneralSettings,
            currGloabalScopes: currGloabalScopes,
            detailModelType: detailModelType)
        let vc = MineTranslateLanguageListController(viewModel: viewModel)
        self.userResolver.navigator.push(vc, from: from)
    }

    /// 跳转网络诊断页面
    func pushNetDiagnoseSettingController() {
        guard let from = getHostViewController() else {
            MineRouter.log.error("MineRouter pushNetDiagnoseSettingController can not find from vc")
            return
        }
        let body = NetDiagnoseSettingBody(from: .general_setting)
        self.userResolver.navigator.push(body: body, from: from)
    }
}
