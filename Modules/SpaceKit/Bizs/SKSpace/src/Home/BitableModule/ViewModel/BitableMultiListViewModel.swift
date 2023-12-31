//
//  BitableMultiListViewModel.swift
//  SKSpace
//
//  Created by 刘焱龙 on 2023/11/30.
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

public final class BitableMultiListViewModel: SpaceHomeViewModel {

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

        if case .baseHomePage = createContext.module {
            //更新列表
            NotificationCenter.default.post(name: .SpaceTabDidAppear, object: nil, userInfo: nil)
        }
    }
}

extension BitableMultiListViewModel {
    public static func favorites(userResolver: UserResolver) -> BitableMultiListViewModel {
        // 尽管这里写着 quickAccess，但是代码中是按照收藏的逻辑处理的
        let viewModel = standardSearchVM(userResolver: userResolver,
                                         createContext: .favorites,
                                         searchFromType: .quickAccess,
                                         searchFromStatisticName: .favourites)
        // 隐藏收藏列表的新建按钮
        viewModel.createVisableRelay.accept(false)
        return viewModel
    }

    public static func manualOfflines(userResolver: UserResolver) -> BitableMultiListViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .manualOfflines,
                         searchFromType: .normal,
                         searchFromStatisticName: .offline)
    }

    public static func mySpace(userResolver: UserResolver) -> BitableMultiListViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .personal,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal)
    }

    // 云盘-我的文件夹列表，直接创建文件夹
    public static func personalFolder(userResolver: UserResolver) -> BitableMultiListViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .personal,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal,
                         createFolderDirectlyInstead: true)
    }

    public static func unorganizedFile(userResolver: UserResolver) -> BitableMultiListViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .unorganizedFile,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal)
    }

    public static func sharedSpace(userResolver: UserResolver) -> BitableMultiListViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .shared,
                         searchFromType: .normal,
                         searchFromStatisticName: .shared)
    }

    public static func bitableHome(userResolver: UserResolver, module: PageModule) -> BitableMultiListViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: .bitableHome(module),
                         searchFromType: .normal,
                         searchFromStatisticName: .bitableHome,
                         fromSpaceType: .bitableHome,
                         preferCreateButtonOnNaviBar: false) // Bitable 首页保留右下角的创建按钮
    }

    public static func recent(userResolver: UserResolver) -> BitableMultiListViewModel {
        standardSearchVM(userResolver: userResolver,
                         createContext: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? .spaceNewHome : .recent,
                         searchFromType: .normal,
                         searchFromStatisticName: .personal,
                         fromSpaceType: .docs)
    }

    public static func subordinateRecent(userResolver: UserResolver, titleRelay: BehaviorRelay<String>) -> BitableMultiListViewModel {
        let homeVM = BitableMultiListViewModel(userResolver: userResolver,
                                                createContext: .subordinateRecent,
                                                preferCreateButtonOnNaviBar: false,
                                                createFolderDirectlyInstead: false,
                                                titleRealy: titleRelay)
        homeVM.createVisableRelay.accept(false)
        return homeVM
    }

    private static func standardSearchVM(userResolver: UserResolver,
                                         createContext: SpaceCreateContext,
                                         searchFromType: DocsSearchFromType,
                                         searchFromStatisticName: SearchFromStatisticName,
                                         fromSpaceType: DocsSearchType = .docs,
                                         preferCreateButtonOnNaviBar: Bool = UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable,
                                         createFolderDirectlyInstead: Bool = false) -> BitableMultiListViewModel {
        let userID = userResolver.userID
        let homeVM = BitableMultiListViewModel(userResolver: userResolver,
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
