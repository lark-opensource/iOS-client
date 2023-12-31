//
//  PageFactory.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/14.
//

import Foundation
import LKLoadable
import LKCommonsLogging
import LarkContainer

public typealias ModuleProvider = (UserResolver) -> BaseModule?
public typealias PatternProvider = () -> [SectionPattern]

public enum Page: String {
    case unknown // 默认

    case main // 首页
    case innerSetting // 关于飞书
    case aboutLark // 关于飞书
    case capabilityPermission // 系统权限设置 - 关于飞书

    // 通用设置
    case general

    // 通知设置
    case notification  // 通知设置页首页
    case notificationDiagnose // 通知诊断页
    case specialFocus // 星标联系人设置页
    case multiUserNotification // 接收其他账号消息通知
    case notificationSpecific // 部分消息设置
    case notificationVoice // 通知声音设置

    // 隐私设置
    case privacy // 隐私设置页首页
    case waysToReachMe  // 联系我的方式

    // 效率设置
    case efficiency // 效率设置页首页
    case ccm    // CCM 文档设置页首页
}

public final class PageFactory {
    public static let shared = PageFactory()
    private var moduleProviderDict = [Page: [String: ModuleProvider]]()
    public var patternsProviderDict = [Page: PatternProvider]()

    public func register(page: Page, moduleKey: String, provider: @escaping ModuleProvider) {
        var dict = moduleProviderDict[page] ?? [String: ModuleProvider]()
        dict[moduleKey] = provider
        moduleProviderDict[page] = dict
    }

    init() {
        SettingLoggerService.logger(.factory).info("life/init: setupPattern")
        setupPattern()
    }

    /*
     描述布局【增改设置项改这里】
     详见：https://bytedance.feishu.cn/wiki/wikcnXpBpMj11bOolssEDKEpp4c?from=wiki
     */
    func setupPattern() {
        patternsProviderDict[.notificationDiagnose] = { return [
            .manySections(pair: ModulePair.NotificationDiagnose.diagnoseTips)
            , .wholeSection(pair: ModulePair.NotificationDiagnose.diagnoseMain)
            , .wholeSection(pair: ModulePair.NotificationDiagnose.customService)
        ]}
        patternsProviderDict[.specialFocus] = { return [
            .wholeSection(pair: ModulePair.SpecialFocus.specialFocusNumber)
            , .wholeSection(pair: ModulePair.SpecialFocus.specialFocusSetting)
        ]}
        patternsProviderDict[.multiUserNotification] = { return [
            .wholeSection(pair: ModulePair.MultiUserNotification.multiUserSwitch)
            ,.wholeSection(pair: ModulePair.MultiUserNotification.multiUserList)
        ]}
        patternsProviderDict[.main] = { return [
            .section(items: [
                ModulePair.Main.accountEntry
                , ModulePair.Main.generalEntry
            ]),
            .wholeSection(pair: ModulePair.Main.notificationEntry),
            .section(items: [
                ModulePair.Main.notificationEntry
                , ModulePair.Main.privacyEntry
                , ModulePair.Main.ccmEntry
                , ModulePair.Main.calendarEntry
                , ModulePair.Main.mailEntry
                , ModulePair.Main.videoConferenceEntry
                , ModulePair.Main.todoEntry
                , ModulePair.Main.momentEntry
                , ModulePair.Main.efficiencyEntry
            ]), .section(items: [
                ModulePair.Main.thirdPartySDKListEntry
                , ModulePair.Main.personalInfoEntry
            ]), .section(items: [
                ModulePair.Main.innerSettingEntry
                , ModulePair.Main.aboutLarkEntry
            ]), .section(
                footer: ModulePair.Main.mainVersion,
                items: [ModulePair.Main.mainLogout])
        ]}
        patternsProviderDict[.aboutLark] = { return [
            .wholeSection(pair: ModulePair.AboutLark.featureIntro)
            , .wholeSection(pair: ModulePair.AboutLark.whitePaper)
            , .wholeSection(pair: ModulePair.AboutLark.privacy)
        ]}
        patternsProviderDict[.innerSetting] = { return [
            .wholeSection(pair: ModulePair.InnerSetting.innerSetting)
        ]}
        patternsProviderDict[.notification] = { return [
            .wholeSection(pair: ModulePair.Notification.main)
            , .wholeSection(pair: ModulePair.Notification.specialFocus)
            , .wholeSection(pair: ModulePair.Notification.multiUserNotification)
            , .wholeSection(pair: ModulePair.Notification.inStartCallIntent)
            , .section(items: [
                ModulePair.Notification.useSystemCall
                , ModulePair.Notification.includesCallsInRecents])
            , .wholeSection(pair: ModulePair.Notification.offDuringCalls)
            , .wholeSection(pair: ModulePair.Notification.indisturbEntry)
            , .wholeSection(pair: ModulePair.Notification.whenPCOnline)
            , .wholeSection(pair: ModulePair.Notification.showDetail)
            , .wholeSection(pair: ModulePair.Notification.addUrgentNum)
            , .wholeSection(pair: ModulePair.Notification.diagnose)
            , .section(header: ModulePair.Notification.voice,
                       items: [ModulePair.Notification.voice,
                               ModulePair.Notification.customizeRingtone])
        ]}
        patternsProviderDict[.notificationSpecific] = { return [
            .wholeSection(pair: ModulePair.NotificationSpecific.specific)
        ]}
        patternsProviderDict[.capabilityPermission] = { return [
            .wholeSection(pair: ModulePair.CapabilityPermission.cameraAndPhoto)
            , .wholeSection(pair: ModulePair.CapabilityPermission.location)
            , .wholeSection(pair: ModulePair.CapabilityPermission.contactAndMicrophone)
            , .wholeSection(pair: ModulePair.CapabilityPermission.calendar)
        ]}
        patternsProviderDict[.general] = { return [
            .section(items: [
                ModulePair.General.appearance, ModulePair.General.messageAlignment
            ])
            , .section(items: [
                ModulePair.General.language, ModulePair.General.profileMultiLanguage, ModulePair.General.translation
            ])
            , .wholeSection(pair: ModulePair.General.font)
            , .wholeSection(pair: ModulePair.General.basicFunction)
            , .wholeSection(pair: ModulePair.General.timeFormat)
            , .wholeSection(pair: ModulePair.General.ipadSingleColumnMode)
            , .wholeSection(pair: ModulePair.General.wifiSwich4G)
            , .wholeSection(pair: ModulePair.General.networkDiagnose)
            , .wholeSection(pair: ModulePair.General.cache)
            , .wholeSection(pair: ModulePair.General.EMManager)
        ]}
        patternsProviderDict[.efficiency] = { return [
            .wholeSection(pair: ModulePair.Efficiency.feedSetting)
            , .wholeSection(pair: ModulePair.Efficiency.feedActionSetting)
            , .wholeSection(pair: ModulePair.Efficiency.audioToText)
            , .wholeSection(pair: ModulePair.Efficiency.enterChatLocationEntry)
            , .wholeSection(pair: ModulePair.Efficiency.smartComposeMessenger)
            , .wholeSection(pair: ModulePair.Efficiency.enterpriseEntity)
            , .wholeSection(pair: ModulePair.Efficiency.smartCorrection)
            , .wholeSection(pair: ModulePair.Efficiency.focusStatus)
        ]}
        patternsProviderDict[.privacy] = { return [
            .section(items: [
                ModulePair.Privacy.waysToReachMeEntry
                , ModulePair.Privacy.chatAuthEntry
            ])
            , .wholeSection(pair: ModulePair.Privacy.timeZoneEntry)
            , .wholeSection(pair: ModulePair.Privacy.whenPhoneCheckedSetting)
            , .wholeSection(pair: ModulePair.Privacy.blocklistEntry)
            , .wholeSection(pair: ModulePair.Privacy.leaderLinkShareEntry)
        ]}
        patternsProviderDict[.waysToReachMe] = { return [
            .wholeSection(pair: ModulePair.WaysToReachMe.canModify)
            , .wholeSection(pair: ModulePair.WaysToReachMe.findMeVia)
            , .wholeSection(pair: ModulePair.WaysToReachMe.addMeVia)
            , .wholeSection(pair: ModulePair.WaysToReachMe.addMeFrom)
        ]}
        patternsProviderDict[.ccm] = { return [
            .wholeSection(pair: ModulePair.CCM.imShareLeader)
            , .wholeSection(pair: ModulePair.CCM.linkShareType)
        ]}
    }

    private func assemblyOnlyOnce() {
        SwiftLoadable.startOnlyOnce(key: "OpenSetting")
        SwiftLoadable.startOnlyOnce(key: "OpenSettingAfterAssembly")
    }

    public func logRegister() {
        moduleProviderDict.forEach { page, moduleProviderDict in
            SettingLoggerService.logger(.factory).info("register: page.\(page) moduleProviders: \(moduleProviderDict.keys)")
        }
    }

    @_silgen_name("Lark.OpenSettingAfterAssembly.logRegister") // 格式: 命名空间.key.文件名
    public static func logRegister() {
        PageFactory.shared.logRegister()
    }

    // body的handler 里创建vc用
    public func generate(
        userResolver: UserResolver,
        page: Page,
        info: [String: Any] = [String: Any]()) -> SettingViewController {
        let context = ModuleContext()
        context.info = info
        let vc = SettingViewController(name: page.rawValue, context: context)
        config(userResolver: userResolver, viewController: vc, with: page)
        return vc
    }

    public func config(userResolver: UserResolver, viewController: SettingViewController, with page: Page) {
        assemblyOnlyOnce()
        viewController.patternsProvider = patternsProviderDict[page]
        guard let dict = moduleProviderDict[page] else {
            SettingLoggerService.logger(.factory).error("generate: page.\(page.rawValue): error: not dict")
            return
        }
        var okModules = [String]()
        var nilModules = [String]()
        dict.forEach { key, provider in
            guard let module = provider(userResolver) else {
                nilModules.append(key)
                return
            }
            okModules.append(key)
            viewController.registerModule(module, key: key)
        }
        SettingLoggerService.logger(.factory).info("generate: page.\(page.rawValue) with module: \(okModules); nil modules: \(nilModules)")
    }
}
