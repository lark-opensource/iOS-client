//
//  NavigationService.swift
//  LarkNavigation
//
//  Created by Meng on 2019/10/21.
//

import UIKit
import LarkLocalizations
import Foundation
import LKCommonsLogging
import RxSwift
import RxCocoa
import LarkUIKit
import AnimatedTabBar
import SuiteAppConfig
import LarkReleaseConfig
import LarkSetting
import BootManager
import LarkDebug
import RustPB
import LarkRustClient
import LarkContainer
import LarkTab
import RunloopTools
import LarkStorage
import LarkQuickLaunchInterface

public protocol NavigationServiceImplDependency {
    var mailEnable: Bool { get }
    func notifyMailNaviUpdated(isEnabled: Bool)
    func notifyVideoConferenceTabEnabled()
    func getMedalKey() -> String
    func updateMedalAvatar(medalUpdate: ((_ entityId: String, _ avatarKey: String, _ medalKey: String) -> Void)?)
    func notifyNavigationAppInfos(appInfos: [OpenNavigationAppInfo])
}

final class NavigationServiceImpl: NavigationService, UserResolverWrapper {    

    var medalUpdate: ((_ entityId: String, _ avatarKey: String, _ medalKey: String) -> Void)?
    
    private let disposeBag = DisposeBag()

    static let logger = Logger.log(NavigationService.self, category: "LarkNavigation.NavigationService")

    var customNaviEnable: Bool {
        return true
    }

    private let tabVariable = PublishSubject<(oldTab: Tab?, newTab: Tab?)>()

    var tabDriver: Driver<(oldTab: Tab?, newTab: Tab?)> {
        return tabVariable.asDriver(onErrorJustReturn: (nil, nil))
    }

    func updateTab(oldTab: Tab?, newTab: Tab?) {
        tabVariable.onNext((oldTab: oldTab, newTab: newTab))
    }

    public let tabNoticeShowVariable = PublishSubject<CGFloat>()
    var tabNoticeShowDriver: Driver<CGFloat> {
        return tabNoticeShowVariable.asDriver(onErrorJustReturn: 0)
    }

    /// notice hide : height = 0 
    /// notice show : height > 0 , height equal to notice view height
    func didNoticeIsShow(height: CGFloat) {
        tabNoticeShowVariable.onNext(height)
    }

    var tabbarStyle: TabbarStyle = .bottom

    lazy var allTabs: AllTabs = {
        let result = loadTabs()
        return result
    }()

    var mainTabs: [Tab] {
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                return allTabs.iPad.main
            }
            return allTabs.iPhone.main
        } else {
            if tabbarStyle == .bottom {
                return allTabs.bottom.main
            }
            return allTabs.edge.main
        }
    }

    var quickTabs: [Tab] {
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                return allTabs.iPad.quick
            }
            return allTabs.iPhone.quick
        } else {
            if tabbarStyle == .bottom {
                return allTabs.bottom.quick
            }
            return allTabs.edge.quick
        }
    }

    var locoalTabs: [Tab] {
        return Tab.allSupportTabs
    }

    var firstTab: Tab? {
        return mainTabs.first
    }
 
    let userResolver: UserResolver
    private let navigationConfigService: NavigationConfigService
    private let dependency: NavigationServiceImplDependency

    init(userResolver: UserResolver,
         navigationConfigService: NavigationConfigService,
         dependency: NavigationServiceImplDependency) {
        self.userResolver = userResolver
        self.dependency = dependency
        self.navigationConfigService = navigationConfigService
    }

    // 需要更新NavigationService里的tabs，所以只能通过NavigationService中转
    func modifyNavigationOrder(mainTabItems: [AbstractTabBarItem], quickTabItems: [AbstractTabBarItem]) -> Observable<AllNavigationInfoResponse?> {
        let observable = navigationConfigService.modifyNavigationOrder(tabbarStyle: self.tabbarStyle, mainTabItems: mainTabItems, quickTabItems: quickTabItems)
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                self.allTabs.iPad.main = mainTabItems.map { $0.tab }
                self.allTabs.iPad.quick = quickTabItems.map { $0.tab }
            } else {
                self.allTabs.iPhone.main = mainTabItems.map { $0.tab }
                self.allTabs.iPhone.quick = quickTabItems.map { $0.tab }
            }
        } else {
            if self.tabbarStyle == .bottom {
                self.allTabs.bottom.main = mainTabItems.map { $0.tab }
                self.allTabs.bottom.quick = quickTabItems.map { $0.tab }
            } else {
                self.allTabs.edge.main = mainTabItems.map { $0.tab }
                self.allTabs.edge.quick = quickTabItems.map { $0.tab }
            }
        }
        return observable
    }

    // 需要更新NavigationService里的tabs，所以只能通过NavigationService中转
    func modifyNavigationOrder(main: [AbstractRankItem], quick: [AbstractRankItem]) -> Observable<AllNavigationInfoResponse?> {
        let observable = navigationConfigService.modifyNavigationOrder(tabbarStyle: self.tabbarStyle, main: main, quick: quick)
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                self.allTabs.iPad.main = main.map { $0.tab }
                self.allTabs.iPad.quick = quick.map { $0.tab }
            } else {
                self.allTabs.iPhone.main = main.map { $0.tab }
                self.allTabs.iPhone.quick = quick.map { $0.tab }
            }
        } else {
            if self.tabbarStyle == .bottom {
                self.allTabs.bottom.main = main.map { $0.tab }
                self.allTabs.bottom.quick = quick.map { $0.tab }
            } else {
                self.allTabs.edge.main = main.map { $0.tab }
                self.allTabs.edge.quick = quick.map { $0.tab }
            }
        }
        return observable
    }
}

extension NavigationServiceImpl {

    private func logLoadTabs() {
        let additionalData: [String: String] = [
            "hasNavigationInfo": "\(navigationConfigService.originalAllTabsinfo != nil)",
            "bottom-mainConfigs": "\(navigationConfigService.originalAllTabsinfo?.bottom.main.map({ $0.key }) ?? [])",
            "bottom-quickConfigs": "\(navigationConfigService.originalAllTabsinfo?.bottom.quick.map({ $0.key }) ?? [])",
            "edge-mainConfigs": "\(navigationConfigService.originalAllTabsinfo?.edge.main.map({ $0.key }) ?? [])",
            "edge-quickConfigs": "\(navigationConfigService.originalAllTabsinfo?.edge.quick.map({ $0.key }) ?? [])",
            "iPhone-mainConfigs": "\(navigationConfigService.originalAllTabsinfo?.iPhone.main.map({ $0.key }) ?? [])",
            "iPhone-quickConfigs": "\(navigationConfigService.originalAllTabsinfo?.iPhone.quick.map({ $0.key }) ?? [])",
            "iPad-mainConfigs": "\(navigationConfigService.originalAllTabsinfo?.iPad.main.map({ $0.key }) ?? [])",
            "iPad-quickConfigs": "\(navigationConfigService.originalAllTabsinfo?.iPad.quick.map({ $0.key }) ?? [])",
            "appCenterEnable": "\(navigationConfigService.appCenterEnable)",
            "mailFeatureSwitch": "\(navigationConfigService.mailFeatureSwitch)",
            "calendarEnable": "\(navigationConfigService.calendarEnable)"
        ]
        NavigationServiceImpl.logger.debug("<NAVIGATION_BAR> navigation start load tabs.", additionalData: additionalData)
    }

    /// client defensive strategy
    ///
    /// -1. if fg close, use legacy tab urls for mainTab, qucikTab return empty array.
    /// 0. filter feature gating tabs
    /// 1. mainTab count in config range, return normally.
    /// 2. mainTab count less than config range lowerbound, supplement from quickTab
    /// 3. others condition, return default configs
    ///
    private func loadTabs() -> AllTabs {
        guard Thread.isMainThread else {
            NavigationServiceImpl.logger.info("<NAVIGATION_BAR> load tabs not in main thread")
            return AllTabs.defaultTabs()
        }
        logLoadTabs()
        Tab.resetAllTabs()

        var navi: AllNavigationInfoResponse?
        if navigationConfigService.naviFeatureEnable {
            return self.leanModeTab
        } else {
            navi = navigationConfigService.originalAllTabsinfo
        }
        // 订阅因为收到远端push发生的导航数据变化
        navigationConfigService.naviInfosObservable
            .subscribe(onNext: { [weak self] navigationInfo in
                guard let `self` = self else { return }
                // 放到异步任务里面
                DispatchQueue.global().async { [weak self] in
                    guard let `self` = self else { return }
                    // 通知上层订阅的业务方导航数据变化了
                    self.notifyNavigationAppInfos(navigationInfo)
                }
            }).disposed(by: disposeBag)

        guard let navigationInfo = navi else {
            RunloopDispatcher.shared.addTask { [weak self] in
                guard let self = self else { return }
                self.notifyIfContainTab(Tab.byteview, allTabs: (self.defaultMainTab + self.defaultQuickTab)) { [weak self] in
                    self?.dependency.notifyVideoConferenceTabEnabled()
                }
            }
            return self.defaultTab
        }

        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        let allTabs: [Basic_V1_NavigationAppInfo]
        if !crmodeDisable {
            allTabs = navigationInfo.iPhone.main + navigationInfo.iPhone.quick + navigationInfo.iPad.main + navigationInfo.iPad.quick
        } else {
            allTabs = navigationInfo.bottom.main + navigationInfo.bottom.quick + navigationInfo.edge.main + navigationInfo.edge.quick
        }
        for appInfo in allTabs {
            let isCustomType = appInfo.isCustomType()
            parseNativeTab(by: appInfo)
            guard let tab = Self.parseNonNativeTab(by: appInfo, userResolver: self.userResolver) else { continue }
            guard isCustomType || TabRegistry.contain(tab) else { continue }
            Tab.allTabs.append(tab)
        }
        // 放到异步任务里面
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            // 通知上层订阅的业务方导航数据变化了
            self.notifyNavigationAppInfos(navigationInfo)
        }
        // filter feature gating
        let tabKeyDics = Tab.tabKeyDics.filter(navigationConfigService.featureGatingEnableFliter)

        // 将返回的 Basic_V1_NavigationAppInfo 转换成 Tab 数据结构
        // NOTE: 这里只用到了 Key，其他信息似乎没有用到？
        // 注意：这里需要过滤 urlString 为空的对象，因为现在可以自己添加自定义应用了，你不能保证用户传了不合法的 url 过来（明明和他们说过就是不听怪我喽）
        var mainTabs: [Tab]
        var quickTabs: [Tab]
        if !crmodeDisable {
            if Display.pad {
                mainTabs = navigationInfo.iPad.main.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
                quickTabs = navigationInfo.iPad.quick.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
            } else {
                mainTabs = navigationInfo.iPhone.main.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
                quickTabs = navigationInfo.iPhone.quick.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
                // 对iPhone主导航的个数进行check&排序
                rearrangeTabsForPhone(mainTabs: &mainTabs, quickTabs: &quickTabs)
            }
        } else {
            mainTabs = navigationInfo.bottom.main.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
            quickTabs = navigationInfo.bottom.quick.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
            // 对bottom的主导航的个数进行check&排序
            rearrangeTabsForPhone(mainTabs: &mainTabs, quickTabs: &quickTabs)
        }
        RunloopDispatcher.shared.addTask { [weak self] in
            self?.notifyIfContainTab(.mail, allTabs: (mainTabs + quickTabs), operationIfContain: {
                self?.dependency.notifyMailNaviUpdated(isEnabled: true)
            }, operationIfNotContain: {
                self?.dependency.notifyMailNaviUpdated(isEnabled: false)
            })

            self?.notifyIfContainTab(Tab.byteview, allTabs: (mainTabs + quickTabs)) {
                self?.dependency.notifyVideoConferenceTabEnabled()
            }
        }

        // Debug改变导航顺序
        reorderTabsByLocalConfigIfNeeded(mainTabs: &mainTabs, quickTabs: &quickTabs)

        // normally
        let iPhoneResponse: NavigationInfoResponse
        let iPadResponse: NavigationInfoResponse
        if !crmodeDisable {
            iPhoneResponse = navigationInfo.iPhone
            iPadResponse = navigationInfo.iPad
        } else {
            iPhoneResponse = navigationInfo.bottom
            iPadResponse = navigationInfo.edge
        }
        let iPhone = Tabs()
        iPhone.main = iPhoneResponse.main.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
        iPhone.quick = iPhoneResponse.quick.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
        let iPad = Tabs()
        // 注意：这里需要过滤 urlString 为空的对象，因为现在可以自己添加自定义应用了，你不能保证用户传了不合法的 url 过来（明明和他们说过就是不听怪我喽）
        var iPadMainTabs: [Tab] = iPadResponse.main.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
        var iPadQuickTabs: [Tab] = iPadResponse.quick.compactMap { tabKeyDics[$0.key] }.filter { !$0.urlString.isEmpty }
        // 兜底逻辑
        if iPadMainTabs.isEmpty {
            iPadMainTabs = iPhone.main
            iPadQuickTabs = iPhone.quick
        }
        iPad.main = iPadMainTabs
        iPad.quick = iPadQuickTabs
        NavigationServiceImpl.logger.debug("<NAVIGATION_BAR> navigation did load tabs.", additionalData: [
            "iPhoneMain": "\(iPhone.main.map({ $0.key }))",
            "iPhoneQuick": "\(iPhone.quick.map({ $0.key }))",
            "iPadMain": "\(iPad.main.map({ $0.key }))",
            "iPadQuick": "\(iPad.quick.map({ $0.key }))"
        ])
        return AllTabs(iPhone: iPhone, iPad: iPad, crmodeDataUnifiedDisable: crmodeDisable)
    }

    private func notifyNavigationAppInfos(_ navigationInfo: AllNavigationInfoResponse) {
        var appInfos: [RustPB.Basic_V1_NavigationAppInfo]
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                appInfos = navigationInfo.iPad.main + navigationInfo.iPad.quick
            } else {
                appInfos = navigationInfo.iPhone.main + navigationInfo.iPhone.quick
            }
        } else {
            if self.tabbarStyle == .bottom {
                appInfos = navigationInfo.bottom.main + navigationInfo.bottom.quick
            } else {
                appInfos = navigationInfo.edge.main + navigationInfo.edge.quick
            }
        }
        let openNavigationInfos = appInfos.compactMap { appInfo in
            self.tranformAppInfoToOpenNavigationInfo(appInfo)
        }
        NavigationServiceImpl.logger.info("<NAVIGATION_BAR> callback openNavigationInfos length = \(openNavigationInfos.count)")
        self.dependency.notifyNavigationAppInfos(appInfos: openNavigationInfos)
    }

    public func tranformAppInfoToOpenNavigationInfo(_ appInfo: RustPB.Basic_V1_NavigationAppInfo) -> OpenNavigationAppInfo {
        // 唯一标识
        let uniqueId = appInfo.uniqueID
        // 用于跳转native app对应tab的key
        let key = appInfo.key
        // 应用类型
        let appType = appInfo.appType.transformToNativeApptype()
        // 因为要支持品牌资源定制化，多语言这边要特殊处理下
        var i18nName = appInfo.name
        // 和安卓保持一致，只取当前语言
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        if let value = TabConfig.defaultName(for: key, of: appType, languageName: lang) {
            i18nName[lang] = value
        }
        return OpenNavigationAppInfo(uniqueId: uniqueId, key: key, appType: appType, i18nName: i18nName)
    }

    private func notifyIfContainTab(_ tab: Tab, allTabs: [Tab], operationIfContain: (() -> Void), operationIfNotContain: (() -> Void)? = nil) {
        if allTabs.contains(tab) {
            NavigationServiceImpl.logger.debug("<NAVIGATION_BAR> [Tabs] nav has \(tab.tabName) tab")
            operationIfContain()
        } else {
            NavigationServiceImpl.logger.debug("<NAVIGATION_BAR> [Tabs] nav doesn't have \(tab.tabName) tab")

            if let block = operationIfNotContain {
                block()
            }
        }
    }

    private func parseNativeTab(by appInfo: Basic_V1_NavigationAppInfo) {
        let appType = appInfo.appType.transformToNativeApptype()
        guard appType == .native else { return }
        // 更新本地打底数据里面的属性，自从有了用户自定义应用后，本地应用也可以租户配置并且指定不同属性(是否可删除、打开方式之类)
        if let index = Tab.allTabs.firstIndex(where: { $0.key == appInfo.key }) {
            Tab.allTabs[index].source = appInfo.source.transformToNativeSource()
            let tab = Tab.allTabs[index]
            // 如果业务方自定义了Tab的打开方式：例如Base
            if let represent = TabRegistry.resolve(tab), let openMode = represent.openMode {
                // 以业务方自定义的为准
                Tab.allTabs[index].openMode = openMode
            } else {
                // 否则以服务端为准
                Tab.allTabs[index].openMode = appInfo.openMode.transformToNativeOpenMode()
            }
            Tab.allTabs[index].primaryOnly = appInfo.primaryOnly
            Tab.allTabs[index].unmovable = appInfo.unmovable
            Tab.allTabs[index].erasable = appInfo.erasable
            Tab.allTabs[index].uniqueId = appInfo.uniqueID
        }
        // 公司圈的话需要特殊处理一下
        if appInfo.key == Tab.moment.key {
            let extra = [
                NavigationKeys.name: appInfo.name,
                NavigationKeys.logo: appInfo.logo.transformToNativeAppLogo()
            ]
            Tab.moment.extra = extra
        }
    }

    static public func parseNonNativeTab(by appInfo: Basic_V1_NavigationAppInfo, userResolver: UserResolver) -> Tab? {
        let appType = appInfo.appType.transformToNativeApptype()
        let source = appInfo.source.transformToNativeSource()
        var openMode = appInfo.openMode.transformToNativeOpenMode()
        let primaryOnly = appInfo.primaryOnly
        let unmovable = appInfo.unmovable
        let erasable = appInfo.erasable
        let key = appInfo.key
        let uniqueId = appInfo.uniqueID
        // 自定义类型单独处理
        if appInfo.isCustomType() {
            let typeValue = Int(appInfo.extra[RecentRecordExtraKey.bizType] ?? "") ?? 0
            let bizType = (NavigationAppBizType(rawValue: typeValue) ?? .unknownType).toCustomBizType()
            var icon = appInfo.logo.customNavigationAppLogo.toCustomTabIcon()
            let logoType = appInfo.logo.customNavigationAppLogo.type
            if let content = appInfo.extra[RecentRecordExtraKey.iconInfo], logoType == .appLogoTypeUnknown {
                icon = TabCandidate.TabIcon.iconInfo(content)
            }
            let appId = appInfo.extra[RecentRecordExtraKey.appid] ?? ""
            let lang = LanguageManager.currentLanguage.rawValue.lowercased()
            var name = appInfo.name[lang] ?? (appInfo.name["en_us"] ?? "")
//            // 如果用户改动名字的话，使用别名
//            if let displayName = appInfo.extra[RecentRecordExtraKey.displayName] {
//                name = displayName
//            }
            // 下面是给开平的特化逻辑，如果是用户配置的开平应用（包含小程序和网页应用）都使用push方式打开（否则和租户配置重复的话打开会出现黑屏）
            if source == .userSource && appType == .appTypeOpenApp {
                openMode = .pushMode
            }
            var url = appInfo.extra[RecentRecordExtraKey.url] ?? ""
            if openMode == .switchMode {
                if bizType == .WEB_APP || bizType == .WEB {
                    url = Tab.webAppPrefix + appInfo.uniqueID
                } else if bizType == .MINI_APP {
                    url = Tab.gadgetPrefix + appInfo.uniqueID
                }
            }
            // 自定义类型的话key和uniqueId一样的
            var tab = Tab(url: url, appType: appType, key: uniqueId, bizType: bizType, name: name, tabIcon: icon, openMode: openMode, source: source, primaryOnly: primaryOnly, unmovable: unmovable, erasable: erasable, uniqueId: uniqueId)
            // 要把appInfo的extra原封不动的带过来
            var extra = Dictionary(uniqueKeysWithValues: appInfo.extra.map { ($0, $1) } )
            // Switch方式打开需要appId
            extra[NavigationKeys.appid] = appId
            extra[NavigationKeys.uniqueid] = uniqueId
            tab.extra = extra
            // 手动注册到TabRegistry中
            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.main_tab.op_app_badge")),
                (bizType == .WEB_APP || bizType == .MINI_APP),
                let service = try? userResolver.resolve(assert: NavigationDependency.self) {
                Self.logger.info("TabRegistry OPAppTabRepresentable appType:\(appType)")
                TabRegistry.register(tab, provider: {_ in
                    return service.createOPAppTabRepresentable(tab: tab)
                })
            } else {
                Self.logger.info("TabRegistry DefaultTabRepresentable")
                TabRegistry.register(tab, provider: {_ in
                    return DefaultTabRepresentable(tab: tab)
                })
            }
            return tab
        }
        // 处理租户配置的小程序gadget和租户配置的H5应用webapp这两种类型
        guard let appId = appInfo.extra[NavigationKeys.appid],
            !appInfo.key.isEmpty, appType != .native else { return nil }
        // 租户配置的应用打开方式需要用服务端给的值，因为不一定适配了主导航（之前租户配置的必须要适配，后来新导航后就打破了这个规矩）
        // 很重要的一点是打开方式不一样，URL的拼接规则也不一样，这逻辑也是服！
        var url: String?
        if appType == .gadget {
            if openMode == .pushMode {
                // 没有适配主导航，要使用server下发的链接
                url = appInfo.extra[NavigationKeys.mobileUrl] ?? ""
            } else {
                // 适配了主导航，使用端上自己配置的路由
                url = Tab.gadgetPrefix + appInfo.key
            }
        }
        if appType == .webapp {
            if openMode == .pushMode {
                // 没有适配主导航，要使用server下发的链接
                url = appInfo.extra[NavigationKeys.mobileUrl] ?? ""
            } else {
                // 适配了主导航，使用端上自己配置的路由
                url = Tab.webAppPrefix + appInfo.key
            }
        }
        if appType == .appTypeCustomNative { url = Tab.appTypeCustomNative + appInfo.key }
        if url.isEmpty {
            NavigationServiceImpl.logger.error("<NAVIGATION_BAR> parseNonNativeTab tab url is isEmpty appInfo: \(appInfo)")
        }
        guard let tabUrl = url else {
            NavigationServiceImpl.logger.error("<NAVIGATION_BAR> parseNonNativeTab tab has no url appInfo: \(appInfo)")
            return nil
        }
        // 之前预置的本地应用key和uniqueId不一样的
        var tab = Tab(url: tabUrl,
                      appType: appType,
                      key: key,
                      openMode: openMode,
                      source: source,
                      primaryOnly: primaryOnly,
                      unmovable: unmovable,
                      erasable: erasable,
                      uniqueId: uniqueId)
        tab.extra = [
            NavigationKeys.name: appInfo.name,
            NavigationKeys.logo: appInfo.logo.transformToNativeAppLogo(),
            NavigationKeys.appid: appId,
            NavigationKeys.uniqueid: uniqueId,
            NavigationKeys.mobileUrl: appInfo.extra[NavigationKeys.mobileUrl] ?? ""
        ]
        // 手动注册到TabRegistry中
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.main_tab.op_app_badge")), 
            (appType == .gadget || appType == .webapp),
            let service = try? userResolver.resolve(assert: NavigationDependency.self) {
            Self.logger.info("TabRegistry OPAppTabRepresentable appType:\(appType)")
            TabRegistry.register(tab, provider: {_ in
                return service.createOPAppTabRepresentable(tab: tab)
            })
        } else {
            Self.logger.info("TabRegistry DefaultTabRepresentable")
            TabRegistry.register(tab, provider: {_ in
                return DefaultTabRepresentable(tab: tab)
            })
        }
        return tab
    }

    private func rearrangeTabsForPhone(mainTabs: inout [Tab], quickTabs: inout [Tab]) {
        // less range lowerbound, supplement
        if mainTabs.count < NavigationConfig.mainTabRange.lowerBound {
            let supplementCount = NavigationConfig.mainTabRange.lowerBound - mainTabs.count
            if quickTabs.count >= supplementCount {
                (mainTabs, quickTabs) = (
                    mainTabs + quickTabs[0..<supplementCount],
                    Array(quickTabs[supplementCount...])
                )
            } else {
                let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
                if !crmodeDisable {
                    (mainTabs, quickTabs) = (defaultTab.iPhone.main, defaultTab.iPhone.quick)
                } else {
                    (mainTabs, quickTabs) = (defaultTab.bottom.main, defaultTab.bottom.quick)
                }
            }
        }
        // beyond range upperbound, default
        if mainTabs.count > NavigationConfig.mainTabRange.upperBound {
            let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
            if !crmodeDisable {
                (mainTabs, quickTabs) = (defaultTab.iPhone.main, defaultTab.iPhone.quick)
            } else {
                (mainTabs, quickTabs) = (defaultTab.bottom.main, defaultTab.bottom.quick)
            }
        }
    }

    private func reorderTabsByLocalConfigIfNeeded(mainTabs: inout [Tab], quickTabs: inout [Tab]) {
        guard appCanDebug() else { return }
        let conf = KVConfig(
            key: KVKeys.Navigation.debugLocalTabs,
            store: KVStores.Navigation.buildGlobal()
        )
        guard let localTabs = conf.value else { return }
        guard let main = localTabs.first, let quick = localTabs.last else { return }
        let currentTabs = mainTabs + quickTabs
        func keyToTab(tab: String) -> Tab? {
            return currentTabs.first { $0.key == tab }
        }
        mainTabs = main.compactMap(keyToTab)
        quickTabs = quick.compactMap(keyToTab)
    }

    func reloadTabs() {
        self.allTabs = self.loadTabs()
    }
    
    func getMedalKey() -> String {
        dependency.getMedalKey()
    }

    func updateMedalAvatar() {
        dependency.updateMedalAvatar(medalUpdate: self.medalUpdate)
    }
}

// MARK: - default config
extension NavigationServiceImpl {

    private var defaultMainTab: [Tab] {
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                return defaultTab.iPad.main
            }
            return defaultTab.iPhone.main
        } else {
            if tabbarStyle == .bottom {
                return defaultTab.bottom.main
            }
            return defaultTab.edge.main
        }
    }

    private var defaultQuickTab: [Tab] {
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                return defaultTab.iPad.quick
            }
            return defaultTab.iPhone.quick
        } else {
            if tabbarStyle == .bottom {
                return defaultTab.bottom.quick
            }
            return defaultTab.edge.quick
        }
    }

    private var defaultTab: AllTabs {
        let bottom = Tabs()
        let edge = Tabs()
        let iPhone = Tabs()
        let iPad = Tabs()
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        let tabs = AllTabs(iPhone: iPhone, iPad: iPad, crmodeDataUnifiedDisable: crmodeDisable)
        if ReleaseConfig.releaseChannel == "Oversea" {
            bottom.main = defaultMainTabsForLark
            bottom.quick = defaultQuickTabsForLark
            edge.main = defaultMainTabsForLark
            edge.quick = defaultQuickTabsForLark
            iPhone.main = defaultMainTabsForLark
            iPhone.quick = defaultQuickTabsForLark
            iPad.main = defaultMainTabsForLark
            iPad.quick = defaultQuickTabsForLark
        } else {
            bottom.main = defaultMainTabsForFeishu
            bottom.quick = defaultQuickTabsForFeishu
            edge.main = defaultMainTabsForFeishu
            edge.quick = defaultQuickTabsForFeishu
            iPhone.main = defaultMainTabsForFeishu
            iPhone.quick = defaultQuickTabsForFeishu
            iPad.main = defaultMainTabsForFeishu
            iPad.quick = defaultQuickTabsForFeishu
        }
        return tabs
    }

    private var leanModeTab: AllTabs {
        let bottom = Tabs()
        let edge = Tabs()
        let crmodeDisable = self.navigationConfigService.crmodeUnifiedDataDisable
        let tabs = AllTabs(iPhone: bottom, iPad: edge, crmodeDataUnifiedDisable: crmodeDisable)
        bottom.main = defaultMainTabsForLeanMode
        bottom.quick = defaultQuickTabsForLeanMode
        edge.main = defaultMainTabsForLeanMode
        edge.quick = defaultQuickTabsForLeanMode
        return tabs
    }

    private var defaultMainTabsForLeanMode: [Tab] {
        var result: [Tab] = []
        result.append(Tab.feed)
        return result.filter { TabRegistry.allRegistedTabs.contains($0) }
    }

    private var defaultQuickTabsForLeanMode: [Tab] {
        let result: [Tab] = []
        return result.filter { TabRegistry.allRegistedTabs.contains($0) }
    }

    private var defaultMainTabsForFeishu: [Tab] {
        var result: [Tab] = []
        result.append(Tab.feed)
        if navigationConfigService.calendarEnable {
            result.append(Tab.calendar)
        }
        if navigationConfigService.appCenterEnable {
            result.append(Tab.appCenter)
        }
        result.append(Tab.doc)
        if navigationConfigService.mailEnable {
            result.append(Tab.mail)
        } else {
            result.append(Tab.contact)
        }
        return result.filter { TabRegistry.allRegistedTabs.contains($0) }
    }

    private var defaultQuickTabsForFeishu: [Tab] {
        var result: [Tab] = []
        if navigationConfigService.mailEnable {
            result.append(Tab.contact)
        }

        result.append(Tab.wiki)
        result.append(Tab.byteview)
        return result.filter { TabRegistry.allRegistedTabs.contains($0) }
    }

    // 海外 Lark 主Tab兜底
    private var defaultMainTabsForLark: [Tab] {
        var result: [Tab] = []
        result.append(Tab.feed)
        result.append(Tab.byteview)
        if navigationConfigService.calendarEnable {
            result.append(Tab.calendar)
        }
        result.append(Tab.doc)
        if navigationConfigService.mailEnable {
            result.append(Tab.mail)
        } else {
            result.append(Tab.contact)
        }
        return result.filter { TabRegistry.allRegistedTabs.contains($0) }
    }

    // 海外 Lark Quick Tab兜底
    private var defaultQuickTabsForLark: [Tab] {
        var result: [Tab] = []
        if navigationConfigService.appCenterEnable {
            result.append(Tab.appCenter)
        }
        if navigationConfigService.mailEnable {
            result.append(Tab.contact)
        }

        result.append(Tab.wiki)

        return result.filter { TabRegistry.allRegistedTabs.contains($0) }
    }
}

// Lean Mode
extension AppConfigManager {
    var naviFeatureIsOn: Bool {
        return AppConfigManager.shared.leanModeIsOn
    }

    var appConfigNavigationInfo: AllNavigationInfoResponse? {
        // swiftlint:disable syntactic_sugar
        let trait = AppConfigManager.shared.feature(for: .navi).trait(for: .tabs) { (info: Any) -> AllNavigationInfoResponse? in
            if let dic = info as? Dictionary<String, Any>,
                let data = try? JSONSerialization.data(withJSONObject: dic, options: []),
                let string = String(data: data, encoding: .utf8) {
                if let infoV2 = try? NavigationInfoV2(jsonString: string) {
                    let infoV3 = AllNavigationInfoResponse.transformToV3FromV2(infoV2)
                    let result =  NavigationConfigService.transformToNativeInfo(pbInfo: infoV3)
                    return result
                }
            }
            NavigationServiceImpl.logger.error("<NAVIGATION_BAR> appConfigNavigationInfo error: \(info)")
            return nil
        }
        return trait.flatMap { $0 }
        // swiftlint:enable syntactic_sugar
    }
}
