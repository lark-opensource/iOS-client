//
//  SpaceVCFactory+CloudDrive.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/6/25.
//

import UIKit
import SKFoundation
import SKResource
import SKInfra
import SKCommon
import LarkContainer
import LarkUIKit
import SKWorkspace

extension SpaceVCFactory {
    public func makeCloudDriveViewController() -> UIViewController {
        // 构建两个 homeVC 组合在 contain二VC 内
        let mySpaceComponent = makeMySpaceForCloudDriveController()
        let sharedSpaceComponent = makeShareSpaceForCloudDriveController()
        let containerVC = SpaceMultiTabContainerController(components: [mySpaceComponent, sharedSpaceComponent],
                                                           title: BundleI18n.SKResource.LarkCCM_CM_Drive_Header)
        return containerVC
    }

    private func makeMySpaceForCloudDriveController() -> SpaceListComponent {
        let homeVM = SpaceStandardHomeViewModel.mySpace(userResolver: userResolver)
        let noticeVM = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                            commonTrackParams: homeVM.commonTrackParams)

        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        let mySpaceSection = makePersonalFileListSection()
        // 这里和正常的 mySpaceHomeUI 不一样，去掉了 subSection 的包装
        let home = SpaceHomeUI {
            noticeSection
            mySpaceSection
        }
        let homeVC = SpaceHomeViewController(userResolver: userResolver,
                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                             homeUI: home,
                                             homeViewModel: homeVM)
        return SpaceListComponent(subSection: mySpaceSection,
                                  controller: homeVC,
                                  title: BundleI18n.SKResource.Doc_List_My_Space,
                                  showSortToolOnSwitcher: true)
    }

    private func makeShareSpaceForCloudDriveController() -> SpaceListComponent {
        let homeVM = SpaceStandardHomeViewModel.sharedSpace(userResolver: userResolver)
        let noticeVM = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                            commonTrackParams: homeVM.commonTrackParams)

        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        // 检查是否要展示历史文件夹banner
        let input = V2ShareFolderListAPI.checkHasHistoryFolder()
        noticeVM.showHistoryFolderIfNeed(input: input)

        let sharedSpaceSection = makeSharedFileListSection()

        let home = SpaceHomeUI {
            noticeSection
            // 2.0新共享空间 有共享文件夹列表， 2.0旧共享空间无共享文件夹列表
            if LKFeatureGating.newShareSpace {
                makeShareFolderListSection()
            }
            // 此场景需要屏蔽 sectionHeader 的 listTools
            SpaceSingleListSection(userResolver: userResolver, subSection: sharedSpaceSection, listToolsEnabled: false)
        }
        let title = LKFeatureGating.newShareSpace
        ? BundleI18n.SKResource.Doc_List_Shared_Space
        : BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab
        let homeVC = SpaceHomeViewController(userResolver: userResolver,
                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                             homeUI: home,
                                             homeViewModel: homeVM)
        return SpaceListComponent(subSection: sharedSpaceSection,
                                  controller: homeVC,
                                  title: title,
                                  showSortToolOnSwitcher: false)
    }
}

// 新首页下的云盘创建逻辑
extension SpaceVCFactory {
    public func makeCloudDriveViewControllerV2() -> UIViewController {
        // 构建两个 homeVC 组合在 contain二VC 内
        let mySpaceComponent = makeMySpaceForCloudDriveControllerV2()
        let sharedSpaceComponent = makeShareSpaceForCloudDriveControllerV2()
        let containerVC: UIViewController
        // 新首页下FG开使用展示快速访问文件夹的新容器，否则继续使用旧的容器展示
        if UserScopeNoChangeFG.MJ.quickAccessFolderEnable {
            containerVC = CloudDriverViewController(userResolver: userResolver,
                                                    components: [mySpaceComponent, sharedSpaceComponent],
                                                    title: BundleI18n.SKResource.LarkCCM_CM_Drive_Header)
            
        } else {
            containerVC = SpaceMultiTabContainerController(components: [mySpaceComponent, sharedSpaceComponent],
                                                           title: BundleI18n.SKResource.LarkCCM_CM_Drive_Header)
        }
        
        return containerVC
    }

    private func makeMySpaceForCloudDriveControllerV2() -> SpaceListComponent {
        let homeVM = SpaceStandardHomeViewModel.mySpace(userResolver: userResolver)
        let noticeVM = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                            commonTrackParams: homeVM.commonTrackParams)

        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        let mySpaceSection = makePersonalFileListSection()
        // 这里和正常的 mySpaceHomeUI 不一样，去掉了 subSection 的包装
        let home = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: mySpaceSection)
        }
        let homeVC = SpaceHomeViewController(userResolver: userResolver,
                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                             homeUI: home,
                                             homeViewModel: homeVM)
        return SpaceListComponent(subSection: mySpaceSection,
                                  controller: homeVC,
                                  title: BundleI18n.SKResource.LarkCCM_NewCM_MyFolder_Menu,
                                  showSortToolOnSwitcher: true)
    }

    private func makeShareSpaceForCloudDriveControllerV2() -> SpaceListComponent {
        let homeVM = SpaceStandardHomeViewModel.sharedSpace(userResolver: userResolver)
        let noticeVM = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                            commonTrackParams: homeVM.commonTrackParams)

        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeVM)
        // 检查是否要展示历史文件夹banner
        let input = V2ShareFolderListAPI.checkHasHistoryFolder()
        noticeVM.showHistoryFolderIfNeed(input: input)

        let dataModel = ShareFolderDataModel(userID: userResolver.userID, usingAPI: .newShareFolder)
        let viewModel = ShareFolderListViewModel(dataModel: dataModel)
        let sharedSpaceSection = FolderListSection(userResolver: userResolver, viewModel: viewModel)

        let hiddenFolderSection = HiddenFolderListSection(userResolver: userResolver, viewModel: viewModel)

        let home = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: sharedSpaceSection)
            hiddenFolderSection
        }
        let homeVC = SpaceHomeViewController(userResolver: userResolver,
                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                             homeUI: home,
                                             homeViewModel: homeVM)
        return SpaceListComponent(subSection: sharedSpaceSection,
                                  controller: homeVC,
                                  title: BundleI18n.SKResource.LarkCCM_NewCM_SharedFolder_Menu,
                                  showSortToolOnSwitcher: true)
    }
    
    public func makeIpadCloudDriverViewController(userResolver: UserResolver) -> UIViewController {
        let homeVM = SpaceStandardHomeViewModel.sharedSpace(userResolver: userResolver)
        
        let mySpaceSection = makePersonalFileListSection(isShowInDetail: true)
        
        let dataModel = ShareFolderDataModel(userID: userResolver.userID, usingAPI: .newShareFolder)
        let viewModel = ShareFolderListViewModel(dataModel: dataModel)
        let sharedSpaceSection = FolderListSection(userResolver: userResolver, viewModel: viewModel, isShowInDetail: true)

        
        let multiSection = SpaceMultiListSection<IpadMultiListHeaderView>(userResolver: userResolver,
                                                                          homeType: .defaultHome(isFromV2Tab: true)) {
            mySpaceSection
            sharedSpaceSection
        }
        
        let hiddenFolderSection = HiddenFolderListSection(userResolver: userResolver,
                                                          viewModel: viewModel,
                                                          subSectionIdentifierObservable: multiSection.currentSectionModuleUpdated,
                                                          isShowInDetail: true)
        
        let home = SpaceHomeUI {
            multiSection
            hiddenFolderSection
        }
        
        let homeViewController = SpaceIpadHomeViewController(userResolver: userResolver,
                                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                             homeUI: home,
                                                             homeViewModel: homeVM,
                                                             useCircleRefreshAnimator: false,
                                                             config: .spaceNewHome)
        let containerVC = SpaceIpadListViewControler(userResolver: userResolver,
                                                     title: BundleI18n.SKResource.LarkCCM_CM_Drive_Header,
                                                     rootViewController: homeViewController,
                                                     config: .cloudDriver) {
            multiSection.currentSectionCreateIntent
        }
        return containerVC
    }
}

// 快速访问文件夹列表
extension SpaceVCFactory {
    public func makePinFolderListViewController() -> UIViewController {
        let homeVM = SpaceStandardHomeViewModel.pinFolderList(userResolver: userResolver)
        
        let quickAccessViewModel = QuickAccessViewModel(dataModel: QuickAccessDataModel(userID: userResolver.userID, apiType: .justFolder))
        let quickAccessSection = SpaceQuickAccessSection(userResolver: userResolver, viewModel: quickAccessViewModel)
        quickAccessViewModel.didBecomeActive()
        
        let homeUI = SpaceHomeUI {
            quickAccessSection
        }
        
        let listVC = SpaceHomeViewController(userResolver: userResolver,
                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                             homeUI: homeUI,
                                             homeViewModel: homeVM)
        let containerVC = SpaceListContainerController(contentViewController: listVC,
                                                       title: BundleI18n.SKResource.Doc_List_Quick_Access)
        return containerVC
    }
    
    public func makeIpadPinFolderListViewController() -> UIViewController {
        let homeVM = SpaceStandardHomeViewModel.pinFolderList(userResolver: userResolver)
        
        let quickAccessViewModel = QuickAccessViewModel(dataModel: QuickAccessDataModel(userID: userResolver.userID, apiType: .justFolder))
        let quickAccessSection = SpaceQuickAccessSection(userResolver: userResolver,
                                                         viewModel: quickAccessViewModel,
                                                         subTitle: BundleI18n.SKResource.Doc_Facade_CreateFolder,
                                                         isShowInDetail: true)
        
        let multiSection = SpaceMultiListSection<IpadMultiListHeaderView>(userResolver: userResolver,
                                                                          homeType: .defaultHome(isFromV2Tab: true)) {
            quickAccessSection
        }
        
        let home = SpaceHomeUI {
            multiSection
        }
        
        let homeViewController = SpaceIpadHomeViewController(userResolver: userResolver,
                                                             naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                             homeUI: home,
                                                             homeViewModel: homeVM,
                                                             useCircleRefreshAnimator: false,
                                                             config: .default)
        let regularVC = SpaceIpadListViewControler(userResolver: userResolver,
                                                     title: BundleI18n.SKResource.Doc_List_Quick_Access,
                                                     rootViewController: homeViewController,
                                                     config: .pinFolderList) {
            multiSection.currentSectionCreateIntent
        }
        
        let compactVC = makePinFolderListViewController()
        let containerVC = WorkspaceIPadContainerController(compactController: compactVC, regularController: regularVC)
        return containerVC
    }
}
