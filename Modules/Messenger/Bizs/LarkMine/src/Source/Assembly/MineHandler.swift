//
//  MineDataHandler.swift
//  Lark
//
//  Created by 姚启灏 on 2018/6/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkContainer
import LarkModel
import Swinject
import EENavigator
import LarkCustomerService
import LarkAccountInterface
import LarkSDKInterface
import LarkAppConfig
import LarkMessengerInterface
import LarkGuide
import LarkLeanMode
import LarkNavigation
import LarkNavigator
import LarkUIKit
import LarkLocalizations
import UniverseDesignToast
import RxSwift
import LKCommonsLogging
import Homeric
import LKCommonsTracker
import RustPB
import LarkVersion
import LarkSetting
import LarkOpenSetting
import LarkCoreLocation

final class MineMainHandler: UserTypedRouterHandler {

    func handle(_ body: MineMainBody, req: EENavigator.Request, res: Response) throws {
        let vc = try self.userResolver.resolve(assert: MineMainViewController.self)
        let router = try self.userResolver.resolve(assert: MineMainRouter.self)
        let hostProvider = { () in
            return body.hostProvider
        }
        router.hostProvider = hostProvider
        vc.router = router
        res.end(resource: vc)
    }
}

final class MineSettingNotificationHandler: UserTypedRouterHandler {

    func handle(_ body: MineNotificationSettingBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = NotificationSettingViewController(userResolver: self.userResolver)
        page.update(highlight: body.highlight)
        PageFactory.shared.config(userResolver: userResolver, viewController: page, with: .notification)
        vc = page
        res.end(resource: vc)
    }
}

final class MineAboutLarkHandler: UserTypedRouterHandler {

    func handle(_ body: MineAboutLarkBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .aboutLark)
        page.navTitle = BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuMobile()
        vc = page
        res.end(resource: vc)
    }
}

final class MineCapabilityPermissionHandler: UserTypedRouterHandler {

    func handle(_ body: MineCapabilityPermissionBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .capabilityPermission)
        page.navTitle = BundleI18n.LarkMine.Lark_CoreAccess_SystemAccessManagement_Option
        vc = page
        res.end(resource: vc)
    }
}

/// 效率设置
final class EfficiencySettingHandler: UserTypedRouterHandler {

    func handle(_ body: EfficiencySettingBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .efficiency)
        page.navTitle = BundleI18n.LarkMine.Lark_NewSettings_Efficiency
        vc = page
        res.end(resource: vc)
    }
}

/// 通用设置
final class MineGeneralSettingHandler: UserTypedRouterHandler {

    func handle(_ body: MineGeneralSettingBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .general)
        page.navTitle = BundleI18n.LarkMine.Lark_NewSettings_GeneralMobile
        vc = page
        res.end(resource: vc)
    }
}

/// 翻译设置
final class TranslateSettingHandler: UserTypedRouterHandler {

    func handle(_ body: TranslateSettingBody, req: EENavigator.Request, res: Response) throws {
        let router = try self.userResolver.resolve(assert: MineTranslateSettingRouter.self)
        let userGeneralSettings = try self.userResolver.resolve(assert: UserGeneralSettings.self)
        let userAppConfig = try self.userResolver.resolve(assert: UserAppConfig.self)
        let vc: UIViewController
        let newViewModel = MineTranslateSettingViewModel(
            userResolver: self.userResolver,
            userGeneralSettings: userGeneralSettings,
            userAppConfig: userAppConfig,
            router: router
        )
        vc = MineTranslateSettingController(viewModel: newViewModel)
        router.hostProvider = { [weak vc] in
            return vc
        }
        res.end(resource: vc)
    }
}

/// 翻译目标语言设置
final class TranslateTargetLanguageSettingHandler: UserTypedRouterHandler {

    func handle(_ body: TranslateTargetLanguageSettingBody, req: EENavigator.Request, res: Response) throws {
        let userGeneralSettings = try self.userResolver.resolve(assert: UserGeneralSettings.self)
        let vc = TranslateTagetLanguageSettingController(userResolver: self.userResolver, userGeneralSettings: userGeneralSettings)
        res.end(resource: vc)
    }
}

/// 隐私设置
final class PrivacySettingSettingHandler: UserTypedRouterHandler {

    ///跳转隐私设置
    func handle(_ body: PrivacySettingBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .privacy)
        page.navTitle = BundleI18n.LarkMine.Lark_NewSettings_Privacy
        vc = page
        res.end(resource: vc)
    }
}

/// 添加我的方式设置
final class AddMeWaySettingHandler: UserTypedRouterHandler {

    ///跳转添加我的方式设置
    func handle(_ body: AddMeWaySettingBody, req: EENavigator.Request, res: Response) throws {
        let vc = PageFactory.shared.generate(userResolver: self.userResolver, page: .waysToReachMe)
        vc.navTitle = BundleI18n.LarkMine.Lark_NewSettings_HowToAddMe
        res.end(resource: vc)
    }
}

/// 对外展示时区设置
final class ShowTimeZoneWithOtherHandler: UserTypedRouterHandler {

    private var disposeBag = DisposeBag()

    ///跳转对外展示时区设置
    func handle(_ body: ShowTimeZoneWithOtherBody, req: EENavigator.Request, res: Response) throws {
        let configureAPI = try self.userResolver.resolve(assert: ConfigurationAPI.self)
        configureAPI.getExternalDisplayTimezone()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { timeZoneSetting in
                let moduleKey = "timeZoneSetting"
                let vc = SettingViewController(name: "timeZoneSetting")
                vc.patternsProvider = { return [
                    .wholeSection(pair: PatternPair(moduleKey, ""))
                ]}
                vc.registerModule(TimeZoneSettingModule(userResolver: self.userResolver, timeZoneSetting: timeZoneSetting), key: moduleKey)
                vc.navTitle = BundleI18n.LarkMine.Lark_IM_PrivacySettings_TimeZoneDisplay_Title
                res.end(resource: vc)
            }, onError: { (error) in
                res.end(error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
    }
}

/// 个人信息
final class MinePersonalInformationViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: MinePersonalInformationBody, req: EENavigator.Request, res: Response) throws {
        let vc = try self.userResolver.resolve(assert: MinePersonalInformationViewController.self)
        vc.completion = body.completion
        res.end(resource: vc)
    }
}

/// 修改name
final class SetNameViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: SetNameControllerBody, req: EENavigator.Request, res: Response) throws {
        let chatterAPI = try self.userResolver.resolve(assert: ChatterAPI.self)
        let viewModel = SetNameViewModel(chatterAPI: chatterAPI, oldName: body.oldName, nameType: body.nameType)
        let vc = SetNameController(viewModel: viewModel)

        res.end(resource: vc)
    }
}

/// 系统设置
final class MineSettingViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: MineSettingBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .main)
        page.navTitle = BundleI18n.LarkMine.Lark_Legacy_SystemSetting
        vc = page
        res.end(resource: vc)
    }
}

/// 工作状态
final class WorkDescriptionSetViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: WorkDescriptionSetBody, req: EENavigator.Request, res: Response) throws {
        let vc = try self.userResolver.resolve(assert: WorkDescriptionSetController.self)
        vc.completion = body.completion
        res.end(resource: vc)
    }
}

/// 内部设置
final class InnerSettingViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: InnerSettingBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .innerSetting)
        page.navTitle = BundleI18n.LarkMine.Lark_NewSettings_InternalSettings_Mobile
        vc = page
        res.end(resource: vc)
    }
}

/// 显示语言
final class MineLanguageSettingViewControllerHandler: UserTypedRouterHandler {

    func handle(_ body: MineLanguageSettingBody, req: EENavigator.Request, res: Response) throws {
        let service = try self.userResolver.resolve(assert: AppLanguageService.self)
        let vc = SelectLanguageController(title: BundleI18n.LarkMine.Lark_NewSettings_Language) { (model, from) in
            service.updateAppLanguage(model: model, from: from)
        }
        res.end(resource: vc)
    }
}

/// 不自动翻译语言设置
final class DisableAutoTranslateLanguagesSettingControllerHandler: UserTypedRouterHandler {

    func handle(_ body: DisableAutoTranslateLanguagesSettingBody, req: EENavigator.Request, res: Response) throws {
        let userGeneralSettings = try self.userResolver.resolve(assert: UserGeneralSettings.self)
        let viewModel: DisableAutoTranslateLanguagesViewModel = DisableAutoTranslateLanguagesViewModel(userGeneralSettings: userGeneralSettings)
        let vc = DisableAutoTranslateLanguagesSettingController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

/// 翻译效果高级设置
final class LanguagesConfigurationSettingControllerHandler: UserTypedRouterHandler {

    func handle(_ body: LanguagesConfigurationSettingBody, req: EENavigator.Request, res: Response) throws {
        let userGeneralSettings = try self.userResolver.resolve(assert: UserGeneralSettings.self)
        let viewModel: LanguagesConfigurationSettingViewModel = LanguagesConfigurationSettingViewModel(userGeneralSettings: userGeneralSettings)
        let vc = LanguagesConfigurationSettingController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

/// 字体大小
final class FontSettingControllerHandler: UserTypedRouterHandler {

    func handle(_ body: MineFontSettingBody, req: EENavigator.Request, res: Response) throws {
        Tracker.post(TeaEvent(Homeric.SETTING_GENERAL_TEXTSIZE_CLICK))
        let vc = FontSettingViewController(userResolver: self.userResolver)
        res.end(resource: vc)
    }
}

/// 编辑链接
final class SetWebLinkHandler: UserTypedRouterHandler {

    func handle(_ body: SetWebLinkBody, req: EENavigator.Request, res: Response) throws {
        let chatterAPI = try self.userResolver.resolve(assert: ChatterAPI.self)
        let viewModel = SetWebLinkViewModel(key: body.key, pageTitle: body.pageTitle, text: body.text, link: body.link, chatterAPI: chatterAPI, successCallBack: body.successCallBack)
        let vc = SetWebLinkViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

/// 设置文本
final class SetTextHandler: UserTypedRouterHandler {

    func handle(_ body: SetTextBody, req: EENavigator.Request, res: Response) throws {
        let chatterAPI = try self.userResolver.resolve(assert: ChatterAPI.self)
        let viewModel = SetTextViewModel(key: body.key, pageTitle: body.pageTitle, text: body.text, chatterAPI: chatterAPI, successCallBack: body.successCallBack)
        let vc = SetTextViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

/// 网络检测
final class NetDiagnoseSettingControllerHandler: UserTypedRouterHandler {

    func handle(_ body: NetDiagnoseSettingBody, req: EENavigator.Request, res: Response) throws {
        let pushCenter = try self.userResolver.userPushCenter
        let rustService = try self.userResolver.resolve(assert: SDKRustService.self)
        let userNavigator = self.userResolver.navigator
        let viewModel: NetDiagnoseSettingViewModel =
        NetDiagnoseSettingViewModel(pushCenter: pushCenter, from: body.from, userNavigator: userNavigator, rustService: rustService)
        let vc = NetDiagnoseSettingController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

/// 星标联系人/特别关注
final class SpecialFocusSettingHandler: UserTypedRouterHandler {

    func handle(_ body: SpecialFocusSettingBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .specialFocus, info: ["scene": body.from])
        page.navTitle = BundleI18n.LarkMine.Lark_IM_ProfileSettings_VIPContactsNotificationsSettings
        vc = page
        res.end(resource: vc)
    }
}

final class MultiUserNotificationSettingHandler: UserTypedRouterHandler {
    func handle(_ body: MultiUserNotificationBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .multiUserNotification)
        page.navTitle = BundleI18n.LarkMine.Lark_NewSettings_MessageNotifications_FromOtherAccounts_Title
        vc = page
        res.end(resource: vc)
    }
}

final class NotificationDiagnosisHandler: UserTypedRouterHandler {

    func handle(_ body: NotificationDiagnosisBody, req: EENavigator.Request, res: Response) throws {
        let vc: UIViewController
        let page = PageFactory.shared.generate(userResolver: self.userResolver, page: .notificationDiagnose)
        page.navTitle = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_Title
        vc = page
        res.end(resource: vc)
    }
}
