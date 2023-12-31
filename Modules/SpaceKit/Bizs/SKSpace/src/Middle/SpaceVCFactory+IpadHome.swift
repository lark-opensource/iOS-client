//
//  SpaceVCFactory+IpadHome.swift
//  SKSpace
//
//  Created by majie.7 on 2023/10/10.
//

import Foundation
import LarkContainer
import SKInfra
import SKCommon
import SKResource


extension SpaceVCFactory {
    // ipad 首页金刚位
    public func makeIpadHomeViewController(userResolver: UserResolver) -> UIViewController {
        let badgeConfig = DocsContainer.shared.resolve(SpaceBadgeConfig.self)!

        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver, createContext: .spaceNewHome, badgeConfig: badgeConfig)
        
        let recentSection = makeRecentListSection(fromV2Tab: false, isShowInDetail: true)
        let shareSpaceSection = makeSharedFileListSection(isShowInDetail: true)
        let favoriteSection = makeFavoritesListSection(homeType: .defaultHome(isFromV2Tab: true), isShowInDetail: true)
        
        let multiSection = SpaceMultiListSection<IpadMultiListHeaderView>(userResolver: userResolver,
                                                                          homeType: .defaultHome(isFromV2Tab: true)) {
            recentSection
            shareSpaceSection
            favoriteSection
        }
        
        let home = SpaceHomeUI {
            multiSection
        }

        let homeViewController = SpaceIpadHomeViewController(userResolver: userResolver,
                                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                             homeUI: home,
                                                             homeViewModel: homeVM,
                                                             useCircleRefreshAnimator: false,
                                                             config: .spaceNewHome)
        let containerVC = SpaceIpadListViewControler(userResolver: userResolver,
                                                     title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_Home_Menu,
                                                     rootViewController: homeViewController) {
            multiSection.currentSectionCreateIntent
        }
        
        SpaceNewHomeTracker.reportSpaceHomePageView()
        return containerVC
    }
    
    // ipad 离线金刚位
    public func makeIpadOfflineViewController(userResolver: UserResolver) -> UIViewController {
        let badgeConfig = DocsContainer.shared.resolve(SpaceBadgeConfig.self)!

        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver, createContext: .spaceNewHome, badgeConfig: badgeConfig)
        
        let offlineSection = makeOffLineListSection(isShowInDetail: true)
        
        let multiSection = SpaceMultiListSection<IpadMultiListHeaderView>(userResolver: userResolver,
                                                                          homeType: .defaultHome(isFromV2Tab: true)) {
            offlineSection
        }
        
        let home = SpaceHomeUI {
            multiSection
        }
        
        let homeViewController = SpaceIpadHomeViewController(userResolver: userResolver,
                                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                             homeUI: home,
                                                             homeViewModel: homeVM,
                                                             useCircleRefreshAnimator: false,
                                                             config: .spaceNewHome)
        let containerVC = SpaceIpadListViewControler(userResolver: userResolver,
                                                     title: BundleI18n.SKResource.Doc_List_OfflineTitle,
                                                     rootViewController: homeViewController) {
            multiSection.currentSectionCreateIntent
        }
        return containerVC
    }
}
