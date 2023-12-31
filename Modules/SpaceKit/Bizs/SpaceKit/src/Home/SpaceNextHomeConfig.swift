//
//  SpaceNextHomeConfig.swift
//  SpaceKit
//
//  Created by Weston Wu on 2023/5/18.
//

import SKSpace
import SKResource
import SKCommon
import SKUIKit
import SKFoundation
import SKWikiV2
import UniverseDesignIcon
import UniverseDesignColor
import SKInfra
import LarkContainer
import SKWorkspace
import LarkUIKit

private struct SpaceNextEntranceFactory {
    let userResolver: UserResolver
    
    private static let iconSize = CGSize(width: 22, height: 22)

    var wiki: SpaceEntrance {
        SpaceEntrance(identifier: "wiki_home",
                      image: UDIcon.getIconByKey(.wikiColorful,
                                                 size: Self.iconSize),
                      themeColor: UDColor.primaryPri50,
                      title: BundleI18n.SKResource.Doc_Facade_Wiki) { _ in
            SpaceSubSectionTracker.reportEnter(module: .wiki)
            let wikiVC = WikiVCFactory.makeWikiHomePageVC(userResolver: userResolver,
                                                          params: ["from": "recent"])
            return .push(viewController: wikiVC)
        }
    }

    var offline: SpaceEntrance {
        SpaceEntrance(identifier: "offline",
                      image: UDIcon.getIconByKey(.offline2Colorful, size: Self.iconSize),
                      themeColor: UDColor.G50,
                      title: BundleI18n.SKResource.Doc_List_OfflineTitle) { _ in
            guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
                DocsLogger.error("can not get SpaceVCFactory")
                return .push(viewController: BaseViewController())
            }
            
            let offlinesContentViewController = vcFactory.makeNewManualOfflinesViewController()
            let containerVC = SpaceListContainerController(contentViewController: offlinesContentViewController, title: BundleI18n.SKResource.Doc_List_OfflineTitle)
            return .push(viewController: containerVC)
        }
    }

    var cloudDrive: SpaceEntrance {
        return SpaceEntrance(identifier: SpaceEntranceSection.EntranceIdentifier.cloudDrive,
                             image: UDIcon.getIconByKey(.driveSpaceColorful, size: Self.iconSize),
                             themeColor: UDColor.W50,
                             title: BundleI18n.SKResource.LarkCCM_CM_Drive_Header) { _ in
            
            guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
                DocsLogger.error("can not get SpaceVCFactory")
                return .push(viewController: BaseViewController())
            }

            let controller = vcFactory.makeCloudDriveViewControllerV2()
            
            SpaceNewHomeTracker.reportSpaceDrivePageView()
            SpaceNewHomeTracker.reportSpaceHomePageClick(params: .drive)
            return .push(viewController: controller)
        }
    }

    var favorites: SpaceEntrance {
        return SpaceEntrance(identifier: "favorite",
                             image: UDIcon.getIconByKey(.collectFilled,
                                                        iconColor: UDColor.colorfulYellow,
                                                        size: Self.iconSize),
                             themeColor: UDColor.Y50,
                             title: BundleI18n.SKResource.Doc_List_MainTabHomeFavorite) { _ in
            guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
                DocsLogger.error("can not get SpaceVCFactory")
                return .push(viewController: BaseViewController())
            }
            let favoritesContentViewController = vcFactory.makeNewFavoriteViewController()
            let containerVC = SpaceListContainerController(contentViewController: favoritesContentViewController,
                                                           title: BundleI18n.SKResource.Doc_List_MainTabHomeFavorite)
            return .push(viewController: containerVC)
        }
    }
}

extension SpaceVCFactory {
    
    
    public func makeSpaceNextHomeViewController(userResolver: UserResolver) -> SpaceHomeViewController {
        // 从缓存的索引中确定当前首页所展示的列表
        var trackerReportScene: SpacePerformanceReportScene
        let multiSectionIndexCache = SpaceMultiSectionIndexCache(needActive: true, identifier: SpaceMultiSectionNewTabHeaderView.reuseIdentifier)
        let index = multiSectionIndexCache.get()
        if index == 0 {
            trackerReportScene = .homeContents
        } else {
            trackerReportScene = .recent
        }
        
        userResolver.docs.spacePerformanceTracker?.reportStartLoading(scene: trackerReportScene)
        userResolver.docs.spacePerformanceTracker?.begin(stage: .createVC, scene: trackerReportScene)
        defer {
            userResolver.docs.spacePerformanceTracker?.end(stage: .createVC, succeed: true, dataSize: 0, scene: trackerReportScene)
        }
        let badgeConfig = DocsContainer.shared.resolve(SpaceBadgeConfig.self)!
        
        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver, createContext: .spaceNewHome, badgeConfig: badgeConfig)
        
        
        let entranceProvider = SpaceNextEntranceFactory(userResolver: userResolver)
        let entranceSection = SpaceEntranceSection(userResolver: userResolver,
                                                   layoutType: SpaceEntranceV2Layout.self,
                                                   cellType: SpaceEntranceV2Cell.self) {
            entranceProvider.cloudDrive
            entranceProvider.wiki
            entranceProvider.favorites
            entranceProvider.offline
        }
        
        let noticeModel = SpaceNoticeViewModel(userResolver: userResolver, bulletinManager: nil, commonTrackParams: [:])
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeModel)
        
        // 保证个人、置顶数据串行化加载
        let refreshCoordinator = RefreshCoordinator()
        // 保证多个cell同时侧滑面板弹出互斥
        let mutexHelper = SKCustomSlideMutexHelper()
        
        let homeAssembleTreeSection = HomeTreeSectionFactory.makeHomeTreeAssembleListSection(userResolver: userResolver, coordinator: refreshCoordinator, slideMutexHelper: mutexHelper)
        let recentListSection = makeRecentListSection(fromV2Tab: true)
        
        let multiListSection = SpaceMultiListSection<SpaceMultiSectionNewTabHeaderView>(userResolver: userResolver,
                                                                                        homeType: .spaceTab,
                                                                                        needActiveIndexCache: true) {
            recentListSection
            homeAssembleTreeSection
        }
        
        let uploadSection = SpaceUploadSection(userResolver: userResolver)
        
        let home = SpaceHomeUI {
            noticeSection
            entranceSection
            uploadSection
            multiListSection
        }
        let sectionIndex = 4
        
        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM,
                                                         useCircleRefreshAnimator: true,
                                                         config: .spaceNewHome)
        recentListSection.visableIndicesHelper = homeViewController.visableIndicesHelper(sectionIndex: sectionIndex)
        SpaceNewHomeTracker.reportSpaceHomePageView()
        return homeViewController
    }
}
