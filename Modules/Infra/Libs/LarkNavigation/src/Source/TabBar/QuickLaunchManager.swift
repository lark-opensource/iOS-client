//
//  QuickLaunchManager.swift
//  LarkNavigation
//
//  Created by Hayden Wang on 2023/5/30.
//

import UIKit
import LarkLocalizations
import LarkTab
import LarkStorage
import AnimatedTabBar
import LKCommonsLogging
import LarkQuickLaunchInterface
import LarkContainer
import RxSwift
import RustPB
import LarkSetting
import LarkUIKit
import SuiteAppConfig
import UniverseDesignToast
import LarkRustClient
import EENavigator

// 忽略魔法数检查
// nolint: magic number

public final class QuickLaunchManager: NSObject, QuickLaunchService, UserResolverWrapper {
    public var userResolver: UserResolver
    weak var newWindowRootVc: UIViewController?

    @ScopedInjectedLazy var fgService: FeatureGatingService?

    // MARK: Feature Gating
    /// 新版导航FG
    public lazy var isQuickLauncherEnabled: Bool = {
        !AppConfigManager.shared.leanModeIsOn
    }()

    // FG：CRMode数据统一
    public lazy var crmodeUnifiedDataDisable: Bool = {
        return fgService?.staticFeatureGatingValue(with: "lark.navigation.disable.crmode") ?? false
    }()

    private lazy var hud: UDToast = {
        return UDToast()
    }()

    @ScopedInjectedLazy var temporaryTabService: TemporaryTabService?
    
    @ScopedInjectedLazy var navigationAPI: NavigationAPI?

    @ScopedInjectedLazy var navigationConfigService: NavigationConfigService?

    private let disposeBag = DisposeBag()

    static let logger = Logger.log(QuickLaunchManager.self, category: "Module.Core.QuickLaunchManager")

    /// 通过 `QuickLaunchManager` 快捷访问 `tabBarController`
    public var tabBarController: AnimatedTabBarController? {
        return RootNavigationController.shared.tabbar
    }

    // 保存当前展示 QuickLaunch 页面的 Window，方便操作
    var quickLaunchWindow: QuickLaunchWindow? {
        return self.tabBarController?.quickLaunchWindow
    }

    var isQuickLaunchWindowShown: Bool {
        quickLaunchWindow != nil
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(quickLaunchWindowDidShow(notification:)), name: .lkQuickLaunchWindowAddRecommandDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(quickLaunchWindowWillDismiss(notification:)), name: .lkQuickLaunchWindowWillDismiss, object: nil)
    }

    func updateDataSourceIfNeeded() {
        guard isQuickLaunchWindowShown else { return }
        quickLaunchWindow?.reloadData()
    }

    @objc
    private func quickLaunchWindowDidShow(notification: NSNotification) {
        if let fromVc = notification.object as? UIViewController {
            self.newWindowRootVc = fromVc
        }
    }

    @objc
    private func quickLaunchWindowWillDismiss(notification: NSNotification) {
        self.newWindowRootVc = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AppInfo

extension QuickLaunchManager {

    /// 获取当前应用对应的 TabIcon 图片
    public func getNavigationAppIcon(appType: AppType, key: String) -> UIImage? {
        if !self.crmodeUnifiedDataDisable {
            if let allTabBarItems = self.tabBarController?.allTabBarItems, let tab = Tab.getTab(appType: appType, key: key) {
                var all: [AbstractTabBarItem]
                if Display.pad {
                    all = allTabBarItems.iPad.main + allTabBarItems.iPad.quick
                } else {
                    all = allTabBarItems.iPhone.main + allTabBarItems.iPhone.quick
                }
                if let item = all.first(where: { $0.tab == tab }) {
                    return item.stateConfig.selectedIcon
                }
            }
        } else {
            if let style = self.tabBarController?.tabbarStyle, let allTabBarItems = self.tabBarController?.allTabBarItems, let tab = Tab.getTab(appType: appType, key: key) {
                var all: [AbstractTabBarItem]
                if style == .bottom {
                    all = allTabBarItems.bottom.main + allTabBarItems.bottom.quick
                } else {
                    all = allTabBarItems.edge.main + allTabBarItems.edge.quick
                }
                if let item = all.first(where: { $0.tab == tab }) {
                    return item.stateConfig.selectedIcon
                }
            }
        }
        return nil
    }
}

// MARK: - Show & Dismiss Launcher

extension QuickLaunchManager {

    /// 调用接口，打开 QuickLaunchWindow
    public func showQuickLaunchWindow(from: MyAIQuickLaunchBarInterface? = nil) {
        tabBarController?.showQuickLaunchWindow(fromBarHeight: from?.launchBarHeight)
    }

    /// 调用接口，关闭 QuickLaunchWindow
    public func dismissQuickLaunchWindow(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let tabBarController = tabBarController else {
            completion?()
            return
        }
        tabBarController.dismissQuickLaunchWindow(animated: animated, completion: completion)
    }
}

// MARK: - Record Recent Pages

extension QuickLaunchManager {

    /// 添加“最近访问”记录
    public func addRecentRecords(vc: TabContainable) {
        guard let navigationAPI = self.navigationAPI else { return }
        var appInfo = RustPB.Basic_V1_NavigationAppInfo()
        let bizType = vc.tabBizType.toAppBizType()
        appInfo.key = ""
        appInfo.appType = .appTypeURL
        if bizType == .webApp || bizType == .miniApp {
            appInfo.appType = .appTypeOpenApp
        }
        appInfo.extra[RecentRecordExtraKey.url] = vc.tabURL
        appInfo.extra[RecentRecordExtraKey.appid] = vc.tabID
        appInfo.extra[RecentRecordExtraKey.bizType] = String(bizType.rawValue)
        appInfo.extra[RecentRecordExtraKey.tabBizId] = vc.tabBizID
        appInfo.extra[RecentRecordExtraKey.docSubType] = String(vc.docInfoSubType)
        if !vc.tabMultiLanguageTitle.isEmpty {
            appInfo.name = vc.tabMultiLanguageTitle
        } else {
            let lang = LanguageManager.currentLanguage.rawValue.lowercased()
            appInfo.name = [lang: vc.tabTitle]
        }
        let uniqueId = Tab.generateAppUniqueId(bizType: vc.tabBizType, appId: vc.tabID)
        appInfo.uniqueID = uniqueId
        Self.logger.info("<NAVIGATION_BAR> add recent records: \(uniqueId)")
        var logo = RustPB.Basic_V1_NavigationAppInfo.Logo()
        logo.customNavigationAppLogo = vc.tabIcon.toCustomAppLogo()
        appInfo.logo = logo
        return navigationAPI.createRecentVisitRecord(appInfo: appInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                Self.logger.info("<NAVIGATION_BAR> add appId to recent record success! appId length: \(vc.tabID.count) name length: \(appInfo.name.count) extra length: \(appInfo.extra.count)")
            }, onError: { error in
                Self.logger.error("<NAVIGATION_BAR> add appId to recent record failed! appId length: : \(vc.tabID.count) name length: \(appInfo.name.count) extra length: \(appInfo.extra.count) error: \(error)")
            })
            .disposed(by: self.disposeBag)
    }

    /// 获取 “最近访问” 列表
    public func getRecentRecords() -> Observable<([RustPB.Basic_V1_NavigationAppInfo])> {
        guard let navigationAPI = self.navigationAPI else { return .empty() }
        return navigationAPI.getRecentVisitRecords().map { (resp: Settings_V1_GetRecentVisitListResponse) in
            Self.logger.info("<NAVIGATION_BAR> get recent visit records count: \(resp.appInfo.count)")
            return resp.appInfo
        }
    }

    /// 移除 “最近打开” 记录
    public func removeRecentRecords(by id: String) {
        guard let navigationAPI = self.navigationAPI else { return }
        return navigationAPI.deleteRecentUsedRecord(uniqueId: id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                Self.logger.info("<NAVIGATION_BAR> delete recent record success! uniqueId: \(id)")
            }, onError: { error in
                Self.logger.error("<NAVIGATION_BAR> delete recent record failed! uniqueId: \(id) error: \(error)")
            })
            .disposed(by: self.disposeBag)
    }
}

// MARK: - Pin、UnPin、Find Page

extension QuickLaunchManager {

    /// 添加应用到主导航（业务方调用）
    public func pinToQuickLaunchWindow(id: String,
                                tabBizID: String,
                                tabBizType: CustomBizType,
                                tabIcon: CustomTabIcon,
                                tabTitle: String,
                                tabURL: String,
                                tabMultiLanguageTitle: [String: String] = [:]) -> Observable<Settings_V1_PinNavigationAppResponse> {
        // 如果是iPad设备的话需要用tabbarStyle来区分是C模式还是R模式
        guard let style = self.tabBarController?.tabbarStyle else {
            Self.logger.error("<NAVIGATION_BAR> pin app to quickLaunchWindow style is nil")
            let resp = RustPB.Settings_V1_PinNavigationAppResponse()
            // 订阅者先收到一个onNext事件，紧接着一个onCompleted事件
            return .just(resp)
        }
        if id.isEmpty {
            Self.logger.error("<NAVIGATION_BAR> pin app to quickLaunchWindow appId is nil")
        }
        if tabURL.isEmpty {
            Self.logger.error("<NAVIGATION_BAR> pin app to quickLaunchWindow url is nil appId length: \(id.count)")
        }
        if tabTitle.isEmpty {
            Self.logger.error("<NAVIGATION_BAR> pin app to quickLaunchWindow title is nil appId length: \(id.count)")
        }
        if tabTitle.isEmpty && tabMultiLanguageTitle.isEmpty {
            Self.logger.error("<NAVIGATION_BAR> pin app to quickLaunchWindow title and multiLanguageTitle is both nil appId length: \(id.count)")
        }
        // 根据入参组装AppInfo
        var appInfo = RustPB.Basic_V1_NavigationAppInfo()
        let bizType = tabBizType.toAppBizType()
        appInfo.key = ""
        appInfo.appType = .appTypeURL
        appInfo.source = .userSource
        appInfo.extra[RecentRecordExtraKey.url] = tabURL
        appInfo.extra[RecentRecordExtraKey.appid] = id
        appInfo.extra[RecentRecordExtraKey.bizType] = String(bizType.rawValue)
        appInfo.extra[RecentRecordExtraKey.tabBizId] = tabBizID
        if !tabMultiLanguageTitle.isEmpty {
            appInfo.name = tabMultiLanguageTitle
        } else {
            let lang = LanguageManager.currentLanguage.rawValue.lowercased()
            appInfo.name = [lang: tabTitle]
        }
        var logo = RustPB.Basic_V1_NavigationAppInfo.Logo()
        logo.customNavigationAppLogo = tabIcon.toCustomAppLogo()
        appInfo.logo = logo
        if logo.customNavigationAppLogo.type == .appLogoTypeCcmIcon {
            appInfo.extra[RecentRecordExtraKey.iconInfo] = logo.customNavigationAppLogo.content
        }
        // 产品要求对所有业务方发起的pin行为重定向到重命名应用标题页面
        DispatchQueue.main.async {
            // 保证在主线程调用
            self.redirectPinAction(appInfo: appInfo, style: style)
        }
        // pin操作没有结果，但重定向到新页面的动作已完成，订阅者会立马收到一个onCompleted事件
        return .empty()
    }
    
    /// 添加页面到主导航（业务方调用）
    public func pinToQuickLaunchWindow(vc: TabContainable) -> Observable<Settings_V1_PinNavigationAppResponse> {
        return self.pinToQuickLaunchWindow(id: vc.tabID,
                                           tabBizID: vc.tabBizID,
                                           tabBizType: vc.tabBizType,
                                           tabIcon: vc.tabIcon,
                                           tabTitle: vc.tabTitle,
                                           tabURL: vc.tabURL,
                                           tabMultiLanguageTitle: vc.tabMultiLanguageTitle)
    }

    /// 添加最近使用数据到主导航
    public func pinToQuickLaunchWindow(tab: TabCandidate) -> Observable<Settings_V1_PinNavigationAppResponse> {
        guard let navigationAPI = self.navigationAPI, let navigationConfigService = self.navigationConfigService else { return .empty() }
        // 如果是iPad设备的话需要用tabbarStyle来区分是C模式还是R模式
        guard let style = self.tabBarController?.tabbarStyle else {
            Self.logger.error("<NAVIGATION_BAR> pin recent used app to quickLaunchWindow mainSceneWindow is nil")
            let resp = RustPB.Settings_V1_PinNavigationAppResponse()
            return .just(resp)
        }
        var appInfo = RustPB.Basic_V1_NavigationAppInfo()
        let bizType = tab.bizType.toAppBizType()
        appInfo.key = ""
        appInfo.appType = .appTypeURL
        appInfo.source = .userSource
        appInfo.extra[RecentRecordExtraKey.url] = tab.url
        appInfo.extra[RecentRecordExtraKey.appid] = tab.id
        appInfo.extra[RecentRecordExtraKey.bizType] = String(bizType.rawValue)
        appInfo.extra[RecentRecordExtraKey.tabBizId] = tab.bizId
        // 如果tab的uniqueId不为空要赋值给appInfo
        if !tab.uniqueId.isEmpty {
            appInfo.uniqueID = tab.uniqueId
        }
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        appInfo.name = [lang: tab.title]
        var logo = RustPB.Basic_V1_NavigationAppInfo.Logo()
        switch tab.icon.type {
        case .byteKey:
            logo.customNavigationAppLogo.type = .appLogoTypeImageKey
        case .udToken:
            logo.customNavigationAppLogo.type = .appLogoTypeUdToken
        case .webURL:
            logo.customNavigationAppLogo.type = .appLogoTypeURL
        case .iconInfo:
            logo.customNavigationAppLogo.type = .appLogoTypeCcmIcon
        @unknown default:
            logo.customNavigationAppLogo.type = .appLogoTypeUnknown
        }

        logo.customNavigationAppLogo.content = tab.icon.content
        appInfo.logo = logo
        if tab.id.isEmpty || tab.url.isEmpty || tab.title.isEmpty {
            // 最近访问pin的时候虽然允许这些参数为空，但是肯定是有问题的，所以需要打个错误日志，方便排查为什么会有这些“脏数据”
            Self.logger.error("<NAVIGATION_BAR> pin recent used appId: \(tab.id) to quick launch window has empty parameter uniqueId = \(appInfo.uniqueID) name: \(appInfo.name) extra: \(appInfo.extra)")
        }
        DispatchQueue.main.async {
            // 保证在主线程调用
            if let topView = self.tabBarController?.quickLaunchWindow {
                self.hud.showLoading(with: BundleI18n.LarkNavigation.Lark_Legacy_BaseUiLoading, on: topView, disableUserInteraction: true)
            }
        }
        return navigationAPI.pinAppToNavigation(appInfo: appInfo, style: style)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] resp in
                Self.logger.info("<NAVIGATION_BAR> pin recent used appId: \(tab.id) to quick launch window success! uniqueId = \(appInfo.uniqueID) name: \(appInfo.name) extra: \(appInfo.extra)")
                guard let self = self, let mainTabBar = self.tabBarController as? MainTabbarController else { return }
                self.hud.remove()
                if self.tabBarController?.tabbarStyle == .edge, self.temporaryTabService?.tabs.contains(where: {
                    $0.uniqueId == appInfo.uniqueID
                }) ?? false {
                    self.temporaryTabService?.removeTab(ids: [tab.uniqueId])
                }
                let batchResponse = self.parsePinResponse(resp)
                let response = AllNavigationInfoResponse(response: batchResponse)
                navigationConfigService.saveToUD(response: response)
                mainTabBar.handleUpdateTabNow(showTips: false)
                self.updateDataSourceIfNeeded()
            }, onError: { [weak self] error in
                Self.logger.error("<NAVIGATION_BAR> pin recent used appId: \(tab.id) to quick launch window failed! uniqueId = \(appInfo.uniqueID) name: \(appInfo.name) extra: \(appInfo.extra) error: \(error)")
                guard let self = self, let topView = self.tabBarController?.quickLaunchWindow else { return }
                self.hud.remove()
                let (_, errorMessage) = self.getNavigationErrorMessage(error: error)
                UDToast.showFailure(with: errorMessage, on: topView)
            })
    }

    /// 从主导航中删除页面
    public func unPinFromQuickLaunchWindow(appId: String, tabBizType: CustomBizType) -> Observable<Settings_V1_UnPinNavigationAppResponse> {
        guard let navigationAPI = self.navigationAPI, let navigationConfigService = self.navigationConfigService else { return .empty() }
        // 如果是iPad设备的话需要用tabbarStyle来区分是C模式还是R模式
        guard let style = self.tabBarController?.tabbarStyle else {
            Self.logger.error("<NAVIGATION_BAR> unpin app from quickLaunchWindow mainSceneWindow is nil")
            let resp = RustPB.Settings_V1_UnPinNavigationAppResponse()
            return .just(resp)
        }
        let bizType = tabBizType.toAppBizType()
        DispatchQueue.main.async {
            // 保证在主线程调用
            if let topView = self.userResolver.navigator.mainSceneWindow {
                self.hud.showLoading(with: BundleI18n.LarkNavigation.Lark_Legacy_BaseUiLoading, on: topView, disableUserInteraction: true)
            }
        }
        return navigationAPI.unpinNavigationApp(appId: appId, bizType: bizType, style: style)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] resp in
                Self.logger.info("<NAVIGATION_BAR> unpin appId: \(appId) from quick launch window success! bizType = \(bizType) style: \(style)")
                guard let self = self, let mainTabBar = self.tabBarController as? MainTabbarController else { return }
                let uuid = generateAppUniqueId(bizType: tabBizType, appId: appId)
                var appType: AppType = .appTypeURL
                if tabBizType == .MINI_APP || tabBizType == .WEB_APP {
                    appType = .appTypeOpenApp
                }
                // 自定义应用被unpin的话需要从注册map里面删除，否则会有内存泄露
                if let tab = Tab.getTab(appType: appType, key: uuid) {
                    _ = TabRegistry.unregister(tab)
                }
                self.hud.remove()
                let batchResponse = self.parseUnPinResponse(resp)
                let response = AllNavigationInfoResponse(response: batchResponse)
                navigationConfigService.saveToUD(response: response)
                mainTabBar.handleUpdateTabNow(showTips: false)
                self.updateDataSourceIfNeeded()
            }, onError: { [weak self] error in
                Self.logger.error("<NAVIGATION_BAR> unpin appId: \(appId) from quick launch window failed! bizType = \(bizType) style: \(style) error: \(error)")
                guard let self = self, let topView = self.userResolver.navigator.mainSceneWindow else { return }
                self.hud.remove()
                let (_, errorMessage) = self.getNavigationErrorMessage(error: error)
                UDToast.showFailure(with: errorMessage, on: topView)
        })
    }
    public func unPinFromQuickLaunchWindow(vc: TabContainable) -> Observable<Settings_V1_UnPinNavigationAppResponse> {
        return self.unPinFromQuickLaunchWindow(appId: vc.tabID, tabBizType: vc.tabBizType)
    }

    /// 查询页面是否在主导航中
    public func findInQuickLaunchWindow(vc: TabContainable) -> Observable<Bool> {
        return self.findInQuickLaunchWindow(appId: vc.tabID, tabBizType: vc.tabBizType)
    }

    public func findInQuickLaunchWindow(appId: String, tabBizType: CustomBizType) -> Observable<Bool> {
        guard let navigationAPI = self.navigationAPI else { return .empty() }
        // 如果是iPad设备的话需要用tabbarStyle来区分是C模式还是R模式
        guard let style = self.tabBarController?.tabbarStyle else {
            return .just(false)
        }
        return navigationAPI.findAppExistInNavigation(appId: appId, bizType: tabBizType.toAppBizType(), style: style)
            .observeOn(MainScheduler.instance)
            .do(onNext: { isInWindow in
                Self.logger.info("<NAVIGATION_BAR> find appId is in quick launch window success! appId length = \(appId.count) isInWindow = \(isInWindow) bizType: \(tabBizType.toAppBizType()) style: \(style)")
        }, onError: { error in
            Self.logger.error("<NAVIGATION_BAR> find appId is in quick launch window failed! appId length = \(appId.count) bizType: \(tabBizType.toAppBizType()) style: \(style) error: \(error)")
        })
    }
    
    /// 获取全量导航
    public func getNavigationApps() -> Observable<Settings_V1_GetNavigationAppsResponse> {
        guard let navigationAPI = self.navigationAPI else { return .empty() }
        return navigationAPI.getNavigationApps()
    }

    public func updateNavigationInfos(appInfos: [RustPB.Basic_V1_NavigationAppInfo]) -> Observable<Void> {
        guard let navigationAPI = self.navigationAPI else { return .empty() }
        return navigationAPI.updateNavigationInfos(appInfos: appInfos)
    }

    /// 生成应用的唯一id
    public func generateAppUniqueId(bizType: CustomBizType, appId: String) -> String {
        // 按照SDK的格式生成每个应用的唯一id：{biz_type}_{md5(app_id)}
        let uuid = bizType.stringValue + "_" + appId.md5()
        Self.logger.info("<NAVIGATION_BAR> bizType = \(bizType), appId length = \(appId.count), uniqueId = \(uuid)")
        return uuid
    }

    /// 获取错误代码和信息
    public func getNavigationErrorMessage(error: Error) -> (Int32, String) {
        var errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavBarUpdateFail_Toast
        var errorCode: Int32 = 0
        if let err = error as? RCError {
            switch err {
            case .businessFailure(let errorInfo):
                errorCode = errorInfo.errorCode
                /* 导航栏[350100-350200] */
                if errorCode == 350100 {
                    // NAVIGATION_CUSTOM_APP_BEYOND_LIMIT = 350100：用户自定义应用超出了数量限制
                    errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavbarUpdate_CantPinNumReached_Toast
                } else if errorCode == 350102 {
                    // NAVIGATION_UNIQUE_ID_DUPLICATE = 350102：应用ID不能重复
                    errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavbarUpdate_AppExistsAlready_Toast
                } else if errorCode == 350107 {
                    // NNAVIGATION_REQ_VERSION_NOT_LATEST = 350107：传参数导航栏version不是最新的
                    errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavBarUpdateFailRefresh_Toast
                }
            default:
                errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavBarUpdateFail_Toast
            }
        }
        return (errorCode, errorMessage)
    }

    func transformByPinNavigationAppResponse(_ resp: Settings_V1_PinNavigationAppResponse) -> NavigationAppInfoResponse {
        var appInfoResponse = NavigationAppInfoResponse()
        appInfoResponse.appInfo = resp.appInfo
        appInfoResponse.primaryCount = resp.primaryCount
        appInfoResponse.totalCount = resp.totalCount
        appInfoResponse.platform = resp.platform
        return appInfoResponse
    }

    func parsePinResponse(_ resp: Settings_V1_PinNavigationAppResponse) -> NavigationAppInfoBatchResponse {
        guard let navigationConfigService = self.navigationConfigService else { return NavigationAppInfoBatchResponse() }
        var batchResponse: NavigationAppInfoBatchResponse
        // 从本地数据库中取出所有平台的导航（mobile+ipad）
        if let response = navigationConfigService.getNavigationInfoByLocal()?.response {
            batchResponse = response
        } else {
            batchResponse = NavigationAppInfoBatchResponse()
        }
        // 字典里面应该有2份数据：mobile+ipad
        var map = [Settings_V1_NavigationPlatform: NavigationAppInfoResponse]()
        // 把字典里面的数据先初始换成本地缓存的（数据库）
        batchResponse.responses.forEach({ map[$0.platform] = $0 })
        var array: [NavigationAppInfoResponse] = []
        // 处理底部导航
        var bottom = map[.navMobile] ?? NavigationAppInfoResponse()
        if resp.platform == .navMobile {
            // 更新数据，以服务端给的为准
            bottom = transformByPinNavigationAppResponse(resp)
        }
        array.append(bottom)
        // 处理侧边栏导航
        var edge = map[.navIpad] ?? NavigationAppInfoResponse()
        if resp.platform == .navIpad {
            // 更新数据，以服务端给的为准
            edge = transformByPinNavigationAppResponse(resp)
        }
        array.append(edge)
        batchResponse.responses = array
        return batchResponse
    }

    func transformByUnPinNavigationAppResponse(_ resp: Settings_V1_UnPinNavigationAppResponse) -> NavigationAppInfoResponse {
        var appInfoResponse = NavigationAppInfoResponse()
        appInfoResponse.appInfo = resp.appInfo
        appInfoResponse.primaryCount = resp.primaryCount
        appInfoResponse.totalCount = resp.totalCount
        appInfoResponse.platform = resp.platform
        return appInfoResponse
    }
    
    func parseUnPinResponse(_ resp: Settings_V1_UnPinNavigationAppResponse) -> NavigationAppInfoBatchResponse {
        guard let navigationConfigService = self.navigationConfigService else { return NavigationAppInfoBatchResponse() }
        var batchResponse: NavigationAppInfoBatchResponse
        // 从本地数据库中取出所有平台的导航（mobile+ipad）
        if let response = navigationConfigService.getNavigationInfoByLocal()?.response {
            batchResponse = response
        } else {
            batchResponse = NavigationAppInfoBatchResponse()
        }
        // 字典里面应该有2份数据：mobile+ipad
        var map = [Settings_V1_NavigationPlatform: NavigationAppInfoResponse]()
        // 把字典里面的数据先初始换成本地缓存的（数据库）
        batchResponse.responses.forEach({ map[$0.platform] = $0 })
        var array: [NavigationAppInfoResponse] = []
        // 处理底部导航
        var bottom = map[.navMobile] ?? NavigationAppInfoResponse()
        if resp.platform == .navMobile {
            // 更新数据，以服务端给的为准
            bottom = transformByUnPinNavigationAppResponse(resp)
        }
        array.append(bottom)
        // 处理侧边栏导航
        var edge = map[.navIpad] ?? NavigationAppInfoResponse()
        if resp.platform == .navIpad {
            // 更新数据，以服务端给的为准
            edge = transformByUnPinNavigationAppResponse(resp)
        }
        array.append(edge)
        batchResponse.responses = array
        return batchResponse
    }

    // 重定向到重命名页面
    func redirectPinAction(appInfo: RustPB.Basic_V1_NavigationAppInfo, style: TabbarStyle) {
        let viewController = TabRenameViewController(userResolver: self.userResolver, appInfo: appInfo, style: style) { [weak self] (app, resp) in
            // 应用pin成功过后的回调
            guard let self = self, let id = app.extra[RecentRecordExtraKey.appid], let navigationConfigService = self.navigationConfigService, let mainTabBar = self.tabBarController as? MainTabbarController else {
                Self.logger.error("<NAVIGATION_BAR> navigationConfigService == nil or mainTabBar == nil")
                return
            }
            // iPad临时区相关逻辑
            if let uniqueID = resp.appInfo.first(where: {
                $0.extra[RecentRecordExtraKey.appid] == id
            })?.uniqueID, self.tabBarController?.tabbarStyle == .edge, self.temporaryTabService?.tabs.contains(where: {
                $0.uniqueId == uniqueID
            }) ?? false {
                self.temporaryTabService?.removeTab(id: uniqueID)
            }
            // 把最新的导航结果存端上DB
            let batchResponse = self.parsePinResponse(resp)
            let response = AllNavigationInfoResponse(response: batchResponse)
            navigationConfigService.saveToUD(response: response)
            mainTabBar.handleUpdateTabNow(showTips: false)
            self.updateDataSourceIfNeeded()
        }
        switch style {
        case .edge:
            viewController.modalPresentationStyle = .formSheet
        case .bottom:
            viewController.modalPresentationStyle = .formSheet
        @unknown default:
            viewController.modalPresentationStyle = .formSheet
        }
        if let newWindowFromVc = newWindowRootVc, let nav = newWindowFromVc.navigationController {
            //处理添加页面新window弹出设置导航页面层级问题
            navigator.present(viewController, from:nav)
        } else if let topVC = navigator.mainSceneTopMost {
            topVC.present(viewController, animated: true)
        } else {
            Self.logger.error("<NAVIGATION_BAR> pin app mainSceneTopMost == nil")
            if let topView = navigator.mainSceneWindow {
                navigator.present(viewController, from: topView)
            } else {
                Self.logger.error("<NAVIGATION_BAR> pin app mainSceneWindow == nil")
            }
        }
    }
}
