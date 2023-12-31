//
//  SpaceVCFactory.swift
//  SpaceKit
//
//  Created by Huang JinZhu on 2018/7/5.

import UIKit
import SwiftyJSON
import SpaceInterface
import LarkUIKit
import LarkSplitViewController
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import RxSwift
import RxRelay
import SKInfra
import LarkContainer

public enum SpaceHomeType {
    case defaultHome(isFromV2Tab: Bool)
    case baseHomeType(context: BaseHomeContext)

    public static var spaceTab: Self {
        .defaultHome(isFromV2Tab: false)
    }

    public static var fromSpaceV2Tab: Self {
        .defaultHome(isFromV2Tab: true)
    }

    public func isBaseHomeType() -> Bool {
        if case .baseHomeType = self {
            return true
        } else {
            return false
        }
    }
    
    public func pageModule() -> PageModule? {
        if case let .baseHomeType(context) = self {
            return .baseHomePage(context: context)
        } else {
            return nil
        }
    }
}

public final class SpaceVCFactory {

    public let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
}

extension SpaceVCFactory {

    public func makeNewMySpaceViewController() -> SpaceHomeViewController {
        let homeVM = SpaceStandardHomeViewModel.mySpace(userResolver: userResolver)
        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,
                                                   bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                                   commonTrackParams: homeVM.commonTrackParams)

        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeViewModel)
        let mySpaceSection = makePersonalFileListSection()
        let home = SpaceHomeUI {
            noticeSection
            if !SettingConfig.singleContainerEnable {
                makeMyFolderListSection()
            }
            SpaceSingleListSection(userResolver: userResolver, subSection: mySpaceSection)
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        return homeViewController
    }

    public func makeNewFavoriteViewController() -> SpaceHomeViewController {
        let homeVM = SpaceStandardHomeViewModel.favorites(userResolver: userResolver)
        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
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
        return homeViewController
    }

    public func makeSubordinateRecentViewController(subordinateID: String) -> SpaceHomeViewController {

        let subordinateRecentSection = makeSubordinateRecentListSection(subordinateID: subordinateID)
        let homeVM = SpaceStandardHomeViewModel.subordinateRecent(userResolver: userResolver, titleRelay: subordinateRecentSection.titleRelay)
        let home = SpaceHomeUI {
            SpaceSingleListSection(userResolver: userResolver, subSection: subordinateRecentSection)
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        return homeViewController
    }

    public func makeNewSharedSpaceViewController(showFolderSection: Bool) -> SpaceHomeViewController {
        let homeVM = SpaceStandardHomeViewModel.sharedSpace(userResolver: userResolver)
        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                                   commonTrackParams: homeVM.commonTrackParams)

        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeViewModel)

        if SettingConfig.singleContainerEnable {
            // 检查是否要展示历史文件夹banner
            let input = V2ShareFolderListAPI.checkHasHistoryFolder()
            noticeViewModel.showHistoryFolderIfNeed(input: input)
        }

        let sharedSpaceSection = makeSharedFileListSection()

        let home = SpaceHomeUI {
            noticeSection
            if showFolderSection {
                makeShareFolderListSection()
            }
            SpaceSingleListSection(userResolver: userResolver, subSection: sharedSpaceSection)
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        return homeViewController
    }

    // TODO: 在 User.current 可以保证可靠取到 UserID 前，暂时强制要求外部传入
    // 背景: Docs 的 handle user login 的时机可能晚于 Space Tab 的展示时机，导致无法可靠读取到 UserID,
    // 后续应该推动 UserID 注入和 handleUserLogin 的逻辑分离，尽早注入 UserID
    public func makeRecentListSection(fromV2Tab: Bool = false, isShowInDetail: Bool = false) -> SpaceRecentListSection {
        let inLeanMode = !DocsConfigManager.isfetchFullDataOfSpaceList
        let recentDataModel = RecentListDataModel(userResolver: userResolver, usingLeanModeAPI: inLeanMode)
        let viewModel = RecentListViewModel(dataModel: recentDataModel, homeType: .defaultHome(isFromV2Tab: fromV2Tab), isShowInDetail: isShowInDetail)
        return SpaceRecentListSection(userResolver: userResolver,
                                      viewModel: viewModel,
                                      homeType: .defaultHome(isFromV2Tab: fromV2Tab),
                                      isShowInDetail: isShowInDetail)
    }

    // TODO: 在 User.current 可以保证可靠取到 UserID 前，暂时强制要求外部传入
    // 背景: Docs 的 handle user login 的时机可能晚于 Space Tab 的展示时机，导致无法可靠读取到 UserID,
    // 后续应该推动 UserID 注入和 handleUserLogin 的逻辑分离，尽早注入 UserID
    public func makeQuickAccessListSection() -> SpaceQuickAccessSection {
        let usingV2API = LKFeatureGating.quickAccessOrStarUseV2Api
        let dataModel = QuickAccessDataModel(userID: userResolver.userID, apiType: usingV2API ? .v2 : .v1)
        return SpaceQuickAccessSection(userResolver: userResolver, viewModel: QuickAccessViewModel(dataModel: dataModel))
    }

    public func makeFavoritesListSection(homeType: SpaceHomeType = .spaceTab, isShowInDetail: Bool = false) -> SpaceFavoritesSection {
        let usingV2API = LKFeatureGating.quickAccessOrStarUseV2Api
        let dataModel = FavoritesDataModel(userID: userResolver.userID, usingV2API: usingV2API, homeType: homeType)
        return SpaceFavoritesSection(viewModel: FavoritesViewModel(dataModel: dataModel, homeType: homeType), homeType: homeType, isShowInDetail: isShowInDetail)
    }

    public func makeOffLineListSection(isShowInDetail: Bool = false) -> SpaceOfflineSection {
        let dataModel = ManuOffLineDataModel(userResolver: userResolver)
        return SpaceOfflineSection(viewModel: OfflineViewModel(dataModel: dataModel), isShowInDetail: isShowInDetail)
    }

    public func makePersonalFileListSection(isShowInDetail: Bool = false) -> MySpaceSection {
        let usingV2API = SettingConfig.singleContainerEnable
        let dataModel = PersonalFileDataModel(userID: userResolver.userID, usingV2API: usingV2API)
        return MySpaceSection(userResolver: userResolver, viewModel: MySpaceViewModel(dataModel: dataModel, isShowInDetail: isShowInDetail), createContext: .personal, isShowInDetail: isShowInDetail)
    }

    public func makeSharedFileListSection(isShowInDetail: Bool = false) -> SharedSpaceSection {
        var apiType: SharedFileApiType = .sharedFileV1
        if SettingConfig.singleContainerEnable {
            apiType = .sharedFileV2
            if LKFeatureGating.newShareSpace {
                apiType = .sharedFileV3
            }
        }
        let dataModel = SharedFileDataModel(userID: userResolver.userID, usingAPI: apiType)
        let viewModel = SharedSpaceViewModel(dataModel: dataModel)
        return SharedSpaceSection(viewModel: viewModel, isShowInDetail: isShowInDetail)
    }

    public func makeMyFolderListSection() -> SpaceVerticalGridSection {
        let dataModel = MyFolderDataModel(userID: userResolver.userID)
        let viewModel = PersonalFolderVerticalGridViewModel(userResolver: userResolver, dataModel: dataModel)
        return SpaceVerticalGridSection(userResolver: userResolver, viewModel: viewModel, config: .personalFolder)
    }

    public func makeShareFolderListSection() -> SpaceVerticalGridSection {
        var apiType: ShareFolderAPIType = .shareFolderV1
        if SettingConfig.singleContainerEnable && LKFeatureGating.newShareSpace {
            apiType = .newShareFolder
        }
        let dataModel = ShareFolderDataModel(userID: userResolver.userID, usingAPI: apiType)
        let viewModel = ShareFolderVerticalGridViewModel(userResolver: userResolver, dataModel: dataModel)
        return SpaceVerticalGridSection(userResolver: userResolver, viewModel: viewModel, config: .shareFolder)
    }

    public func makeSubordinateRecentListSection(subordinateID: String) -> SubordinateRecentListSection {
        let dataModel = SubordinateRecentListDataModel(userID: userResolver.userID, subordinateID: subordinateID)
        let viewModel = SubordinateRecentListViewModel(dataModel: dataModel)
        return SubordinateRecentListSection(viewModel: viewModel)
    }

    func makeMyFolderListController() -> UIViewController {
        let dataModel = MyFolderDataModel(userID: userResolver.userID)
        let viewModel = MyFolderListViewModel(dataModel: dataModel)
        let folderSection = FolderListSection(userResolver: userResolver, viewModel: viewModel)

        let containerVM = SpaceDefaultFolderContainerViewModel.myFolderRoot
        let homeVM = FolderHomeViewModel(userResolver: userResolver,
                                         listTools: folderSection.navTools,
                                         createEnableUpdated: .just(true),
                                         commonTrackParams: containerVM.bizParams.params,
                                         createContext: .personalFolderRoot,
                                         searchContext: SpaceSearchContext(searchFromType: .normal, module: .personalFolderRoot, isShareFolder: false))

        let noticeVM = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!, commonTrackParams: homeVM.commonTrackParams)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        let home = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: folderSection)
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        let containerVC = SpaceFolderContainerController(userResolver: userResolver, contentViewController: homeViewController, viewModel: containerVM)
        return containerVC
    }

    // 是否在 2.0 环境下，从不同入口传不同的值
    func makeShareFolderListController(apiType: ShareFolderAPIType, isShowInDetail: Bool = false) -> UIViewController {
        let dataModel = ShareFolderDataModel(userID: userResolver.userID, usingAPI: apiType)
        let viewModel = ShareFolderListViewModel(dataModel: dataModel)
        let folderSection = FolderListSection(userResolver: userResolver, viewModel: viewModel, isShowInDetail: isShowInDetail)

        var createContext: SpaceCreateContext = .sharedFolderRoot
        var containerVM = SpaceDefaultFolderContainerViewModel.sharedFolderRoot
        if apiType == .hiddenFolder {
            containerVM = SpaceDefaultFolderContainerViewModel.hiddenFolderRoot
            createContext = .newShareFolderRoot
        }
        if apiType == .newShareFolder {
            containerVM = SpaceDefaultFolderContainerViewModel.shareFolderV2Root
            createContext = .newShareFolderRoot
        }
        let homeVM = FolderHomeViewModel(userResolver: userResolver,
                                         listTools: folderSection.navTools,
                                         createEnableUpdated: .just(true),
                                         commonTrackParams: containerVM.bizParams.params,
                                         createContext: createContext,
                                         searchContext: SpaceSearchContext(searchFromType: .normal, module: createContext.module, isShareFolder: false))

        let noticeVM = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!, commonTrackParams: homeVM.commonTrackParams)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        let hiddenFolderSection = HiddenFolderListSection(userResolver: userResolver, viewModel: viewModel)

        let home: SpaceHomeUI
        switch apiType {
        case .shareFolderV1, .shareFolderV2:
            home = SpaceHomeUI {
                noticeSection
                SpaceSingleListSection(userResolver: userResolver, subSection: folderSection)
            }
        case .newShareFolder:
            home = SpaceHomeUI {
                noticeSection
                SpaceSingleListSection(userResolver: userResolver, subSection: folderSection)
                hiddenFolderSection
            }
        case .hiddenFolder:
            if isShowInDetail {
                let multiSection = SpaceMultiListSection<IpadMultiListHeaderView>(userResolver: userResolver,
                                                                                  homeType: .defaultHome(isFromV2Tab: true)) {
                    folderSection
                }
                home = SpaceHomeUI(sections: {
                    multiSection
                })
            } else {
                home = SpaceHomeUI {
                    noticeSection
                    SpaceSingleListSection(userResolver: userResolver, subSection: folderSection)
                }
            }
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        let containerVC = SpaceFolderContainerController(userResolver: userResolver, contentViewController: homeViewController, viewModel: containerVM)
        return containerVC
    }
}
