//
//  SpaceVCFactory+AllFiles.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/6/20.
//

import UIKit
import SKFoundation
import SKResource
import SKInfra
import SKCommon

extension SpaceVCFactory {

    public enum AllFilesSection {
        case recent
        case personalFiles
        case sharedFiles
        case favorites
    }

    public func makeAllFilesController(initialSection: AllFilesSection = .recent) -> UIViewController {
        // Space 首页改版，由最近访问、归我所有、与我共享、收藏构成(归我所有还没做)
        let recentComponent = makeRecentForAllFilesController()
//        let personalFilesComponent = makePersonalFilesForAllFilesController()
        let sharedFilesComponent = makeSharedFilesForAllFilesController()
        let favoriteComponent = makeFavoriteListForAllFilesController()
        let containerVC = SpaceMultiTabContainerController(components: [recentComponent, sharedFilesComponent, favoriteComponent],
                                                           title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_Home_Menu,
                                                           initialIndex: initialSectionIndex(section: initialSection, personalFilesEnable: false))
        return containerVC
    }

    private func initialSectionIndex(section: AllFilesSection, personalFilesEnable: Bool) -> Int {
        switch section {
        case .recent:
            return 0
        case .personalFiles:
            return 1
        case .sharedFiles:
            return personalFilesEnable ? 2 : 1
        case .favorites:
            return personalFilesEnable ? 3 : 2
        }
    }

    private func makeRecentForAllFilesController() -> SpaceListComponent {
        let homeVM = SpaceStandardHomeViewModel.recent(userResolver: userResolver)
        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,
                                                   bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                                   commonTrackParams: homeVM.commonTrackParams)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeViewModel)
        // TODO: 内部拆分下筛选与过滤

        let recentSection = makeRecentListSection(fromV2Tab: false)
        let home = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: recentSection)
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        return SpaceListComponent(subSection: recentSection,
                                  controller: homeViewController,
                                  title: BundleI18n.SKResource.LarkCCM_NewCM_RecentVisits_Menu,
                                  showSortToolOnSwitcher: false)
    }

    private func makeSharedFilesForAllFilesController() -> SpaceListComponent {
        let homeVM = SpaceStandardHomeViewModel.sharedSpace(userResolver: userResolver)
        let noticeVM = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                            commonTrackParams: homeVM.commonTrackParams)

        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        // 只保留文档，不要文件夹部分
        let sharedSpaceSection = makeSharedFileListSection()
        let home = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: sharedSpaceSection)
        }
        let homeVC = SpaceHomeViewController(userResolver: userResolver,
                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                             homeUI: home,
                                             homeViewModel: homeVM)
        return SpaceListComponent(subSection: sharedSpaceSection,
                                  controller: homeVC,
                                  title: BundleI18n.SKResource.Doc_List_Share_With_Me,
                                  showSortToolOnSwitcher: false)
    }

    private func makeFavoriteListForAllFilesController() -> SpaceListComponent {
        let homeVM = SpaceStandardHomeViewModel.favorites(userResolver: userResolver)
        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,
                                                   bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                                   commonTrackParams: homeVM.commonTrackParams)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeViewModel)
        let favoritesSection = makeFavoritesListSection()
        let home = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: favoritesSection)
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        return SpaceListComponent(subSection: favoritesSection,
                                  controller: homeViewController,
                                  title: BundleI18n.SKResource.LarkCCM_Workspace_Home_Favorites,
                                  showSortToolOnSwitcher: false)
    }
}
