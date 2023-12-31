//
//  SpaceNextIpadHomeConfig.swift
//  SpaceKit
//
//  Created by majie.7 on 2023/9/28.
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

private struct SpaceNextIpadEntranceFactory {
    let userResolver: UserResolver
    private static let iconSize = CGSize(width: 22, height: 22)
    
    // ipad 主页金刚位
    var home: SpaceEntrance {
        return SpaceEntrance(identifier: SpaceEntranceSection.EntranceIdentifier.ipadHome,
                             image: UDIcon.getIconByKey(.homeFilled,
                                                        iconColor: UDColor.functionInfoContentDefault,
                                                        size: Self.iconSize),
                             title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_Home_Menu) { _ in
            guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
                DocsLogger.error("can not get SpaceVCFactory")
                return .showDetail(viewController: BaseViewController())
            }
            
            let phoneViewController = vcFactory.makeAllFilesController(initialSection: .recent)
            let ipadViewController = vcFactory.makeIpadHomeViewController(userResolver: userResolver)
            let containerVC = LkNavigationController(rootViewController:  WorkspaceIPadContainerController(compactController: phoneViewController,
                                                                                                           regularController: ipadViewController))
            containerVC.navigationBar.isHidden = true
            return .showDetail(viewController: containerVC)
        }
    }
    
    var wiki: SpaceEntrance {
        SpaceEntrance(identifier: SpaceEntranceSection.EntranceIdentifier.ipadWiki,
                      image: UDIcon.getIconByKey(.wikiColorful,
                                                 size: Self.iconSize),
                      themeColor: UDColor.primaryPri50,
                      title: BundleI18n.SKResource.Doc_Facade_Wiki) { _ in
            SpaceSubSectionTracker.reportEnter(module: .wiki)
            let wikiVC = WikiVCFactory.makeWikiHomePageVC(userResolver: userResolver,
                                                          params: ["from": "recent"],
                                                          openWikiHomeWhenClosedWikiTree: true)
            let regularVC = WikiIPadHomePageViewController(userResolver: userResolver)
            let container = WorkspaceIPadContainerController(compactController: wikiVC, regularController: regularVC)
            return .showDetail(viewController: container)
        }
    }
    
    var cloudDrive: SpaceEntrance {
        return SpaceEntrance(identifier: SpaceEntranceSection.EntranceIdentifier.ipadCloudDriver,
                             image: UDIcon.getIconByKey(.driveSpaceColorful, size: Self.iconSize),
                             themeColor: UDColor.W50,
                             title: BundleI18n.SKResource.LarkCCM_CM_Drive_Header) { _ in
            
            guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
                DocsLogger.error("can not get SpaceVCFactory")
                return .showDetail(viewController: BaseViewController())
            }

            let controller = vcFactory.makeCloudDriveViewControllerV2()
            let regularVC = vcFactory.makeIpadCloudDriverViewController(userResolver: userResolver)
            let containerVC = LkNavigationController(rootViewController: WorkspaceIPadContainerController(compactController: controller, regularController: regularVC))
            containerVC.navigationBar.isHidden = true
            
            return .showDetail(viewController: containerVC)
        }
    }
    
    var offline: SpaceEntrance {
        SpaceEntrance(identifier: SpaceEntranceSection.EntranceIdentifier.ipadOffline,
                      image: UDIcon.getIconByKey(.offline2Colorful, size: Self.iconSize),
                      themeColor: UDColor.G50,
                      title: BundleI18n.SKResource.Doc_List_OfflineTitle) { _ in
            guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
                DocsLogger.error("can not get SpaceVCFactory")
                return .showDetail(viewController: BaseViewController())
            }
            
            let offlineVC = vcFactory.makeNewManualOfflinesViewController()
            let compactVC = SpaceListContainerController(contentViewController: offlineVC, title: BundleI18n.SKResource.Doc_List_OfflineTitle)
            
            let regularVC = vcFactory.makeIpadOfflineViewController(userResolver: userResolver)
            let containerVC = LkNavigationController(rootViewController:  WorkspaceIPadContainerController(compactController: compactVC,
                                                                                                           regularController: regularVC))
            containerVC.navigationBar.isHidden = true
            return .showDetail(viewController: containerVC)
        }
    }
    
}

extension SpaceVCFactory {
    // ipad Space Tab页
    public func makeSpaceNextHomeIpadViewController(userResolver: UserResolver) -> SpaceHomeViewController {
        userResolver.docs.spacePerformanceTracker?.reportStartLoading(scene: .homeContents)
        userResolver.docs.spacePerformanceTracker?.begin(stage: .createVC, scene: .homeContents)
        defer {
            userResolver.docs.spacePerformanceTracker?.end(stage: .createVC, succeed: true, dataSize: 0, scene: .homeContents)
        }
        let badgeConfig = DocsContainer.shared.resolve(SpaceBadgeConfig.self)!

        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver, createContext: .spaceNewHome, badgeConfig: badgeConfig)
        
        let entranceProvider = SpaceNextIpadEntranceFactory(userResolver: userResolver)
        let entranceSection = SpaceEntranceSection(userResolver: userResolver,
                                                   layoutType: SpaceEntranceIpadLayout.self,
                                                   cellType: SpaceEntranceIpadCell.self) {
            entranceProvider.home
            entranceProvider.cloudDrive
            entranceProvider.wiki
            entranceProvider.offline
        }
        
        let noticeModel = SpaceNoticeViewModel(userResolver: userResolver, bulletinManager: nil, commonTrackParams: [:])
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeModel)
        
        // 保证个人、置顶数据串行化加载
        let refreshCoordinator = RefreshCoordinator()
        // 保证多个cell同时侧滑面板弹出互斥
        let mutexHelper = SKCustomSlideMutexHelper()
        
        let documentTreeSection = HomeTreeSectionFactory.makeHomeClipDocumentSection(userResolver: userResolver, coordinator: refreshCoordinator, slideMutexHelper: mutexHelper)
        let wikiTreeSection = HomeTreeSectionFactory.makeHomeClipWikiSpaceSection(userResolver: userResolver, coordinator: refreshCoordinator, slideMutexHelper: mutexHelper)
        let sharedSection = HomeTreeSectionFactory.makeShareTreeSection(userResolver: userResolver, coordinator: refreshCoordinator, slideMutexHelper: mutexHelper)
        let personalSection = HomeTreeSectionFactory.makeHomePersonalSecton(userResolver: userResolver, coordinator: refreshCoordinator, slideMutexHelper: mutexHelper)
        
        let ipadInsetWidht: CGFloat = 16
        let uploadSection = SpaceUploadSection(userResolver: userResolver, insetWidth: ipadInsetWidht)
        
        let home = SpaceHomeUI {
            noticeSection
            uploadSection
            entranceSection
            documentTreeSection
            wikiTreeSection
            if UserScopeNoChangeFG.MJ.sidebarSharedEnable {
                sharedSection
            }
            personalSection
        }

        let homeViewController = SpaceIpadHomeViewController(userResolver: userResolver,
                                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                             homeUI: home,
                                                             homeViewModel: homeVM,
                                                             useCircleRefreshAnimator: true,
                                                             config: .init(canLoadMore: false),
                                                             ipadHomeConfig: .tabHome)
        SpaceNewHomeTracker.reportSpaceHomePageView()
        return homeViewController
    }
}
