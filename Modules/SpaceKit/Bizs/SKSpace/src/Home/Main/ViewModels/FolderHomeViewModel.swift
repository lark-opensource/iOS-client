//
//  SpaceFolderViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2021/3/24.
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
import UniverseDesignIcon
import SKInfra
import SpaceInterface
import LarkContainer

public struct SpaceSearchContext {
    let searchFromType: DocsSearchFromType
    let module: PageModule
    let isShareFolder: Bool
}

public final class FolderHomeViewModel: SpaceHomeViewModel {
    
    public let userResolver: UserResolver
    
    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> { actionInput.asSignal() }
    
    private let createVisableRelay = BehaviorRelay<Bool>(value: true)
    public var createVisableDriver: Driver<Bool> {
        if UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable {
            return .just(false)
        } else {
            return createVisableRelay.asDriver()
        }
    }

    private let createEnableRelay = BehaviorRelay<Bool>(value: false)
    public var createEnableDriver: Driver<Bool> { createEnableRelay.asDriver() }

    public let createIntentionTrigger = PublishRelay<CreateFromSource>()
    public var tabBadgeVisableChanged: Observable<Bool> { .just(false) }

    private lazy var naviBarItemsRelay = BehaviorRelay<[SpaceNaviBarItem]>(value: [])
    public var naviBarItemsUpdated: Driver<[SpaceNaviBarItem]> {
        naviBarItemsRelay.asDriver()
    }

    // 部分场景下（URL打开、密码分享）无法在进入文件夹时立即获取到文件夹类型，因此需要设计为动态获取的方式
    private let createContextProvider: () -> SpaceCreateContext
    private let searchContextProvider: () -> SpaceSearchContext

    // 由于 SpaceHomeViewModel 协议要求提供埋点公参，但是本类没有 viewModel 属性，所以通过 Provider 注入获取
    var commonTrackParamsProvider: () -> [String: String]
    public var commonTrackParams: [String: String] {
        return commonTrackParamsProvider()
    }
    public var refreshAnimatorDescrption: String {
        let context = createContextProvider()
        switch context.module {
        case .sharedFolderRoot, .shareFolderV2Root:
            return BundleI18n.SKResource.Doc_List_FolderRefreshTips
        default:
            return BundleI18n.SKResource.Doc_List_RefreshDocTips
        }
    }

    private let disposeBag = DisposeBag()

    convenience public init(userResolver: UserResolver,
                            listTools: [SpaceListTool],
                            createEnableUpdated: Observable<Bool>,
                            commonTrackParams: @autoclosure @escaping () -> [String: String],
                            createContext: @autoclosure @escaping () -> SpaceCreateContext,
                            searchContext: @autoclosure @escaping () -> SpaceSearchContext) {
        self.init(userResolver: userResolver,
                  listTools: listTools,
                  createEnableUpdated: createEnableUpdated,
                  commonTrackParamsProvider: commonTrackParams,
                  createContextProvider: createContext,
                  searchContextProvider: searchContext)
    }

    public init(userResolver: UserResolver,
                listTools: [SpaceListTool],
                createEnableUpdated: Observable<Bool>,
                commonTrackParamsProvider: @escaping () -> [String: String],
                createContextProvider: @escaping () -> SpaceCreateContext,
                searchContextProvider: @escaping () -> SpaceSearchContext) {
        self.userResolver = userResolver
        self.commonTrackParamsProvider = commonTrackParamsProvider
        self.createContextProvider = createContextProvider
        self.searchContextProvider = searchContextProvider
        createEnableUpdated.bind(to: createEnableRelay).disposed(by: disposeBag)
        setupCreateContext()
        setup(listTools: listTools)
    }

    private func setupCreateContext() {
        createIntentionTrigger.compactMap { [weak self] (fromSource, location, sourceView) -> Action? in
            guard let self = self else { return nil }
            let context = self.createContextProvider()
            return .create(with: Intent(context: context, source: fromSource, createButtonLocation: location),
                           sourceView: sourceView)
        }
        .bind(to: actionInput)
        .disposed(by: disposeBag)
    }

    private func makeCreateBarItem() -> SpaceNaviBarItem {
        SKCommonRxNaviBarItem(id: .create,
                              icon: BehaviorRelay(value: UDIcon.moreAddOutlined),
                              visable: createVisableRelay,
                              enabled: createEnableRelay) { [weak self] sourceView in
            guard let self else { return }
            let fromSource: FromSource
            if let folderType = self.createContextProvider().folderType {
                fromSource = folderType.isShareFolder ? .sharedFolder : .personalFolder
            } else {
                fromSource = .personalFolder
            }
            self.createIntentionTrigger.accept((fromSource, .bottomRight, sourceView))
        }
    }

    private func setup(listTools: [SpaceListTool]) {
        var barItems = listTools.map { (tool) -> SpaceNaviBarItem in
            switch tool {
            case let .more(isEnabled, handler):
                let iconRelay = BehaviorRelay<UIImage>(value: UDIcon.moreOutlined)
                let enableRelay = BehaviorRelay(value: true)
                isEnabled.bind(to: enableRelay).disposed(by: disposeBag)
                return SpaceHomeNaviBarItem(id: .more, icon: iconRelay, visable: BehaviorRelay(value: true), enabled: enableRelay, clickHandler: handler)
            default:
                spaceAssertionFailure("can not support")
                let iconRelay = BehaviorRelay<UIImage>(value: UDIcon.moreOutlined)
                let enableRelay = BehaviorRelay(value: true)
                return SpaceHomeNaviBarItem(id: .more, icon: iconRelay, visable: BehaviorRelay(value: true), enabled: enableRelay, clickHandler: { _ in })
            }
        }
        if UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable {
            let createItem = makeCreateBarItem()
            barItems.append(createItem)
        }
        let searchBarItem = SpaceHomeNaviBarItem.standard(id: .search, icon: UDIcon.searchOutlined) { [weak self] _ in
            guard let self = self else { return }
            guard let factory = try? self.userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
                DocsLogger.error("can not get WorkspaceSearchFactory")
                return
            }

            let searchContext = self.searchContextProvider()
            let searchVC = factory.createSpaceSearchController(docsSearchType: .docs,
                                                               searchFrom: searchContext.searchFromType,
                                                               statisticFrom: .personal)
            if SKDisplay.pad {
                self.actionInput.accept(.push(viewController: searchVC))
            } else {
                let searchNav = LkNavigationController(rootViewController: searchVC)
                searchNav.modalPresentationStyle = .fullScreen
                self.actionInput.accept(.present(viewController: searchNav,
                                                   popoverConfiguration: nil))
            }
            // 我的空间1.0, 共享空间1.0, 子文件夹埋点上报
            DocsTracker.reprotFolderPageSearchClick(module: searchContext.module, isShare: searchContext.isShareFolder)
        }
        barItems.append(searchBarItem)

        naviBarItemsRelay.accept(barItems)
        
        let createContext = createContextProvider()
        if case .shareFolderV2Root = createContext.module {
            createVisableRelay.accept(false)
        }
    }

    public func notifyViewDidLoad() {}

    public func notifyViewDidAppear() {
        SKCreateTracker.srcFolderID = nil
        SKCreateTracker.subModuleString = "" // 重置为空
        let createContext = createContextProvider()
        if let folderType = createContext.folderType {
            let module = folderType.isShareFolder ? "shared_folder" : "folder"
            SKCreateTracker.moduleString = module
            if !createContext.mountLocationToken.isEmpty {
                SKCreateTracker.srcFolderID = DocsTracker.encrypt(id: createContext.mountLocationToken)
            } else {
                SKCreateTracker.srcFolderID = nil
            }
        } else {
            switch createContext.module {
            case .personal:
                SKCreateTracker.moduleString = StatisticModule.personal.rawValue
            case .shared:
                SKCreateTracker.moduleString = StatisticModule.sharetome.rawValue
            default: break
            }
        }
    }
}
