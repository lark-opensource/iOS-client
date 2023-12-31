//
//  NavigationConfigService.swift
//  LarkNavigation
//
//  Created by Meng on 2019/11/5.
//

import UIKit
import Foundation
import LKCommonsLogging
import RxSwift
import RxCocoa
import EEAtomic
import LarkContainer
import LarkUIKit
import LarkExtensions
import LarkAppConfig
import AnimatedTabBar
import SuiteAppConfig
import LarkTab
import LarkStorage
import RustPB
import RunloopTools
import LarkFeatureSwitch
import LarkSetting
import UniverseDesignToast
import LarkRustClient
import EENavigator

struct NavigationConfig {
    /// settings.v3 key
    static let settingsKey: String = "lark_navigation"
    #if DEBUG
    static let mainTabRange: ClosedRange<Int> = 1...5
    #else
    static let mainTabRange: ClosedRange<Int> = 1...5
    #endif
}

final class NavigationConfigService: UserResolverWrapper {
    public var userResolver: UserResolver

    static let logger = Logger.log(NavigationConfigService.self, category: "LarkNavigation.NavigationConfigService")

    private let disposeBag = DisposeBag()

    /// Default return local kv configs (fastLogin && !switchAccount)
    /// if ([after login] or [switch account]) & no local configs
    ///     load from remote & save to UserDefaults
    ///
    /// after launch home, configs will never change.
    private(set) var originalAllTabsinfo: AllNavigationInfoResponse? {
        didSet {
            guard let originalNavigationInfo = originalAllTabsinfo else { return }
            // 这个数据源发生变化，说明UI发生了变化，需要通知订阅的业务方
            naviInfosSubject.onNext(originalNavigationInfo)
        }
    }

    private let userId: String
    private lazy var userStore = KVStores.Navigation.build(forUser: userId)
    private let pushCenter: PushNotificationCenter
    @ScopedInjectedLazy var navigationAPI: NavigationAPI?

    private let saveDataSerialQueue = DispatchQueue(label: "com.lark.navigation.saveDataQueue")
    private lazy var scheduler = SerialDispatchQueueScheduler(queue: saveDataSerialQueue, internalSerialQueueName: saveDataSerialQueue.label)

    private var bottomAddList: Array<String> = []
    private var bottomDeleteList: Array<String> = []
    private var sidebarAddList: Array<String> = []
    private var sidebarDeleteList: Array<String> = []
    // iPad CRMode数据统一：GA后上面的可以删除，只保留下面的四个属性
    private var iPhoneAddList: Array<String> = []
    private var iPhoneDeleteList: Array<String> = []
    private var iPadAddList: Array<String> = []
    private var iPadDeleteList: Array<String> = []
    private var authChangeDeleteList: Array<String> = []
    private var authChangeAddList: Array<String> = []

    private let lock = UnfairLockCell()

    /// AppConfig navi feature and trait check
    /// lean-mode: naviFeatureEnable = true
    /// norm-mode: naviFeatureEnable = false
    var naviFeatureEnable: Bool {
        return AppConfigManager.shared.leanModeIsOn
    }

    var updateTabResourceEnable: Bool {
        return self.featureGatingService.staticFeatureGatingValue(with: "lark.core.daohanglan.update")
    }

    var tabRemoteUpdateTipEnable: Bool {
        return self.featureGatingService.staticFeatureGatingValue(with: "lark.core.navigation_menu.change_notice")
    }

    // FG：CRMode数据统一
    var crmodeUnifiedDataDisable: Bool {
        return self.featureGatingService.staticFeatureGatingValue(with: "lark.navigation.disable.crmode")
    }

    private let dependency: NavigationServiceImplDependency

    internal var appCenterEnable: Bool
    internal var calendarEnable: Bool
    internal var featureGatingService: FeatureGatingService

    /// 物料更新触发UI刷新信号
    private let dataChangeSubject: PublishSubject<Void> = PublishSubject<Void>()
    var dataChangeObservable: Observable<(Void)> {
        return dataChangeSubject.asObservable()
    }

    /// 底部导航栏（包含iPad设备C模式下的底部栏）变更触发提示信号
    private let bottomTabBarUpdateShowTipSubject: PublishSubject<String> = PublishSubject<String>()
    var bottomTabBarUpdateShowTipObservable: Observable<String> {
        return bottomTabBarUpdateShowTipSubject.asObservable()
    }
    
    /// 侧边导航栏（iPad设备）变更触发提示信号
    private let sideTabBarUpdateShowTipSubject: PublishSubject<String> = PublishSubject<String>()
    var sideTabBarUpdateShowTipObservable: Observable<String> {
        return sideTabBarUpdateShowTipSubject.asObservable()
    }

    // iPad CRMode数据统一：GA后上面的可以删除，只保留下面的两个属性
    private let iPhoneTabBarUpdateShowTipSubject: PublishSubject<String> = PublishSubject<String>()
    var iPhoneTabBarUpdateShowTipObservable: Observable<String> {
        return iPhoneTabBarUpdateShowTipSubject.asObservable()
    }
    private let iPadTabBarUpdateShowTipSubject: PublishSubject<String> = PublishSubject<String>()
    var iPadTabBarUpdateShowTipObservable: Observable<String> {
        return iPadTabBarUpdateShowTipSubject.asObservable()
    }

    private let naviInfosSubject: PublishSubject<AllNavigationInfoResponse> = PublishSubject<AllNavigationInfoResponse>()
    var naviInfosObservable: Observable<AllNavigationInfoResponse> {
        return naviInfosSubject.asObservable()
    }

    init(userResolver: UserResolver,
         appCenterEnable: Bool,
         pushCenter: PushNotificationCenter,
         featureGatingService: FeatureGatingService,
         dependency: NavigationServiceImplDependency) {
        self.pushCenter = pushCenter
        self.featureGatingService = featureGatingService
        self.appCenterEnable = appCenterEnable
        self.dependency = dependency
        self.calendarEnable = true
        self.userResolver = userResolver
        self.userId = userResolver.userID

        Feature.on(.calendarTab).apply(on: {}, off: {
            self.calendarEnable = false
        })

        if let info = getNavigationInfoByLocal() {
            originalAllTabsinfo = info
        }
        observeNavigationInfo()
    }

    internal var mailEnable: Bool {
        if !mailFeatureSwitch {
            return false
        }
        return dependency.mailEnable
    }

    internal var mailFeatureSwitch: Bool {
        var status = true
        Feature.on(.mailTab).apply(on: {}, off: {
            status = false
        })
        return status
    }

    func isSupportTab(meta: TabMeta) -> Bool {
        if let tabType = AppType(rawValue: meta.appType) {
            var url: String = ""
            if tabType == .gadget { url = Tab.gadgetPrefix + meta.key }
            if tabType == .webapp { url = Tab.webAppPrefix + meta.key }
            if tabType == .appTypeCustomNative { url = Tab.appTypeCustomNative + meta.key }
            // 如果是appTypeURL或者appTypeOpenApp（不管是租户配置还是用户配置都默认支持）
            if tabType == .appTypeURL || tabType == .appTypeOpenApp { return true }
            let tab = Tab(url: url, appType: tabType, key: meta.key, source: .tenantSource)
            return TabRegistry.contain(tab)
        }
        return false
    }

    internal func featureGatingEnableFliter(key: String, tab: Tab) -> Bool {
        return featureGatingEnable(key: key, appType: tab.appType)
    }

    private func featureGatingEnable(key: String, appType: AppType) -> Bool {
        switch appType {
        case .native:
            if key == Tab.appCenter.key { return appCenterEnable }
            if key == Tab.mail.key { return mailFeatureSwitch }
            if key == Tab.calendar.key { return calendarEnable }
            return true
        case .gadget, .webapp, .appTypeCustomNative, .appTypeOpenApp, .appTypeURL:
            return true
        @unknown default:
            return false
        }
    }

    func reloadLocalData() -> AllNavigationInfoResponse? {
        if let info = getNavigationInfoByLocal() {
            originalAllTabsinfo = info
            return info
        }
        return nil
    }

    // 通知Rust tab切换
    func noticeRustSwitchTab(tabKey: String) {
        guard let navigationAPI = self.navigationAPI else { return }
        navigationAPI.noticeRustSwitchTab(tabKey: tabKey).subscribe().disposed(by: disposeBag)
    }

    // 修改导航栏顺序（新版）
    func modifyNavigationOrder(tabbarStyle: TabbarStyle, mainTabItems: [AbstractTabBarItem], quickTabItems: [AbstractTabBarItem]) -> Observable<AllNavigationInfoResponse?> {
        Self.logger.info("<NAVIGATION_BAR> modify navigation order: isIpad = \(Display.pad) tabBarStyle = \(tabbarStyle)",
                         additionalData: ["mainIDs": "\(mainTabItems.map { $0.tab.uniqueId })",
                                          "mainKeys": "\(mainTabItems.map { $0.tab.key })",
                                          "quickIDs": "\(quickTabItems.map { $0.tab.uniqueId })",
                                          "quickKeys": "\(quickTabItems.map { $0.tab.key })"])
        guard let navigationAPI = self.navigationAPI else { return .empty() }
        guard let topView = navigator.mainSceneWindow else {
            Self.logger.error("<NAVIGATION_BAR> modify navigation order mainSceneWindow is nil")
            return .just(nil)
        }
        let hud: UDToast = UDToast()
        return navigationAPI.modifyNavigationOrder(tabbarStyle: tabbarStyle, mainTabItems: mainTabItems, quickTabItems: quickTabItems)
            .observeOn(self.scheduler)
            .flatMap({ [weak self] (info) -> Observable<AllNavigationInfoResponse?> in
                guard let self = self else { return .just(nil) }
                guard let response = self.parseSingleResponse(info) else { return .just(nil) }
                NavigationConfigService.logger.info("<NAVIGATION_BAR> modify navigation order begin save to UD")
                self.saveToUD(response: response)
                return .just(response)
            })
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] allTabsInfo in
                guard let self = self else { return }
                self.originalAllTabsinfo = allTabsInfo
            }, onError: { [weak self] error in
                Self.logger.error("<NAVIGATION_BAR> modify navigation error", error: error)
                guard let self = self else { return }
                let (_, errorMessage) = self.getNavigationErrorMessage(error: error)
                hud.showFailure(with: errorMessage, on: topView)
            })
    }

    // 修改导航栏顺序（旧版）
    func modifyNavigationOrder(tabbarStyle: TabbarStyle, main: [AbstractRankItem], quick: [AbstractRankItem]) -> Observable<AllNavigationInfoResponse?> {
        Self.logger.info("<NAVIGATION_BAR> modify navigation order",
                         additionalData: ["mainIDs": "\(main.map { $0.uniqueID })",
                                          "mainKeys": "\(main.map { $0.tab.key })",
                                          "quickIDs": "\(quick.map { $0.uniqueID })",
                                          "quickKeys": "\(quick.map { $0.tab.key })"])
        guard let navigationAPI = self.navigationAPI else { return .empty() }
        guard let topView = Navigator.shared.mainSceneWindow else {
            Self.logger.error("<NAVIGATION_BAR> modify navigation order mainSceneWindow is nil")
            return .just(nil)
        }
        let hud: UDToast = UDToast()
        return navigationAPI.modifyNavigationOrder(tabbarStyle: tabbarStyle, mainItems: main, quickItems: quick)
            .observeOn(self.scheduler)
            .flatMap({ [weak self] (info) -> Observable<AllNavigationInfoResponse?> in
                guard let self = self else { return .just(nil) }
                guard let response = self.parseSingleResponse(info) else { return .just(nil) }
                NavigationConfigService.logger.info("<NAVIGATION_BAR> modify navigation order begin save to UD")
                self.saveToUD(response: response)
                return .just(response)
            })
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] allTabsInfo in
                guard let self = self else { return }
                self.originalAllTabsinfo = allTabsInfo
            }, onError: { [weak self] error in
                Self.logger.error("<NAVIGATION_BAR> modify navigation error", error: error)
                guard let self = self else { return }
                let (_, errorMessage) = self.getNavigationErrorMessage(error: error)
                hud.showFailure(with: errorMessage, on: topView)
            })
    }
    
    // 获取错误代码和信息
    func getNavigationErrorMessage(error: Error) -> (Int32, String) {
        var errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavBarUpdateFail_Toast
        var errorCode: Int32 = 0
        if let err = error as? RCError {
            switch err {
            case .businessFailure(let errorInfo):
                errorCode = errorInfo.errorCode
                /* 导航栏[350100-350200] */
                // nolint: magic_number errorcode
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
}

// MARK: - tab guide
extension NavigationConfigService {
    // iPhone设备或者iPad设备的更新提示
    func handleTabBarUpdate(addList: Array<String>, deleteList: Array<String>, newNaviInfo: AllNavigationInfoResponse) {
        guard self.tabRemoteUpdateTipEnable else { return }
        // 精简模式开启情况下不做处理
        guard !self.naviFeatureEnable else {
            Self.logger.info("<NAVIGATION_BAR> in lean mode")
            return
        }
        guard originalAllTabsinfo != nil else {
            Self.logger.info("<NAVIGATION_BAR> original data is empty")
            return
        }
        // 只有当addList和deleteList都为空的时候（顺序改变或者用户一直不点更新确认）才走下面的逻辑，否则直接跳过走增加或者删除了哪些应用的逻辑
        if addList.isEmpty && deleteList.isEmpty {
            // 检查是否需要忽略本次更新提示：新增和删除的内容和上次一样（没有变化）那就直接返回
            if self.checkNeedIgnoreUpdate(newNaviInfo: newNaviInfo) {
                return
            }
            // 没有新增或者删除，那就要比较顺序有没有发生变化
            if let orderNotice = self.diffOrderNotice(newNaviInfo: newNaviInfo) {
                // order has changed, triger notice signal
                if Display.pad {
                    self.iPadTabBarUpdateShowTipSubject.onNext(orderNotice)
                } else {
                    self.iPhoneTabBarUpdateShowTipSubject.onNext(orderNotice)
                }
                return
            }
        }
        lock.lock()
        defer {
            lock.unlock()
        }
        // 1. merge add list & delete list
        self.mergeUpdateData(addList: addList, deleteList: deleteList)
        // 2. convert ids of add-list to names of add-list
        // 新增的以传入的（新）数据为准
        var newAppInfos = newNaviInfo.iPhone
        if Display.pad {
            newAppInfos = newNaviInfo.iPad
        }
        let addNames = self.transformAppIdToNames(ids: addList, appInfos: newAppInfos)
        Self.logger.info("<NAVIGATION_BAR> server add keys = \(addList), names = \(addNames)")
        // 3. convert ids of delete-list to names of delete-list
        // 删除的以当前显示的（老）数据为准
        var oldAppInfos = originalAllTabsinfo?.iPhone
        if Display.pad {
            oldAppInfos = originalAllTabsinfo?.iPad
        }
        let deleteNames = self.transformAppIdToNames(ids: deleteList, appInfos: oldAppInfos)
        Self.logger.info("<NAVIGATION_BAR> server delete keys = \(self.iPhoneDeleteList), names = \(deleteNames)")
        // 4. diff the other of apps change, such as fg or authorization chage
        self.diffAuthChangeApplist(newNaviInfo: newNaviInfo)
        let authChangeDeleteNames = self.transformAppIdToNames(ids: self.authChangeDeleteList, appInfos: oldAppInfos)
        Self.logger.info("<NAVIGATION_BAR> auth change delete keys = \(self.authChangeDeleteList), names = \(authChangeDeleteNames)")
        let authChangeAddNames = self.transformAppIdToNames(ids: self.authChangeAddList, appInfos: newAppInfos)
        Self.logger.info("<NAVIGATION_BAR> auth change add keys = \(self.authChangeAddList), names = \(authChangeAddNames)")
        // 5. publish the signal to update UI
        guard (!addNames.isEmpty ||
               !deleteNames.isEmpty ||
               !authChangeAddNames.isEmpty ||
               !authChangeDeleteNames.isEmpty)
        else {
            // trigger empty string signal to remove current notice view
            if Display.pad {
                self.iPadTabBarUpdateShowTipSubject.onNext("")
            } else {
                self.iPhoneTabBarUpdateShowTipSubject.onNext("")
            }
            Self.logger.info("<NAVIGATION_BAR> has no update notice")
            return
        }
        let notice = self.formatTips(addNames: addNames,
                                     deleteNames: deleteNames,
                                     authChangeAddNames: authChangeAddNames,
                                     authChangeDeleteNames: authChangeDeleteNames)
        if Display.pad {
            self.iPadTabBarUpdateShowTipSubject.onNext(notice)
        } else {
            self.iPhoneTabBarUpdateShowTipSubject.onNext(notice)
        }
    }

    private func mergeUpdateData(addList: Array<String>, deleteList: Array<String>) {
        Self.logger.info("<NAVIGATION_BAR> remote add list: \(addList), delete list: \(deleteList)")
        // 以服务端push的数据为准，要区分iPhone和iPad设备，不能使用同一份缓存进行数据merge，会串数据的
        if Display.pad {
            self.iPadAddList = addList
            self.iPadDeleteList = deleteList
        } else {
            self.iPhoneAddList = addList
            self.iPhoneDeleteList = deleteList
        }
    }

    private func diffAuthChangeApplist(newNaviInfo: AllNavigationInfoResponse) {
        // 新数据、与当前展示数据做diff，且不在diff list里的属于权限问题少的
        var allNewIdSets: Set<String> = []
        var currentIdSets: Set<String> = []
        if Display.pad {
            newNaviInfo.iPad.response.appInfo.forEach({ appInfo in
                allNewIdSets.insert(appInfo.uniqueID)
            })
            originalAllTabsinfo?.iPad.response.appInfo.forEach({ appInfo in
                currentIdSets.insert(appInfo.uniqueID)
            })
        } else {
            newNaviInfo.iPhone.response.appInfo.forEach({ appInfo in
                allNewIdSets.insert(appInfo.uniqueID)
            })
            originalAllTabsinfo?.iPhone.response.appInfo.forEach({ appInfo in
                currentIdSets.insert(appInfo.uniqueID)
            })
        }
        var deleteListSet = Set(self.iPhoneDeleteList.map({ $0 }))
        var addListSet = Set(self.iPhoneAddList.map({ $0 }))
        if Display.pad {
            deleteListSet = Set(self.iPadDeleteList.map({ $0 }))
            addListSet = Set(self.iPadAddList.map({ $0 }))
        }
        let diffDeleteList = currentIdSets.subtracting(allNewIdSets).subtracting(deleteListSet)
        let diffAddList = allNewIdSets.subtracting(currentIdSets).subtracting(addListSet)
        self.authChangeDeleteList = Array(diffDeleteList)
        self.authChangeAddList = Array(diffAddList)
        Self.logger.info("<NAVIGATION_BAR> auth change add list: \(self.authChangeAddList), delete list: \(self.authChangeDeleteList)")
    }

    // Mobile设备的底部栏和iPad设备C视图的更新提示（CRMode数据统一GA后删除）
    func handleBottomTabBarUpdate(addList: Array<String>, deleteList: Array<String>, newNaviInfo: AllNavigationInfoResponse) {
        guard self.tabRemoteUpdateTipEnable else { return }
        // 精简模式开启情况下不做处理
        guard !self.naviFeatureEnable else {
            Self.logger.info("<NAVIGATION_BAR> in lean mode bottomBar")
            return
        }
        guard originalAllTabsinfo != nil else {
            Self.logger.info("<NAVIGATION_BAR> original data is empty bottomBar")
            return
        }
        // 只有当addList和deleteList都为空的时候（顺序改变或者用户一直不点更新确认）才走下面的逻辑，否则直接跳过走增加或者删除了哪些应用的逻辑
        if addList.isEmpty && deleteList.isEmpty {
            // 检查是否需要忽略本次更新提示：新增和删除的内容和上次一样（没有变化）那就直接返回
            if self.checkNeedIgnoreUpdate(newNaviInfo: newNaviInfo, isSideBar: false) {
                return
            }
            // 没有新增或者删除，那就要比较顺序有没有发生变化
            if let orderNotice = self.diffOrderNotice(newNaviInfo: newNaviInfo, isSideBar: false) {
                // order has changed, triger notice signal
                self.bottomTabBarUpdateShowTipSubject.onNext(orderNotice)
                return
            }
        }
        lock.lock()
        defer {
            lock.unlock()
        }
        // 1. merge add list & delete list
        self.mergeUpdateData(addList: addList, deleteList: deleteList, isSideBar: false)
        // 2. convert ids of add-list to names of add-list
        // 新添加以获取最新的数据为准
        let bottom = newNaviInfo.bottom
        let addNames = self.transformAppIdToNames(ids: self.bottomAddList, appInfos: bottom)
        Self.logger.info("<NAVIGATION_BAR> server add keys = \(self.bottomAddList), names = \(addNames) bottomBar")
        // 3. convert ids of delete-list to names of delete-list
        // 删除的以当前显示的数据为准
        let currentBottom = originalAllTabsinfo?.bottom
        let deleteNames = self.transformAppIdToNames(ids: self.bottomDeleteList, appInfos: currentBottom)
        Self.logger.info("<NAVIGATION_BAR> server delete keys = \(self.bottomDeleteList), names = \(deleteNames) bottomBar")
        // 4. diff the other of apps change, such as fg or authorization chage
        self.diffAuthChangeApplist(newNaviInfo: newNaviInfo, tabbarStyle: .bottom)
        let authChangeDeleteNames = self.transformAppIdToNames(ids: self.authChangeDeleteList, appInfos: currentBottom)
        Self.logger.info("<NAVIGATION_BAR> auth change delete keys = \(self.authChangeDeleteList), names = \(authChangeDeleteNames) bottomBar")
        let authChangeAddNames = self.transformAppIdToNames(ids: self.authChangeAddList, appInfos: bottom)
        Self.logger.info("<NAVIGATION_BAR> auth change add keys = \(self.authChangeAddList), names = \(authChangeAddNames) bottomBar")
        // 5. publish the signal to update UI
        guard (!addNames.isEmpty ||
               !deleteNames.isEmpty ||
               !authChangeAddNames.isEmpty ||
               !authChangeDeleteNames.isEmpty)
        else {
            // trigger empty string signal to remove current notice view
            self.bottomTabBarUpdateShowTipSubject.onNext("")
            Self.logger.info("<NAVIGATION_BAR> has no update notice bottomBar")
            return
        }
        let notice = self.formatTips(addNames: addNames,
                                     deleteNames: deleteNames,
                                     authChangeAddNames: authChangeAddNames,
                                     authChangeDeleteNames: authChangeDeleteNames)
        self.bottomTabBarUpdateShowTipSubject.onNext(notice)
    }

    // 新需求，iPad设备R视图也需要更新提示（CRMode数据统一GA后删除）
    func handleSideBarUpdate(addList: Array<String>, deleteList: Array<String>, newNaviInfo: AllNavigationInfoResponse) {
        guard self.tabRemoteUpdateTipEnable else { return }
        // 精简模式开启情况下不做处理
        guard !self.naviFeatureEnable else {
            Self.logger.info("<NAVIGATION_BAR> in lean mode sideBar")
            return
        }
        guard originalAllTabsinfo != nil else {
            Self.logger.info("<NAVIGATION_BAR> original data is empty sideBar")
            return
        }
        // 只有当addList和deleteList都为空的时候（顺序改变或者用户一直不点更新确认）才走下面的逻辑，否则直接跳过走增加或者删除了哪些应用的逻辑
        if addList.isEmpty && deleteList.isEmpty {
            // 检查是否需要忽略本次更新提示：新增和删除的内容和上次一样（没有变化）那就直接返回
            if self.checkNeedIgnoreUpdate(newNaviInfo: newNaviInfo, isSideBar: true) {
                return
            }
            // 没有新增或者删除，那就要比较顺序有没有发生变化
            if let orderNotice = self.diffOrderNotice(newNaviInfo: newNaviInfo, isSideBar: true) {
                // order has changed, triger notice signal
                self.sideTabBarUpdateShowTipSubject.onNext(orderNotice)
                return
            }
        }
        lock.lock()
        defer {
            lock.unlock()
        }
        // 1. merge add list & delete list
        self.mergeUpdateData(addList: addList, deleteList: deleteList, isSideBar: true)
        // 2. convert ids of add-list to names of add-list
        // 新添加以获取最新的数据为准
        let edge = newNaviInfo.edge
        let addNames = self.transformAppIdToNames(ids: self.sidebarAddList, appInfos: edge)
        Self.logger.info("<NAVIGATION_BAR> server add keys = \(self.sidebarAddList), names = \(addNames) sideBar")
        // 3. convert ids of delete-list to names of delete-list
        // 删除的以当前显示的数据为准
        let currentEdge = originalAllTabsinfo?.edge
        let deleteNames = self.transformAppIdToNames(ids: self.sidebarDeleteList, appInfos: currentEdge)
        Self.logger.info("<NAVIGATION_BAR> server delete keys = \(self.sidebarDeleteList), names = \(deleteNames) sideBar")
        // 4. diff the other of apps change, such as fg or authorization chage
        self.diffAuthChangeApplist(newNaviInfo: newNaviInfo, tabbarStyle: .edge)
        let authChangeDeleteNames = self.transformAppIdToNames(ids: self.authChangeDeleteList, appInfos: currentEdge)
        Self.logger.info("<NAVIGATION_BAR> auth change delete keys = \(self.authChangeDeleteList), names = \(authChangeDeleteNames) sideBar")
        let authChangeAddNames = self.transformAppIdToNames(ids: self.authChangeAddList, appInfos: edge)
        Self.logger.info("<NAVIGATION_BAR> auth change add keys = \(self.authChangeAddList), names = \(authChangeAddNames) sideBar")
        // 5. publish the signal to update UI
        guard (!addNames.isEmpty ||
               !deleteNames.isEmpty ||
               !authChangeAddNames.isEmpty ||
               !authChangeDeleteNames.isEmpty)
        else {
            // trigger empty string signal to remove current notice view
            self.sideTabBarUpdateShowTipSubject.onNext("")
            Self.logger.info("<NAVIGATION_BAR> has no update notice sideBar")
            return
        }
        let notice = self.formatTips(addNames: addNames,
                                     deleteNames: deleteNames,
                                     authChangeAddNames: authChangeAddNames,
                                     authChangeDeleteNames: authChangeDeleteNames)
        self.sideTabBarUpdateShowTipSubject.onNext(notice)
    }

    // CRMode数据统一GA后删除
    private func mergeUpdateData(addList: Array<String>, deleteList: Array<String>, isSideBar: Bool) {
        Self.logger.info("<NAVIGATION_BAR> remote add list: \(addList), delete list: \(deleteList)")
        // 以服务端push的数据为准，因为现在需要区分底部栏和侧边栏的，不能使用同一份缓存进行数据merge，会串数据的
        if isSideBar {
            self.sidebarAddList = addList
            self.sidebarDeleteList = deleteList
        } else {
            self.bottomAddList = addList
            self.bottomDeleteList = deleteList
        }
    }

    // CRMode数据统一GA后删除
    private func diffAuthChangeApplist(newNaviInfo: AllNavigationInfoResponse, tabbarStyle: TabbarStyle) {
        // 新数据、与当前展示数据做diff，且不在diff list里的属于权限问题少的
        var allNewIdSets: Set<String> = []
        var currentIdSets: Set<String> = []
        if tabbarStyle == .bottom {
            newNaviInfo.bottom.response.appInfo.forEach({ appInfo in
                allNewIdSets.insert(appInfo.uniqueID)
            })
            originalAllTabsinfo?.bottom.response.appInfo.forEach({ appInfo in
                currentIdSets.insert(appInfo.uniqueID)
            })
        } else if tabbarStyle == .edge {
            newNaviInfo.edge.response.appInfo.forEach({ appInfo in
                allNewIdSets.insert(appInfo.uniqueID)
            })
            originalAllTabsinfo?.edge.response.appInfo.forEach({ appInfo in
                currentIdSets.insert(appInfo.uniqueID)
            })
        }
        var deleteListSet = Set(self.bottomDeleteList.map({ $0 }))
        var addListSet = Set(self.bottomAddList.map({ $0 }))
        if tabbarStyle == .edge {
            deleteListSet = Set(self.sidebarDeleteList.map({ $0 }))
            addListSet = Set(self.sidebarAddList.map({ $0 }))
        }
        let diffDeleteList = currentIdSets.subtracting(allNewIdSets).subtracting(deleteListSet)
        let diffAddList = allNewIdSets.subtracting(currentIdSets).subtracting(addListSet)
        self.authChangeDeleteList = Array(diffDeleteList)
        self.authChangeAddList = Array(diffAddList)
        Self.logger.info("<NAVIGATION_BAR> auth change add list: \(self.authChangeAddList), delete list: \(self.authChangeDeleteList)")
    }

    private func transformAppIdToNames(ids: Array<String>, appInfos: NavigationInfoResponse?) -> [String] {
        guard !ids.isEmpty else { return [] }
        guard let appInfos = appInfos?.response.appInfo, !appInfos.isEmpty else { return [] }
        var appNames: [String] = []
        ids.forEach { id in
            for appInfo in appInfos {
                if appInfo.uniqueID == id {
                    let meta = appInfo.tabMeta
                    if let tabType = AppType(rawValue: meta.appType),
                       isSupportTab(meta: meta),
                       featureGatingEnable(key: meta.key, appType: tabType),
                       let name = getTabName(meta: meta) {
                        appNames.append(name)
                    }
                    break
                }
            }
        }
        return appNames
    }

    private func getTabName(meta: TabMeta) -> String? {
        if meta.appType == AppType.native.rawValue {
            if meta.key == Tab.moment.key,
               let momentName = meta.currentName,
               !momentName.isEmpty {
                /// 公司圈比较特殊，有配置服务端取服务端配置的
                return momentName
            } else if let name = TabConfig.defaultConfig(for: meta.key, of: .native).name,
                !name.isEmpty {
                /// 除公司圈外的native应用
                 return name
            }
        } else if let name = meta.currentName, !name.isEmpty {
            // 本地一方应用没有，找meta里面的 譬如：小程序
            return name
        }
        return nil
    }

    private func formatTips(addNames: [String],
                  deleteNames: [String],
                  authChangeAddNames: [String],
                  authChangeDeleteNames: [String]) -> String {
        let notice = self.formatManagerUpdateTip(addNames: addNames, deleteNames: deleteNames)
        let authNotice = self.formatAuthChangeTip(authChangeAddNames: authChangeAddNames, authChangeDelNames: authChangeDeleteNames)
        var result = ""
        if !notice.isEmpty {
            result += notice
        }
        if !result.isEmpty && !authNotice.isEmpty {
            result += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_Separator_ForMobile
        }
        if !authNotice.isEmpty {
            result += authNotice
        }
        return result
    }

    private func formatManagerUpdateTip(addNames: [String], deleteNames: [String]) -> String {
        guard (!addNames.isEmpty || !deleteNames.isEmpty) else { return "" }
        let limitCount = 3
        var notice: String = ""
        var subAddNames: [String] = []
        var subDelNames: [String] = []
        if addNames.count > limitCount {
            subAddNames = Array(addNames.prefix(upTo: limitCount))
        }
        if deleteNames.count > limitCount {
            subDelNames = Array(deleteNames.prefix(upTo: limitCount))
        }
        let coma = BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdates_SeparateApps_Coma
        let joinAddNames = subAddNames.joined(separator: coma)
        let joinDelNames = subDelNames.joined(separator: coma)

        if addNames.count > limitCount {
            notice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_AddedNumAppsMoreThan3_Text(
                wrapperNumsTxt(addNames.count),
                joinAddNames
            )
        } else if !addNames.isEmpty {
            notice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_AddedNumAppsLessThan3_New(
                wrapperNumsTxt(addNames.count),
                addNames.joined(separator: coma)
            )
        }

        if !notice.isEmpty && !deleteNames.isEmpty {
            notice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_Separator_ForMobile
        }

        if deleteNames.count > limitCount {
            notice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_RemovedNumAppsMoreThan3_Text(
                wrapperNumsTxt(deleteNames.count),
                joinDelNames
            )
        } else if !deleteNames.isEmpty {
            notice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_RemovedNumAppsLessThan3_New(
                wrapperNumsTxt(deleteNames.count),
                deleteNames.joined(separator: coma)
            )
        }
        return notice
    }

    private func formatAuthChangeTip(authChangeAddNames: [String], authChangeDelNames: [String]) -> String {
        guard (!authChangeAddNames.isEmpty || !authChangeDelNames.isEmpty) else { return "" }
        // 权限变更文案拼接
        let limitCount = 3
        var authNotice = ""
        var subAuthAddNames: [String] = []
        var subAuthDelNames: [String] = []
        let coma = BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdates_SeparateApps_Coma
        if authChangeAddNames.count > limitCount {
            subAuthAddNames = Array(authChangeAddNames.prefix(upTo: limitCount))
        }
        if authChangeDelNames.count > limitCount {
            subAuthDelNames = Array(authChangeDelNames.prefix(upTo: limitCount))
        }

        let joinAddNames = subAuthAddNames.joined(separator: coma)
        let joinDelNames = subAuthDelNames.joined(separator: coma)

        if authChangeAddNames.count > limitCount {
            authNotice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_PermissionChanged_AddedNumAppsMoreThan3_Text(
                wrapperNumsTxt(authChangeAddNames.count),
                joinAddNames
            )
        } else if !authChangeAddNames.isEmpty {
            authNotice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_PermissionChanged_AddedNumAppsLessThan3_New(
                wrapperNumsTxt(authChangeAddNames.count),
                authChangeAddNames.joined(separator: coma)
            )
        }

        if !authNotice.isEmpty && !authChangeDelNames.isEmpty {
            authNotice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_Separator_ForMobile
        }

        if authChangeDelNames.count > limitCount {
            authNotice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_PermissionChanged_RemovedNumAppsMoreThan3_Text(
                wrapperNumsTxt(authChangeDelNames.count),
                joinDelNames
            )
        } else if !authChangeDelNames.isEmpty {
            authNotice += BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_PermissionChanged_RemovedNumAppsLessThan3_New(
                wrapperNumsTxt(authChangeDelNames.count),
                authChangeDelNames.joined(separator: coma)
            )
        }
        return authNotice
    }

    private func wrapperNumsTxt(_ count: Int) -> String {
        return BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_AddedOrRemoved_ICU(count)
    }

    func resetLocalData() {
        lock.lock()
        defer {
            lock.unlock()
        }
        self.bottomAddList.removeAll()
        self.bottomDeleteList.removeAll()
        self.sidebarAddList.removeAll()
        self.sidebarDeleteList.removeAll()
        self.iPhoneAddList.removeAll()
        self.iPhoneDeleteList.removeAll()
        self.iPadAddList.removeAll()
        self.iPadDeleteList.removeAll()
        self.authChangeAddList.removeAll()
        self.authChangeDeleteList.removeAll()
    }

    /// 比较 UI 显示导航顺序和服务端新推送数据上是否一致，不一致提示更新提示：区分iPhone和iPad（数据源是隔离的）
    private func diffOrderNotice(newNaviInfo: AllNavigationInfoResponse) -> String? {
        guard let originalNavigationInfo = originalAllTabsinfo else {
            return nil
        }
        var oldTabs: [Basic_V1_NavigationAppInfo] = []
        if Display.pad {
            oldTabs = originalNavigationInfo.iPad.main + originalNavigationInfo.iPad.quick
        } else {
            oldTabs = originalNavigationInfo.iPhone.main + originalNavigationInfo.iPhone.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterOldTabs = oldTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        var newTabs: [Basic_V1_NavigationAppInfo] = []
        if Display.pad {
            newTabs = newNaviInfo.iPad.main + newNaviInfo.iPad.quick
        } else {
            newTabs = newNaviInfo.iPhone.main + newNaviInfo.iPhone.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterNewTabs = newTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        // 过滤不支持的应用以后再比较，否则比较的结果不准，提了好几个相关的bug
        let oldTabUniqueIds = filterOldTabs.map({ $0.uniqueID })
        let newTabUniqueIds = filterNewTabs.map({ $0.uniqueID })
        NavigationConfigService.logger.debug("<NAVIGATION_BAR> old: \(oldTabUniqueIds) new: \(newTabUniqueIds) isIPad: \(Display.pad)")
        if Set(oldTabUniqueIds) != Set(newTabUniqueIds) {
            // 如果新旧两个集合已经不一样了，说明不单单是顺序，里面的内容都发生变化了（增删都有可能）
            NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi tabs changed isIPad: \(Display.pad)")
            // 需要进一步计算出新增了哪些应用
            let addUniqueIds = Set(newTabUniqueIds).subtracting(Set(oldTabUniqueIds))
            // 需要进一步计算出删除了哪些应用
            let deleteUniqueIds = Set(oldTabUniqueIds).subtracting(Set(newTabUniqueIds))
            if !addUniqueIds.isEmpty || !deleteUniqueIds.isEmpty {
                NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi tabs changed, addUnidueIds = \(addUniqueIds), deleteUnidueIds = \(deleteUniqueIds) isIPad: \(Display.pad)")
                // 提示有新增或者删除应用
                return self.getFormatTips(newNaviInfo: newNaviInfo, addList: Array(addUniqueIds), deleteList: Array(deleteUniqueIds))
            }
            NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi tabs changed, show tips NavigationUpdate isIPad: \(Display.pad)")
            // 提示导航栏更新了
            return BundleI18n.LarkNavigation.Lark_Legacy_NavigationUpdateTitle
        }
        // 走到这边表示集合里的id是完全一致的，所以接下来还要比较顺序是否发生变化
        if oldTabUniqueIds == newTabUniqueIds {
            NavigationConfigService.logger.debug("<NAVIGATION_BAR> all tab is same begin to compare order isIPad: \(Display.pad)")
            /// 顺序也完全一样，但是main tabs 和 quick tabs 不一样，比较其中一个就行
            var originalCompareTabs: [Basic_V1_NavigationAppInfo] = []
            var newCompareTabs: [Basic_V1_NavigationAppInfo] = []
            if Display.pad {
                originalCompareTabs = originalNavigationInfo.iPad.main
                newCompareTabs = newNaviInfo.iPad.main
            } else {
                originalCompareTabs = originalNavigationInfo.iPhone.main
                newCompareTabs = newNaviInfo.iPhone.main
            }
            if (originalCompareTabs.count == newCompareTabs.count) {
                NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi order is same isIPad: \(Display.pad)")
                return nil
            }
        }
        NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi order changed, show tips AdminChangedOrder isIPad: \(Display.pad)")
        return BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_AdminChangedDisplayOrder_Text
    }

    /// 比较 UI 显示导航顺序和服务端新推送数据上是否一致，不一致提示更新提示：区分底部栏和侧边栏（数据源是隔离的）（CRMode数据统一GA后删除）
    private func diffOrderNotice(newNaviInfo: AllNavigationInfoResponse, isSideBar: Bool = false) -> String? {
        guard let originalNavigationInfo = originalAllTabsinfo else {
            return nil
        }
        var oldTabs: [Basic_V1_NavigationAppInfo] = []
        if isSideBar {
            oldTabs = originalNavigationInfo.edge.main + originalNavigationInfo.edge.quick
        } else {
            oldTabs = originalNavigationInfo.bottom.main + originalNavigationInfo.bottom.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterOldTabs = oldTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        var newTabs: [Basic_V1_NavigationAppInfo] = []
        if isSideBar {
            newTabs = newNaviInfo.edge.main + newNaviInfo.edge.quick
        } else {
            newTabs = newNaviInfo.bottom.main + newNaviInfo.bottom.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterNewTabs = newTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        // 过滤不支持的应用以后再比较，否则比较的结果不准，提了好几个相关的bug
        let oldTabUniqueIds = filterOldTabs.map({ $0.uniqueID })
        let newTabUniqueIds = filterNewTabs.map({ $0.uniqueID })
        NavigationConfigService.logger.debug("<NAVIGATION_BAR> old: \(oldTabUniqueIds) new: \(newTabUniqueIds) isSideBar: \(isSideBar)")
        if Set(oldTabUniqueIds) != Set(newTabUniqueIds) {
            // 如果新旧两个集合已经不一样了，说明不单单是顺序，里面的内容都发生变化了（增删都有可能）
            NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi tabs changed isSideBar: \(isSideBar)")
            // 需要进一步计算出新增了哪些应用
            let addUniqueIds = Set(newTabUniqueIds).subtracting(Set(oldTabUniqueIds))
            // 需要进一步计算出删除了哪些应用
            let deleteUniqueIds = Set(oldTabUniqueIds).subtracting(Set(newTabUniqueIds))
            if !addUniqueIds.isEmpty || !deleteUniqueIds.isEmpty {
                NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi tabs changed, addUnidueIds = \(addUniqueIds), deleteUnidueIds = \(deleteUniqueIds) isSideBar: \(isSideBar)")
                // 提示有新增或者删除应用
                return self.getFormatTips(newNaviInfo: newNaviInfo, isSideBar: isSideBar, addList: Array(addUniqueIds), deleteList: Array(deleteUniqueIds))
            }
            NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi tabs changed, show tips NavigationUpdate isSideBar: \(isSideBar)")
            // 提示导航栏更新了
            return BundleI18n.LarkNavigation.Lark_Legacy_NavigationUpdateTitle
        }
        // 走到这边表示集合里的id是完全一致的，所以接下来还要比较顺序是否发生变化
        if oldTabUniqueIds == newTabUniqueIds {
            NavigationConfigService.logger.debug("<NAVIGATION_BAR> all tab is same begin to compare order isSideBar: \(isSideBar)")
            /// 顺序也完全一样，但是main tabs 和 quick tabs 不一样，比较其中一个就行
            var originalCompareTabs: [Basic_V1_NavigationAppInfo] = []
            var newCompareTabs: [Basic_V1_NavigationAppInfo] = []
            if isSideBar {
                originalCompareTabs = originalNavigationInfo.edge.main
                newCompareTabs = newNaviInfo.edge.main
            } else {
                originalCompareTabs = originalNavigationInfo.bottom.main
                newCompareTabs = newNaviInfo.bottom.main
            }
            if (originalCompareTabs.count == newCompareTabs.count) {
                NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi order is same isSideBar: \(isSideBar)")
                return nil
            }
        }
        NavigationConfigService.logger.debug("<NAVIGATION_BAR> navi order changed, show tips AdminChangedOrder isSideBar: \(isSideBar)")
        return BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_AdminChangedDisplayOrder_Text
    }

    /// 获取增加和删除应用的提示信息：区分iPhone和iPad（数据源是隔离的）
    private func getFormatTips(newNaviInfo: AllNavigationInfoResponse, addList: [String], deleteList: [String]) -> String {
        let newAppInfos: NavigationInfoResponse
        if Display.pad {
            newAppInfos = newNaviInfo.iPad
        } else {
            newAppInfos = newNaviInfo.iPhone
        }
        let addNames = self.transformAppIdToNames(ids: addList, appInfos: newAppInfos)
        Self.logger.info("<NAVIGATION_BAR> add names: \(addNames), isIPad: \(Display.pad)")
        // 删除的以当前显示的数据为准
        let oldAppInfos: NavigationInfoResponse?
        if Display.pad {
            oldAppInfos = originalAllTabsinfo?.iPad
        } else {
            oldAppInfos = originalAllTabsinfo?.iPhone
        }
        let deleteNames = self.transformAppIdToNames(ids: deleteList, appInfos: oldAppInfos)
        Self.logger.info("<NAVIGATION_BAR> delete names: \(deleteNames), isIPad: \(Display.pad)")
        let notice = self.formatTips(addNames: addNames,
                                     deleteNames: deleteNames,
                                     authChangeAddNames: [],
                                     authChangeDeleteNames: [])
        return notice
    }

    /// 获取增加和删除应用的提示信息：区分底部栏和侧边栏（数据源是隔离的）（CRMode数据统一GA后删除）
    private func getFormatTips(newNaviInfo: AllNavigationInfoResponse, isSideBar: Bool, addList: [String], deleteList: [String]) -> String {
        let naviInfo: NavigationInfoResponse
        if isSideBar {
            naviInfo = newNaviInfo.edge
        } else {
            naviInfo = newNaviInfo.bottom
        }
        let addNames = self.transformAppIdToNames(ids: addList, appInfos: naviInfo)
        Self.logger.info("<NAVIGATION_BAR> add names count: \(addNames.count)")
        // 删除的以当前显示的数据为准
        let currentNaviInfo: NavigationInfoResponse?
        if isSideBar {
            currentNaviInfo = originalAllTabsinfo?.edge
        } else {
            currentNaviInfo = originalAllTabsinfo?.bottom
        }
        let deleteNames = self.transformAppIdToNames(ids: deleteList, appInfos: currentNaviInfo)
        Self.logger.info("<NAVIGATION_BAR> delete names count: \(deleteNames.count)")
        let notice = self.formatTips(addNames: addNames,
                                     deleteNames: deleteNames,
                                     authChangeAddNames: [],
                                     authChangeDeleteNames: [])
        return notice
    }

    /// 检查是否需要忽略本次更新提示：区分iPhone和iPad（数据源是隔离的）
    private func checkNeedIgnoreUpdate(newNaviInfo: AllNavigationInfoResponse) -> Bool {
        guard let originalNavigationInfo = originalAllTabsinfo else {
            return false
        }
        let oldTabs: [Basic_V1_NavigationAppInfo]
        if Display.pad {
            oldTabs = originalNavigationInfo.iPad.main + originalNavigationInfo.iPad.quick
        } else {
            oldTabs = originalNavigationInfo.iPhone.main + originalNavigationInfo.iPhone.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterOldTabs = oldTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        let newTabs: [Basic_V1_NavigationAppInfo]
        if Display.pad {
            newTabs = newNaviInfo.iPad.main + newNaviInfo.iPad.quick
        } else {
            newTabs = newNaviInfo.iPhone.main + newNaviInfo.iPhone.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterNewTabs = newTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        // 过滤不支持的应用以后再比较，否则比较的结果不准，提了好几个相关的bug
        let oldTabUniqueIds = filterOldTabs.map({ $0.uniqueID })
        let newTabUniqueIds = filterNewTabs.map({ $0.uniqueID })
        if Set(oldTabUniqueIds) != Set(newTabUniqueIds) {
            // 需要进一步计算出新增了哪些应用
            let addUniqueIds = Set(newTabUniqueIds).subtracting(Set(oldTabUniqueIds))
            // 需要进一步计算出删除了哪些应用
            let deleteUniqueIds = Set(oldTabUniqueIds).subtracting(Set(newTabUniqueIds))
            var addList = self.iPhoneAddList
            var deleteList = self.iPhoneDeleteList
            if Display.pad {
                addList = self.iPadAddList
                deleteList = self.iPadDeleteList
            }
            if Set(addUniqueIds) == Set(addList) && Set(deleteUniqueIds) == Set(deleteList) {
                // 如果新增和删除的内容和上次一样（没有变化）那就不要再出更新提示了
                return true
            }
        }
        return false
    }
    
    /// 检查是否需要忽略本次更新提示：区分底部栏和侧边栏（数据源是隔离的）（CRMode数据统一GA后删除）
    private func checkNeedIgnoreUpdate(newNaviInfo: AllNavigationInfoResponse, isSideBar: Bool) -> Bool {
        guard let originalNavigationInfo = originalAllTabsinfo else {
            return false
        }
        let oldTabs: [Basic_V1_NavigationAppInfo]
        if isSideBar {
            oldTabs = originalNavigationInfo.edge.main + originalNavigationInfo.edge.quick
        } else {
            oldTabs = originalNavigationInfo.bottom.main + originalNavigationInfo.bottom.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterOldTabs = oldTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        let newTabs: [Basic_V1_NavigationAppInfo]
        if isSideBar {
            newTabs = newNaviInfo.edge.main + newNaviInfo.edge.quick
        } else {
            newTabs = newNaviInfo.bottom.main + newNaviInfo.bottom.quick
        }
        // 目前不支持租户配置的原生应用，所以需要过滤，服务端可能会下发这种类型的应用（测试会配置啊！！！！）
        let filterNewTabs = newTabs.filter({ isSupportTab(meta: $0.tabMeta) })
        // 过滤不支持的应用以后再比较，否则比较的结果不准，提了好几个相关的bug
        let oldTabUniqueIds = filterOldTabs.map({ $0.uniqueID })
        let newTabUniqueIds = filterNewTabs.map({ $0.uniqueID })
        if Set(oldTabUniqueIds) != Set(newTabUniqueIds) {
            // 需要进一步计算出新增了哪些应用
            let addUniqueIds = Set(newTabUniqueIds).subtracting(Set(oldTabUniqueIds))
            // 需要进一步计算出删除了哪些应用
            let deleteUniqueIds = Set(oldTabUniqueIds).subtracting(Set(newTabUniqueIds))
            var addList = self.bottomAddList
            var deleteList = self.bottomDeleteList
            if isSideBar {
                addList = self.sidebarAddList
                deleteList = self.sidebarDeleteList
            }
            if Set(addUniqueIds) == Set(addList) && Set(deleteUniqueIds) == Set(deleteList) {
                // 如果新增和删除的内容和上次一样（没有变化）那就不要再出更新提示了
                return true
            }
        }
        return false
    }
}

// MARK: Data
extension NavigationConfigService {

    func getNavigationInfoByLocal() -> AllNavigationInfoResponse? {
        let key = KVKeys.Navigation.navigationInfo
        // 尝试获取v3缓存
        guard let infoValue = userStore[key] else {
            Self.logger.error("<NAVIGATION_BAR> fetch local navigation failed, key = \(key.raw)")
            // 没有获取到v3缓存，尝试获取旧的v2缓存，并转换成v3
            guard let v3InfoFromV2 = getTransformedV3InfoFromV2ByLocal() else {
                return nil
            }
            // 获取到v2缓存并且已经成功转换到v3
            return Self.transformToNativeInfo(pbInfo: v3InfoFromV2)
        }

        var info = try? NavigationAppInfoBatchResponse(jsonString: infoValue)
        if (info == nil) {
            Self.logger.info("<NAVIGATION_BAR> app_type did change")
            /// 7.0 版本 app_type 枚举值做了不兼容修改，所以这里解析可能会失败，如果是这个情况，先对json里app_type做次校准后，重新初始化
            guard let transformValue = Self.transformJsonAppType(jsonString: infoValue) else {
                Self.logger.error("<NAVIGATION_BAR> transformJsonAppType failed")
                return nil
            }
            info = try? NavigationAppInfoBatchResponse(jsonString: transformValue)
        }

        guard let result = info else {
            Self.logger.error("<NAVIGATION_BAR> convert jsonString to AllNavigationInfoResponse failed")
            return nil
        }
        return Self.transformToNativeInfo(pbInfo: result)
    }

    static func transformToNativeInfo(pbInfo: NavigationAppInfoBatchResponse) -> AllNavigationInfoResponse {
        var pbInfo = pbInfo
        // iPad 上兼容没有 edge 的 V3 数据，从老数据进行补位
        if Display.pad, pbInfo.responses.count == 1,
           let iPhone = pbInfo.responses.first,
           iPhone.platform == .navMobile {
            var iPad = iPhone
            iPad.platform = .navIpad
            iPad.primaryCount = iPhone.totalCount
            pbInfo.responses = [iPhone, iPad]
        }
        let result = AllNavigationInfoResponse(response: pbInfo)
        Self.logger.info("<NAVIGATION_BAR> did load local navigation info")
        return result
    }

    static func transformJsonAppType(jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        var jsonData = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, Any>
        var responses = jsonData?["responses"] as? [Dictionary<String, Any>]
        for r in 0..<(responses?.count ?? 0) {
            var response = responses?[r] as? Dictionary<String, Any>
            var appInfos = response?["appInfo"] as? [Dictionary<String, Any>]
            for i in 0..<(appInfos?.count ?? 0) {
                var item = appInfos?[i] as? Dictionary<String, Any>
                if let appType = item?["appType"] as? String {
                    item?["appType"] = Self.transformAppTypeToNewAppType(appType)
                    if let item = item {
                        appInfos?[i] = item
                    }
                }
            }
            if let appInfos = appInfos {
                response?["appInfo"] = appInfos
            }
            if let response = response {
                responses?[r] = response
            }
        }
        if let responses = responses {
            jsonData?["responses"] = responses
        }
        guard let jsonObject = jsonData, let data = try? JSONSerialization.data(withJSONObject: jsonObject , options:.prettyPrinted) else {
            return nil
        }
        return String(data: data, encoding:.utf8)
    }

    static func transformAppTypeToNewAppType(_ appType: String) -> String {
        switch appType {
        case "APP_TYPE_NATIVE":
            return "APP_TYPE_LARK_NATIVE"
        default:
            return appType
        }
    }

    // Fast Login: 异步拉取Navi Info
    func observeNavigationInfo() {
        // 启动优化：导航数据拉取延后
        RunloopDispatcher.shared.addTask(priority: .high, identify: "GetNavigationAppInfo") { [weak self] in
            guard let self = self else { return }
            guard let navigationAPI = self.navigationAPI else { return }
            // 跟server端已沟通好，目前采用全量拉取，二期待优化
            navigationAPI.getNavigationInfo(firstPage: nil, fullData: true)
                .subscribe(onNext: { [weak self] res in
                    guard let self = self else { return }
                    NavigationConfigService.logger.info("<NAVIGATION_BAR> Fast Login: get navigation success begin save to UD")
                    self.saveToUD(response: res)
                    let crmodeDisable = self.crmodeUnifiedDataDisable
                    if !crmodeDisable {
                        let addList = Display.pad ? res.iPad.addList : res.iPhone.addList
                        let deleteList = Display.pad ? res.iPad.deleteList : res.iPhone.deleteList
                        self.handleTabBarUpdate(addList: addList, deleteList: deleteList, newNaviInfo: res)
                    } else {
                        let bottomAddList = res.bottom.addList
                        let bottomDeleteList = res.bottom.deleteList
                        // 移动端和iPad设备C模式
                        self.handleBottomTabBarUpdate(addList: bottomAddList, deleteList: bottomDeleteList, newNaviInfo: res)
                        if Display.pad {
                            // iPad设备R模式
                            let sidebarAddList = res.edge.addList
                            let sidebarDeleteList = res.edge.deleteList
                            self.handleSideBarUpdate(addList: sidebarAddList, deleteList: sidebarDeleteList, newNaviInfo: res)
                        }
                    }
                }).disposed(by: self.disposeBag)
        }

        pushCenter.observable(for: NavigationInfoResponse.self)
            .observeOn(self.scheduler)
            .flatMap({ [weak self] (push) -> Observable<(NavigationInfoResponse, AllNavigationInfoResponse)> in
                guard let self = self else { return .empty() }
                /// iPad 会有多次push，使用异步保存会导致数据不同步，这里使用SerialQueue，保证数据串行保存完成
                guard let naviInfo = self.parseSingleResponse(push) else { return .empty() }
                NavigationConfigService.logger.info("<NAVIGATION_BAR> receive navigation push begin save to UD")
                self.saveToUD(response: naviInfo)
                return .just((push, naviInfo))
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push, naviInfo) in
                guard let self = self else { return }
                let crmodeDisable = self.crmodeUnifiedDataDisable
                if !crmodeDisable {
                    let addList = push.addList
                    let deleteList = push.deleteList
                    // C、R模式数据源统一后指定设备的推送只给指定设备推
                    if push.platform == .navIpad && Display.pad {
                        // 如果是iPad推送并且当前是iPad设备的话
                        self.handleTabBarUpdate(addList: addList, deleteList: deleteList, newNaviInfo: naviInfo)
                    } else if push.platform == .navMobile && Display.phone {
                        // 如果是Mobile推送并且当前是iPhone设备的话
                        self.handleTabBarUpdate(addList: addList, deleteList: deleteList, newNaviInfo: naviInfo)
                    }
                } else {
                    let isPad = UIDevice.current.userInterfaceIdiom == .pad
                    let addList = push.addList
                    let deleteList = push.deleteList
                    if push.platform == .navIpad && isPad {
                        // 如果是iPad推送并且当前是iPad设备的话需要更新侧边栏
                        self.handleSideBarUpdate(addList: addList, deleteList: deleteList, newNaviInfo: naviInfo)
                    } else if push.platform == .navMobile {
                        // 如果是Mobile推送的话需要更新底部栏（iPad设备需要更新C视图）
                        self.handleBottomTabBarUpdate(addList: addList, deleteList: deleteList, newNaviInfo: naviInfo)
                    }
                }
            }).disposed(by: disposeBag)
    }

    // 登陆/切租户(本地无缓存时): 阻塞拉取Navi Info
    func fetchNavigationInfo() -> Observable<Void> {
        guard originalAllTabsinfo == nil else {
            NavigationConfigService.logger.debug("<NAVIGATION_BAR> load remote navigation config canceled.")
            return .just(())
        }
        guard let navigationAPI = self.navigationAPI else { return .empty() }
        return navigationAPI.getNavigationInfo(firstPage: nil, fullData: true)
            .flatMap({ [weak self] info -> Observable<Void> in
                guard let self = self else {
                    Self.logger.debug("<NAVIGATION_BAR> received navigation info nil.")
                    return .just(())
                }
                self.originalAllTabsinfo = info
                NavigationConfigService.logger.info("<NAVIGATION_BAR> fetch navigation success begin save to UD")
                self.saveToUD(response: info)
                return .just(())
            }).observeOn(MainScheduler.instance)
    }
    
    private func parseSingleResponse(_ singleResponse: NavigationInfoResponse) -> AllNavigationInfoResponse? {
        // 为了逻辑清晰CRMode数据统一GA前完全区分开来，GA后把重复代码删除即可，这样保证不会出错，强行要精简逻辑只会出问题!!!!
        let crmodeDisable = self.crmodeUnifiedDataDisable
        if !crmodeDisable {
            let types: [Settings_V1_NavigationPlatform] = Display.pad ? [.navIpad] : [.navMobile]
            guard types.contains(singleResponse.platform) else { return nil }
            var batchResponse: NavigationAppInfoBatchResponse
            if let response = self.getNavigationInfoByLocal()?.response {
                batchResponse = response
            } else {
                batchResponse = NavigationAppInfoBatchResponse()
            }
            var map = [Settings_V1_NavigationPlatform: NavigationAppInfoResponse]()
            batchResponse.responses.forEach({ map[$0.platform] = $0 })
            var iPhone = map[.navMobile] ?? NavigationAppInfoResponse()
            if singleResponse.response.platform == .navMobile {
                iPhone = singleResponse.response
            }
            var array: [NavigationAppInfoResponse] = [iPhone]
            if Display.pad {
                var iPad = map[.navIpad] ?? NavigationAppInfoResponse()
                if singleResponse.response.platform == .navIpad {
                    iPad = singleResponse.response
                }
                array.append(iPad)
            }
            batchResponse.responses = array
            return AllNavigationInfoResponse(response: batchResponse)
        } else {
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let types: [Settings_V1_NavigationPlatform] = isPad ? [.navMobile, .navIpad] : [.navMobile]
            guard types.contains(singleResponse.platform) else { return nil }
            var batchResponse: NavigationAppInfoBatchResponse
            if let response = self.getNavigationInfoByLocal()?.response {
                batchResponse = response
            } else {
                batchResponse = NavigationAppInfoBatchResponse()
            }
            var map = [Settings_V1_NavigationPlatform: NavigationAppInfoResponse]()
            batchResponse.responses.forEach({ map[$0.platform] = $0 })
            var bottom = map[.navMobile] ?? NavigationAppInfoResponse()
            if singleResponse.response.platform == .navMobile {
                bottom = singleResponse.response
            }
            var array: [NavigationAppInfoResponse] = [bottom]
            if isPad {
                var edge = map[.navIpad] ?? NavigationAppInfoResponse()
                if singleResponse.response.platform == .navIpad {
                    edge = singleResponse.response
                }
                array.append(edge)
            }
            batchResponse.responses = array
            return AllNavigationInfoResponse(response: batchResponse)
        }
    }

    func saveToUD(response: AllNavigationInfoResponse) {
        let key = KVKeys.Navigation.navigationInfo
        NavigationConfigService.logger.debug("<NAVIGATION_BAR> save navigation info to UD, key = \(key.raw)")
        guard let configValue = try? response.response.jsonString() else {
            NavigationConfigService.logger.error("<NAVIGATION_BAR> generate navigtion jsonString failed.")
            return
        }
        NavigationConfigService.logger.info("<NAVIGATION_BAR> saveToUD success")
        self.userStore[key] = configValue
        let resp: NavigationInfoResponse
        let crmodeDisable = self.crmodeUnifiedDataDisable
        if !crmodeDisable {
            resp = response.iPhone
        } else {
            resp = response.bottom
        }
        if let appInfo = resp.main.first,
           appInfo.appType.transformToNativeApptype() == .native,
           let firstTab = Tab.allTabs.first(where: { $0.key == appInfo.key }) {
            self.userStore[KVKeys.Navigation.firstTab] = firstTab.urlString
        } else {
            self.userStore.removeValue(forKey: KVKeys.Navigation.firstTab)
        }
        self.dataChangeSubject.onNext(())
    }
}

// MARK: 兼容v2数据，以后可以删除
extension NavigationConfigService {
    // 仅用来兼容4.5版本及之前的本地缓存的v2数据，作为v2过度到v3用，以后可以删除

    // 获取旧的v2缓存，并转换成v3
    private func getTransformedV3InfoFromV2ByLocal() -> NavigationAppInfoBatchResponse? {
        let key = KVKeys.Navigation.navigationInfoV2
        guard let infoValue = userStore[key],
              let infoV2 = try? NavigationInfoV2(jsonString: infoValue) else {
            Self.logger.error("<NAVIGATION_BAR> fetch local navigationv2 failed, key = \(key.raw)")
            return nil
        }
        Self.logger.info("<NAVIGATION_BAR> did load local navigationv2 success mainNavigation: \(infoV2.mainNavigation.map({ $0.key })), shortcutNavigation: \(infoV2.shortcutNavigation.map({ $0.key })))")
        let infoV3 = AllNavigationInfoResponse.transformToV3FromV2(infoV2)
        return infoV3
    }
}
