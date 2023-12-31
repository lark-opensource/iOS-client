//
//  SpaceCreateDirector.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/27.
//

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import SKResource
import SKUIKit
import LarkUIKit
import SpaceInterface
import SKInfra
import UniverseDesignIcon
import LarkContainer

public enum SpaceHomeAction {
    case create(with: SpaceCreateIntent, sourceView: UIView?)
    case createFolder(with: SpaceCreateIntent)
    case push(viewController: UIViewController)
    case showHUD(_ action: SpaceSectionAction.HUDAction)
    case present(viewController: UIViewController, popoverConfiguration: ((UIViewController) -> Void)?)
    case sectionAction(_ action: SpaceSection.Action)
}

public protocol SpaceHomeViewModel {
    typealias Intent = SpaceCreateIntent
    typealias Action = SpaceHomeAction
    typealias CreateFromSource = (FromSource, CreateButtonLocation, UIView)
    var userResolver: UserResolver { get }
    var createVisableDriver: Driver<Bool> { get }
    var createEnableDriver: Driver<Bool> { get }
    var createIntentionTrigger: PublishRelay<CreateFromSource> { get }
    // 是否响应禁用态的创建按钮点击事件
    var disabledCreateTrigger: PublishRelay<Void>? { get }
    var actionSignal: Signal<Action> { get }
    var tabBadgeVisableChanged: Observable<Bool> { get }
    var naviBarItemsUpdated: Driver<[SpaceNaviBarItem]> { get }
    var naviBarTitleDriver: Driver<String>? { get }
    var commonTrackParams: [String: String] { get }
    var refreshAnimatorDescrption: String { get }
    func notifyViewDidLoad()
    func notifyViewDidAppear()
}

public extension SpaceHomeViewModel {
    // 默认不响应禁用态的点击事件
    var disabledCreateTrigger: PublishRelay<Void>? { nil }

    var naviBarTitleDriver: Driver<String>? { nil }
}

public final class LarkSpaceHomeViewModel: SpaceHomeViewModel {
    
    public var naviBarItemsUpdated: Driver<[SpaceNaviBarItem]> { .never() }
    public var multiListSection: SpaceMultiListSection<SpaceMultiListHeaderView>?

    private let createVisableRelay = BehaviorRelay<Bool>(value: true)
    public var createVisableDriver: Driver<Bool> {
        if UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable {
            return .just(false)
        } else {
            return createVisableRelay.asDriver()
        }
    }

    private let createEnableRelay = BehaviorRelay<Bool>(value: true)
    public var createEnableDriver: Driver<Bool> {
        createEnableRelay.asDriver()
    }

    public let createIntentionTrigger = PublishRelay<CreateFromSource>()
    // 引导用户去云盘离线创建
    public let disabledCreateTrigger: PublishRelay<Void>? = PublishRelay<Void>()
    // 离线禁止点击的 Toast 提示
    private var disabledCreateMessage = BundleI18n.SKResource.LarkCCM_CM_MyLib_NewDoc_NA_Tooltip

    let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> { actionInput.asSignal() }

    // 用于判断是否需要展示 tab 的红点
    private let tabBadgeRelay = BehaviorRelay<Bool>(value: false)
    public var tabBadgeVisableChanged: Observable<Bool> {
        tabBadgeRelay.asObservable()
    }

    private let createContext: SpaceCreateContext
    private let badgeConfig: SpaceBadgeConfig
    private let defaultLocationProvider: WorkspaceDefaultLocationProvider.Type
    private let netMonitorType: RxNetworkMonitorType.Type
    private let disposeBag = DisposeBag()

    private let tracker = SpaceHomeTracker(bizParameter: SpaceBizParameter(module: .home(.recent)))
    public var commonTrackParams: [String: String] {
        return tracker.bizParameter.params
    }
    public var refreshAnimatorDescrption: String {
        BundleI18n.SKResource.Doc_List_RefreshDocTips
    }

    public let userResolver: UserResolver
    
    public init(userResolver: UserResolver,
                createContext: SpaceCreateContext,
                badgeConfig: SpaceBadgeConfig,
                defaultLocationProvider: WorkspaceDefaultLocationProvider.Type = WorkspaceCreateDirector.self,
                netMonitorType: RxNetworkMonitorType.Type = RxNetworkMonitor.self) {
        self.userResolver = userResolver
        self.createContext = createContext
        self.badgeConfig = badgeConfig
        self.defaultLocationProvider = defaultLocationProvider
        self.netMonitorType = netMonitorType
        setup()
    }

    private func setup() {
        setupNetworkMonitor()

        createIntentionTrigger.map { [weak self] (fromSource, location, sourceView) -> Action in
            guard let self = self else {
                return .create(with: Intent(context: .recent, source: fromSource, createButtonLocation: location),
                               sourceView: sourceView)
            }
            return .create(with: Intent(context: self.createContext, source: fromSource, createButtonLocation: location),
                           sourceView: sourceView)
        }
        .bind(to: actionInput)
        .disposed(by: disposeBag)
    }

    private func setupNetworkMonitor() {
        guard let disabledCreateTrigger else { return }
        switch createContext.mountLocation {
        case .wiki:
            return
        case .folder:
            return
        case .default:
            // default 需要延后到断网时，再根据缓存的判断决定是否要置灰
            netMonitorType.networkStatus(observerObj: self)
                .map { $1 }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isReachable in
                    guard let self else { return }
                    if isReachable {
                        self.createEnableRelay.accept(true)
                        return
                    }
                    guard let location = try? self.defaultLocationProvider.getDefaultCreateLocation() else {
                        self.createEnableRelay.accept(false)
                        self.disabledCreateMessage = BundleI18n.SKResource.Doc_Facade_CreateFailed
                        return
                    }
                    switch location {
                    case .wiki:
                        // 创建到wiki时，检查支持离线新建FG
                        self.createEnableRelay.accept(true)
                        self.disabledCreateMessage = BundleI18n.SKResource.LarkCCM_CM_MyLib_NewDoc_NA_Tooltip
                    case .folder:
                        self.createEnableRelay.accept(true)
                    case .default:
                        spaceAssertionFailure("default should not be found when get from cache")
                        self.createEnableRelay.accept(false)
                        self.disabledCreateMessage = BundleI18n.SKResource.Doc_Facade_CreateFailed
                    }
                })
                .disposed(by: disposeBag)

            disabledCreateTrigger.compactMap { [weak self] () -> Action? in
                guard let self else { return nil }
                return .showHUD(.warning(self.disabledCreateMessage))
            }
            .bind(to: actionInput)
            .disposed(by: disposeBag)
        }
    }

    public func notifyViewDidLoad() {
        NotificationCenter.default.post(name: Notification.Name.Docs.docsTabDidAppear, object: nil)
    }

    public func notifyViewDidAppear() {
        // 消 badge
        badgeConfig.cleanBadge()
        // TODO 区分下从链接打开和点击tab打开, 分别放在胶水层 tabVC 和 URL router 处理
        tracker.reportEnterHome(from: .clickTab)
        tracker.reportDocsTabShow()

        if multiListSection?.currentSection is SpaceRecentListSection {
            SKCreateTracker.moduleString = StatisticModule.recent.rawValue
            SKCreateTracker.srcModuleString = StatisticModule.home.rawValue
            SKCreateTracker.subModuleString = StatisticModule.recent.rawValue
        } else {
            SKCreateTracker.moduleString = StatisticModule.quickaccess.rawValue
            SKCreateTracker.srcModuleString = StatisticModule.home.rawValue
            SKCreateTracker.subModuleString = StatisticModule.quickaccess.rawValue
        }
        SKCreateTracker.srcFolderID = nil

        let subModule: HomePageSubModule
        if multiListSection?.currentSection is SpaceRecentListSection {
            subModule = .recent
        } else if multiListSection?.currentSection is SpaceFavoritesSection {
            subModule = .favorites
        } else {
            subModule = .quickaccess
        }
        tracker.reportAppear(module: createContext.module, subModule: subModule)

        // 通知 spaceTab appear 事件
        NotificationCenter.default.post(name: .SpaceTabDidAppear, object: nil, userInfo: nil)
    }
}

public final class SpaceStandardHomeViewModel: SpaceHomeViewModel {
    
    public let userResolver: UserResolver
    
    public let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> { actionInput.asSignal() }

    // 是否在导航栏上展示创建按钮，true 时会隐藏右下角的创建按钮
    public let preferCreateButtonOnNaviBar: Bool
    // 创建时直接创建文件夹，取代创建面板
    public let createFolderDirectlyInstead: Bool

    private let createVisableRelay = BehaviorRelay<Bool>(value: true)
    public var createVisableDriver: Driver<Bool> {
        if preferCreateButtonOnNaviBar {
            return .just(false)
        } else {
            return createVisableRelay.asDriver()
        }
    }

    public var createEnableDriver: Driver<Bool> { .just(true) }

    public let createIntentionTrigger = PublishRelay<CreateFromSource>()
    public var tabBadgeVisableChanged: Observable<Bool> { .just(false) }

    private let naviBarItemsRelay = BehaviorRelay<[SpaceNaviBarItem]>(value: [])
    public var naviBarItemsUpdated: Driver<[SpaceNaviBarItem]> {
        naviBarItemsRelay.asDriver()
    }

    public let createContext: SpaceCreateContext

    private let naviBarTitleRelay = PublishRelay<String>()
    public var naviBarTitleDriver: Driver<String>? {
        return naviBarTitleRelay.asDriver(onErrorJustReturn: "")
    }

    private let disposeBag = DisposeBag()

    private var tracker: SpaceHomeTracker
    public var commonTrackParams: [String: String] {
        return tracker.bizParameter.params
    }
    public var refreshAnimatorDescrption: String {
        BundleI18n.SKResource.Doc_List_RefreshDocTips
    }

    public init(userResolver: UserResolver,
                createContext: SpaceCreateContext,
                preferCreateButtonOnNaviBar: Bool,
                createFolderDirectlyInstead: Bool) {
        self.userResolver = userResolver
        self.createContext = createContext
        self.preferCreateButtonOnNaviBar = preferCreateButtonOnNaviBar
        self.createFolderDirectlyInstead = createFolderDirectlyInstead
        self.tracker = SpaceHomeTracker(bizParameter: SpaceBizParameter(module: createContext.module))
        setup()
    }

    convenience init(userResolver: UserResolver,
                     createContext: SpaceCreateContext,
                     preferCreateButtonOnNaviBar: Bool,
                     createFolderDirectlyInstead: Bool,
                     titleRealy: BehaviorRelay<String>) {
        self.init(userResolver: userResolver, createContext: createContext, preferCreateButtonOnNaviBar: preferCreateButtonOnNaviBar, createFolderDirectlyInstead: createFolderDirectlyInstead)
        titleRealy.bind(to: self.naviBarTitleRelay).disposed(by: disposeBag)
    }

    private func makeCreateBarItem() -> SpaceNaviBarItem {
        SKCommonRxNaviBarItem(id: .create,
                              icon: BehaviorRelay(value: UDIcon.moreAddOutlined),
                              visable: createVisableRelay,
                              enabled: BehaviorRelay(value: true)) { [weak self] sourceView in
            guard let self else { return }
            self.createIntentionTrigger.accept((.recent, .bottomRight, sourceView))
        }
    }

    public func update(naviBarItems: [SpaceNaviBarItem]) {
        if preferCreateButtonOnNaviBar {
            var items = naviBarItems
            items.insert(makeCreateBarItem(), at: 0)
            naviBarItemsRelay.accept(items)
        } else {
            naviBarItemsRelay.accept(naviBarItems)
        }
    }

    private func setup() {
        let context = createContext
        let createFolderDirectlyInstead = self.createFolderDirectlyInstead
        createIntentionTrigger.map { (fromSource, location, sourceView) -> Action in
            let intent = Intent(context: context, source: fromSource, createButtonLocation: location)
            if createFolderDirectlyInstead {
                return .createFolder(with: intent)
            } else {
                return .create(with: intent,
                               sourceView: sourceView)
            }
        }
        .bind(to: actionInput)
        .disposed(by: disposeBag)

        if case .shared = createContext.module, SettingConfig.singleContainerEnable {
            createVisableRelay.accept(false)
        }
    }

    public func notifyViewDidLoad() {
        if case .baseHomePage = createContext.module {
            //初始化RN
            NotificationCenter.default.post(name: Notification.Name.Docs.docsTabDidAppear, object: nil)
        }
    }

    public func notifyViewDidAppear() {
        SKCreateTracker.srcFolderID = nil
        switch createContext.module {
        case .favorites:
            SKCreateTracker.moduleString = StatisticModule.favorite.rawValue
        case .offline:
            SKCreateTracker.moduleString = StatisticModule.offline.rawValue
        case .personal:
            SKCreateTracker.moduleString = StatisticModule.personal.rawValue
        case .shared:
            SKCreateTracker.moduleString = StatisticModule.sharetome.rawValue
        default: break
        }
        SKCreateTracker.subModuleString = "" // 重置为空
        tracker.reportAppear(module: createContext.module)

        if case .baseHomePage = createContext.module {
            //更新列表
            NotificationCenter.default.post(name: .SpaceTabDidAppear, object: nil, userInfo: nil)
        }
    }
}

// MARK: - 金刚位 ViewModel
extension SpaceStandardHomeViewModel {
    public static func favorites(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        // 尽管这里写着 quickAccess，但是代码中是按照收藏的逻辑处理的
        let viewModel = standardSearchVM(userResolver: userResolver,
                                         createContext: .favorites,
                                         searchFromType: .quickAccess,
                                         searchFromStatisticName: .favourites)
        // 隐藏收藏列表的新建按钮
        viewModel.createVisableRelay.accept(false)
        return viewModel
    }

    public static func manualOfflines(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .manualOfflines,
                         searchFromType: .normal,
                         searchFromStatisticName: .offline)
    }

    public static func mySpace(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .personal,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal)
    }

    // 云盘-我的文件夹列表，直接创建文件夹
    public static func personalFolder(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .personal,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal,
                         createFolderDirectlyInstead: true)
    }

    public static func unorganizedFile(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .unorganizedFile,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal)
    }

    public static func sharedSpace(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .shared,
                         searchFromType: .normal,
                         searchFromStatisticName: .shared)
    }

    public static func bitableHome(userResolver: UserResolver, module: PageModule) -> SpaceStandardHomeViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .bitableHome(module),
                         searchFromType: .normal,
                         searchFromStatisticName: .bitableHome,
                         fromSpaceType: .bitableHome,
                         preferCreateButtonOnNaviBar: false) // Bitable 首页保留右下角的创建按钮
    }

    public static func recent(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? .spaceNewHome : .recent,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal,
                         fromSpaceType: .docs)
    }

    public static func subordinateRecent(userResolver: UserResolver, titleRelay: BehaviorRelay<String>) -> SpaceStandardHomeViewModel {
        let homeVM = SpaceStandardHomeViewModel(userResolver: userResolver,
                                                createContext: .subordinateRecent,
                                                preferCreateButtonOnNaviBar: false,
                                                createFolderDirectlyInstead: false,
                                                titleRealy: titleRelay)
        homeVM.createVisableRelay.accept(false)
        return homeVM
    }
    
    public static func pinFolderList(userResolver: UserResolver) -> SpaceStandardHomeViewModel {
        let homeVM = SpaceStandardHomeViewModel(userResolver: userResolver,
                                               createContext: .quickAccess,
                                               preferCreateButtonOnNaviBar: false,
                                               createFolderDirectlyInstead: false)
        homeVM.createVisableRelay.accept(false)
        return homeVM
    }

    private static func standardSearchVM(userResolver: UserResolver,
                                         createContext: SpaceCreateContext,
                                         searchFromType: DocsSearchFromType,
                                         searchFromStatisticName: SearchFromStatisticName,
                                         fromSpaceType: DocsSearchType = .docs,
                                         preferCreateButtonOnNaviBar: Bool = UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable,
                                         createFolderDirectlyInstead: Bool = false) -> SpaceStandardHomeViewModel {
        let userID = userResolver.userID
        let homeVM = SpaceStandardHomeViewModel(userResolver: userResolver,
                                                createContext: createContext,
                                                preferCreateButtonOnNaviBar: preferCreateButtonOnNaviBar,
                                                createFolderDirectlyInstead: createFolderDirectlyInstead)
        let searchBarItem = SpaceHomeNaviBarItem.standard(id: .search, icon: BundleResources.SKResource.Common.Global.icon_global_search_nor) { [weak homeVM] _ in
            guard let homeVM = homeVM else { return }
            guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
                DocsLogger.error("can not get WorkspaceSearchFactory")
                return
            }

            let searchVC = factory.createSpaceSearchController(docsSearchType: fromSpaceType,
                                                               searchFrom: searchFromType,
                                                               statisticFrom: searchFromStatisticName)
            if SKDisplay.pad {
                homeVM.actionInput.accept(.push(viewController: searchVC))
            } else {
                let searchNav = LkNavigationController(rootViewController: searchVC)
                searchNav.modalPresentationStyle = .fullScreen
                homeVM.actionInput.accept(.present(viewController: searchNav,
                                                   popoverConfiguration: nil))
            }
            DocsTracker.reportSpacePageSearchClick(module: createContext.module)
        }
        homeVM.update(naviBarItems: [searchBarItem])
        return homeVM
    }
}
