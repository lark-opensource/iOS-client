//
//  MineSettingAssembly.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/7.
//

import Foundation
import Swinject
import LarkOpenSetting
import LarkSetting
import EENavigator
import LarkContainer
import RustPB
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsTracker
import Homeric
import LarkAccountInterface
import LarkUrgent
import LarkTab
import LarkNavigation
import LarkUIKit
import LarkFocus
import LKCommonsLogging

public final class MineSettingAssembly {

    @_silgen_name("Lark.OpenSetting.MineSettingAssembly") // 格式: 命名空间.key.文件名
    public static func pageFactoryRegister() {
        SettingLoggerService.logger(.factory).info("assembly: mine")
        registerStoreTrackHandler()
        registerBizTrackHandler()
        registerMineSettingConfigForMain()
        registerMineSettingConfigForGeneral()
        registerMineSettingConfigForNotification()
        registerMineSettingConfigForEfficiency()
        registerMineSettingConfigForPrivacy()
    }

    static func registerStoreTrackHandler() {
        SettingStoreService.registerLogHandler { info in
            Tracker.post(SlardarEvent(
                name: "lark_biz_setting_kv_monitor",
                metric: ["latency": info.duration * 1000], // 使得单位由秒变为毫秒
                category: ["mainThread": info.isMainThread, "action": info.action],
                extra: ["isMissed": info.isMissed ?? "", "key": info.key ?? ""]
            ))
//            SettingLoggerService.logger(.store).debug(info.description) // TODO: 调试用
        }
    }

    static func registerBizTrackHandler() {
        SettingTrackeService.registerTrackHandler(handler: { info in
            Tracker.post(SlardarEvent(
                name: "lark_biz_setting_request_monitor",
                metric: ["latency": info.duration * 1000], // 使得单位由秒变为毫秒
                category: [
                    "settingName": info.settingName,  // 请求的名字，不包括set/get前缀
                    "module": info.module,  // module 必选
                    "action": info.action,  // get or set
                    "errorCode": info.errorCode, // 无错的时候是0
                    "from": info.from
                ],
                extra: ["errorCode": info.errorMsg]
            ))
//            SettingLoggerService.logger(.track).debug(info.description) // TODO: 调试用
        })
    }

    static func registerMineSettingConfigForNotification() {
        PageFactory.shared.register(page: .notificationSpecific, moduleKey: ModulePair.NotificationSpecific.specific.moduleKey, provider: { userResolver in
            NotificationSettingSpecificModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.whenPCOnline.moduleKey, provider: { userResolver in
            NotificationSettingWhenPCOnlineModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.showDetail.moduleKey, provider: { userResolver in
            NotificationSettingShowDetailModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .notificationDiagnose, moduleKey: ModulePair.NotificationDiagnose.diagnoseMain.moduleKey, provider: { userResolver in
            NotificationDiagnosisingModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .notificationDiagnose, moduleKey: ModulePair.NotificationDiagnose.customService.moduleKey, provider: { userResolver in
            NotificationDiagnoseCustomServiceModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .specialFocus, moduleKey: ModulePair.SpecialFocus.specialFocusNumber.moduleKey, provider: { userResolver in
            SpecialFocusSettingNumberModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .specialFocus, moduleKey: ModulePair.SpecialFocus.specialFocusSetting.moduleKey,
                                    provider: { userResolver in
            SpecialFocusSettingConfigModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.main.moduleKey) { userResolver in
            NotificationSettingMainModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.diagnose.moduleKey) { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NotificationTroubleShooting_Title,
                footerStr: BundleI18n.LarkMine.Lark_NotificationTroubleShooting_Desc,
                onClickBlock: { (userResolver, vc) in
                    MineTracker.trackClickNotificationDiagnosis()
                    userResolver.navigator.push(body: NotificationDiagnosisBody(), from: vc)
                })
        }
        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.voice.moduleKey) { userResolver in
            NotificationSettingSoundModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .multiUserNotification, moduleKey: ModulePair.MultiUserNotification.multiUserSwitch.moduleKey) { userResolver in
            NotificationMultiUserSettingModule(userResolver: userResolver)
        }
    }
    static func registerMineSettingConfigForMain() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.generalEntry.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_GeneralMobile,
                onClickBlock: { (userResolver, vc) in
                    userResolver.navigator.push(body: MineGeneralSettingBody(), from: vc)
                })
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.privacyEntry.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_Privacy,
                onClickBlock: { (userResolver, vc) in
                    MineTracker.trackSettingPrivacytabClick()
                    MineTracker.trackEnterPrivacySetting()
                    userResolver.navigator.push(body: PrivacySettingBody(), from: vc)
                })
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.notificationEntry.moduleKey, provider: { userResolver in
            NotificationSettingEntryModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.personalInfoEntry.moduleKey, provider: { userResolver in
            guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .personalInfoCollectedGate) else { return nil }
            guard let userAppConfig = try? userResolver.resolve(assert: UserAppConfig.self) else { return nil }
            let urlKey = RustPB.Basic_V1_AppConfig.ResourceKey.privacyChecklist
            guard let str = userAppConfig.resourceAddrWithLanguage(key: urlKey), let url = URL(string: str) else { return nil }
            return GeneralURLModule(userResolver: userResolver, title: BundleI18n.LarkMine.Lark_Core_PersonalInfoCollected, url: url)
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.thirdPartySDKListEntry.moduleKey, provider: { userResolver in
            guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .suiteAboutThirdpartySdk) else { return nil }
            guard let userAppConfig = try? userResolver.resolve(assert: UserAppConfig.self) else { return nil }
            let urlKey = RustPB.Basic_V1_AppConfig.ResourceKey.thirdPartySdk
            guard let str = userAppConfig.resourceAddrWithLanguage(key: urlKey), let url = URL(string: str) else { return nil }
            let module = GeneralURLModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_Core_ThirdPartySDKList,
                url: url)
            module.onClick = { MineTracker.trackSettingAboutSDKList() }
            return module
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.innerSettingEntry.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_InternalSettings_Mobile,
                onClickBlock: { (userResolver, vc) in
                    userResolver.navigator.push(body: InnerSettingBody(), from: vc)
                })
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.aboutLarkEntry.moduleKey, provider: { userResolver in
            AboutLarkEntryModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.efficiencyEntry.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_Efficiency,
                onClickBlock: { (userResolver, vc) in
                    userResolver.navigator.push(body: EfficiencySettingBody(), from: vc)
                    Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: ["click": "general"]))
                })
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.mainVersion.moduleKey, provider: { userResolver in
            MainSettingVersionModule(userResolver: userResolver)
        })
        PageFactory.shared.register(page: .aboutLark, moduleKey: ModulePair.AboutLark.featureIntro.moduleKey) { userResolver in
            AboutLarkModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .capabilityPermission, moduleKey: ModulePair.CapabilityPermission.cameraAndPhoto.moduleKey) { userResolver in
            CapabilityPermissionModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .innerSetting, moduleKey: ModulePair.InnerSetting.innerSetting.moduleKey) { userResolver in
            InnerSettingModule(userResolver: userResolver)
        }
    }

    static func registerMineSettingConfigForGeneral() {
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.appearance.moduleKey) { userResolver in
            if #available(iOS 13.0, *) {
                return AppearanceEntryModule(userResolver: userResolver)
            }
            return nil
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.messageAlignment.moduleKey) { userResolver in
            guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: "messenger.message_settings_bubble_alignment") else { return nil }
            return MessageAlignmentModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.language.moduleKey) { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_Language) { (userResolver, from) in
                let body = MineLanguageSettingBody()
                userResolver.navigator.present(body: body,
                                         wrap: LkNavigationController.self,
                                         from: from,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            }
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.font.moduleKey) { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_TextSizeTitle, footerStr: BundleI18n.LarkMine.Lark_NewSettings_TextSizeTitleDesc) { (userResolver, from) in
                userResolver.navigator.present(body: MineFontSettingBody(),
                                         wrap: LkNavigationController.self,
                                         from: from,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            }
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.timeFormat.moduleKey) { userResolver in
            TimeFormatModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.ipadSingleColumnMode.moduleKey) { userResolver in
            IpadSingleColumnModeModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.basicFunction.moduleKey) { userResolver in
            let passportUserService = try? userResolver.resolve(assert: PassportUserService.self)
            let userType = passportUserService?.user.type ?? .undefined
            // 当前租户是否是小B
            let isSimpleB = userType == .undefined || userType == .simple
            guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: "mobile.core.basic_mode") && isSimpleB else { return nil }
            return BasicFunctionModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.wifiSwich4G.moduleKey) { userResolver in
            guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: "core.wifi.4g") else { return nil }
            return WifiSwich4GModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.networkDiagnose.moduleKey) { userResolver in
            return GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NetworkDiagnosis) { (userResolver, from) in
                MineTracker.trackSettingNetworkCheckClick()
                let body = NetDiagnoseSettingBody(from: .general_setting)
                userResolver.navigator.push(body: body, from: from)
            }
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.cache.moduleKey) { userResolver in
            CacheModule(userResolver: userResolver)
        }
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.EMManager.moduleKey) { userResolver in
            guard EMManager.isEnabled else { return nil }
            return EMManagerEntryModule(userResolver: userResolver)
        }
    }

    static func registerMineSettingConfigForEfficiency() {
        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.focusStatus.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_Profile_PersonalStatus,
                footerStr: BundleI18n.LarkMine.Lark_Profile_PersonalStatusDesc,
                onClickBlock: { (userResolver, from) in
                    let vc = FocusSettingController(userResolver: userResolver)
                    userResolver.navigator.push(vc, from: from)
                    SettingTracker.Main.Click.FocusSetting()
                })
        })
        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.enterChatLocationEntry.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_StartFrom,
                onClickBlock: { (userResolver, from) in
                    let pageName = "enterChatLocation"
                    let enterChatLocation = PatternPair("enterChatLocation", "")
                    let vc = SettingViewController(name: pageName)
                    vc.patternsProvider = { return [
                        .wholeSection(pair: enterChatLocation)
                    ]}
                    vc.registerModule(EnterChatLocationModule(userResolver: userResolver), key: enterChatLocation.moduleKey)
                    vc.navTitle = BundleI18n.LarkMine.Lark_NewSettings_StartFrom
                    userResolver.navigator.push(vc, from: from)
                })
        })
        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.audioToText.moduleKey, provider: { userResolver in
            guard let fg = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
            guard fg.staticFeatureGatingValue(with: .suiteVoice2Text) && fg.staticFeatureGatingValue(with: .audioToTextEnable) else { return nil }
            return AudioToTextModule(userResolver: userResolver)
        })
    }

    static func registerMineSettingConfigForPrivacy() {
        PageFactory.shared.register(page: .privacy, moduleKey: ModulePair.Privacy.waysToReachMeEntry.moduleKey, provider: waysToReachMeEntryModuleProvider)
        PageFactory.shared.register(page: .waysToReachMe, moduleKey: ModulePair.WaysToReachMe.canModify.moduleKey, provider: waysToReachMeSettingModuleProvider)

        PageFactory.shared.register(page: .privacy, moduleKey: ModulePair.Privacy.chatAuthEntry.moduleKey, provider: chatAuthEntryModuleProvider)

        PageFactory.shared.register(page: .privacy, moduleKey: ModulePair.Privacy.whenPhoneCheckedSetting.moduleKey, provider: whenPhoneCheckedModuleProvider)

        PageFactory.shared.register(page: .privacy, moduleKey: ModulePair.Privacy.timeZoneEntry.moduleKey, provider: timeZoneEntryModuleProvider)

        PageFactory.shared.register(page: .privacy, moduleKey: ModulePair.Privacy.blocklistEntry.moduleKey, provider: blockListEntryModuleProvider)
    }
}
