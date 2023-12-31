//
//  SpaceHomeConfig.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/12/1.
//

import SKSpace
import SKResource
import SKCommon
import SKUIKit
import SKFoundation
import SKWikiV2
import UniverseDesignIcon
import SKInfra
import LarkSetting
import SKBitable
import LarkContainer

private struct SpaceEntranceFactory {
    let userResolver: UserResolver
    
    private static let iconSize = CGSize(width: 30, height: 30)
    
    private var vcFactory: SpaceVCFactory? {
        guard let factory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            DocsLogger.error("can not get SpaceVCFactory")
            return nil
        }

        return factory
    }

    var mySpace: SpaceEntrance {
        let userID = userResolver.userID
        return SpaceEntrance(identifier: "personal",
                             image: UDIcon.getIconByKey(.fileFolderColorful, size: Self.iconSize),
                             title: BundleI18n.SKResource.Doc_List_My_Space) { _ in
            guard let mySpaceContentViewController = vcFactory?.makeNewMySpaceViewController() else {
                DocsLogger.error("can not get mySpaceContentViewController")
                return .push(viewController: BaseViewController())
            }
            let containerVC = SpaceListContainerController(contentViewController: mySpaceContentViewController, title: BundleI18n.SKResource.Doc_List_My_Space)
            return .push(viewController: containerVC)
        }
    }

    var shareSpace: SpaceEntrance {
        let userID = userResolver.userID
        var title = SettingConfig.singleContainerEnable ? BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab : BundleI18n.SKResource.Doc_List_Shared_Space
        if SettingConfig.singleContainerEnable && LKFeatureGating.newShareSpace {
            title = BundleI18n.SKResource.Doc_List_Shared_Space
        }
        return SpaceEntrance(identifier: "sharetome",
                             image: UDIcon.getIconByKey(.sharedspaceColorful, size: Self.iconSize),
                             title: title) { _ in
            // 1.0共享空间 或 2.0新共享空间 有共享文件夹列表， 2.0旧共享空间无共享文件夹列表
            let showFolderSection = !SettingConfig.singleContainerEnable || LKFeatureGating.newShareSpace
            guard let sharedSpaceContentViewController = vcFactory?.makeNewSharedSpaceViewController(showFolderSection: showFolderSection) else {
                DocsLogger.error("can not get sharedSpaceContentViewController")
                return .push(viewController: BaseViewController())
            }
            let containerVC = SpaceListContainerController(contentViewController: sharedSpaceContentViewController, title: title)
            return .push(viewController: containerVC)
        }
    }

    var wiki: SpaceEntrance {
        SpaceEntrance(identifier: "wiki_home",
                      image: UDIcon.getIconByKey(.wikiColorful, size: Self.iconSize),
                      title: BundleI18n.SKResource.Doc_Wiki_Home_Title) { _ in
            SpaceSubSectionTracker.reportEnter(module: .wiki)
            let wikiVC = WikiVCFactory.makeWikiHomePageVC(userResolver: userResolver, params: ["from": "recent"])
            return .push(viewController: wikiVC)
        }
    }

    var favorites: SpaceEntrance {
        let userID = userResolver.userID
        return SpaceEntrance(identifier: "favorite",
                             image: UDIcon.getIconByKey(.favoritesColorful, size: Self.iconSize),
                             title: BundleI18n.SKResource.Doc_List_MainTabHomeFavorite) { _ in
            guard let favoritesContentViewController = vcFactory?.makeNewFavoriteViewController() else {
                DocsLogger.error("can not get favoritesContentViewController")
                return .push(viewController: BaseViewController())
            }

            let containerVC = SpaceListContainerController(contentViewController: favoritesContentViewController, title: BundleI18n.SKResource.Doc_List_MainTabHomeFavorite)
            return .push(viewController: containerVC)
        }
    }

    var offline: SpaceEntrance {
        SpaceEntrance(identifier: "offline",
                      image: UDIcon.getIconByKey(.offline2Colorful, size: Self.iconSize),
                      title: BundleI18n.SKResource.Doc_List_OfflineTitle) { _ in
            guard let offlinesContentViewController = vcFactory?.makeNewManualOfflinesViewController() else {
                DocsLogger.error("can not get offlinesContentViewController")
                return .push(viewController: BaseViewController())
            }
            let containerVC = SpaceListContainerController(contentViewController: offlinesContentViewController, title: BundleI18n.SKResource.Doc_List_OfflineTitle)
            return .push(viewController: containerVC)
        }
    }

    var templateCenter: SpaceEntrance {

        SpaceEntrance(identifier: "template",
                      image: UDIcon.getIconByKey(.templateColorful, size: Self.iconSize),
                      title: BundleI18n.SKResource.CreationMobile_Onboarding_Templates_Button) { _ in
            SpaceSubSectionTracker.reportEnter(module: .template)
            let vc = TemplateCenterViewController(mountLocation: .default, source: .fromSpaceIcon)
            // TODO: @wuwenjian.weston 确认下金刚位进入的 source
            vc.trackParamter = DocsCreateDirectorV2.TrackParameters(source: .recent,
                                                                    module: .home(.recent),
                                                                    ccmOpenSource: .templateCenter)
            return .presentOrPush(viewController: vc) { (vc) in
                vc.modalPresentationStyle = .formSheet
                vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
                vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
            }
        }
    }
    
    var myLibrary: SpaceEntrance {
        SpaceEntrance(identifier: SpaceEntranceSection.EntranceIdentifier.myLibrary,
                      image: UDIcon.getIconByKey(.mywikiColorful, size: Self.iconSize),
                      title: BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu) { _ in
            let vc = WikiVCFactory.makeWikiMyLibraryVC(userResolver: userResolver)
            return .push(viewController: vc)
        }
    }

    var cloudDrive: SpaceEntrance {
        let userID = userResolver.userID
        return SpaceEntrance(identifier: SpaceEntranceSection.EntranceIdentifier.cloudDrive,
                             image: UDIcon.getIconByKey(.driveSpaceColorful, size: Self.iconSize),
                             title: BundleI18n.SKResource.LarkCCM_CM_Drive_Header) { _ in
            guard let controller = vcFactory?.makeCloudDriveViewController() else {
                DocsLogger.error("can not get CloudDriveViewController")
                return .push(viewController: BaseViewController())
            }
            return .push(viewController: controller)
        }
    }
}

extension SpaceVCFactory {

    public func makeNewManualOfflinesViewController() -> SpaceHomeViewController {
        let homeVM = SpaceStandardHomeViewModel.manualOfflines(userResolver: userResolver)
        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: DocsContainer.shared.resolve(DocsBulletinManager.self)!,
                                                   commonTrackParams: homeVM.commonTrackParams)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeViewModel)
        let offlineSection = makeOffLineListSection()
        let home = SpaceHomeUI {
            noticeSection
            SpaceSingleListSection(userResolver: userResolver, subSection: offlineSection)
        }

        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        return homeViewController
    }

    public func makeSpaceHomeViewController(userResolver: UserResolver, homeType: SpaceHomeType = .spaceTab) -> SpaceHomeViewController {
        let userID = userResolver.userID
        if case let .baseHomeType(context) = homeType {
            // Base 分支
            return makeBaseHomeViewController(userResolver: userResolver, homeType: homeType, context: context)
        }
        userResolver.docs.spacePerformanceTracker?.reportStartLoading(scene: .recent)
        userResolver.docs.spacePerformanceTracker?.begin(stage: .createVC, scene: .recent)
        defer {
            userResolver.docs.spacePerformanceTracker?.end(stage: .createVC, succeed: true, dataSize: 0, scene: .recent)
        }
        let badgeConfig = DocsContainer.shared.resolve(SpaceBadgeConfig.self)!

        let homeVM = LarkSpaceHomeViewModel(userResolver: userResolver, createContext: .recent, badgeConfig: badgeConfig)

        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: homeType.isBaseHomeType() ? nil : DocsContainer.shared.resolve(DocsBulletinManager.self),
                                                   commonTrackParams: homeVM.commonTrackParams)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeViewModel)
        let spaceBannerViewModel = SpaceBannerViewModel()
        let bannerSection = SpaceBannerSection(userResolver: userResolver,
                                               viewModel: spaceBannerViewModel)
        
        let enctranceProvider = SpaceEntranceFactory(userResolver: userResolver)
        let cloudDriveEnable = SettingConfig.singleContainerEnable && UserScopeNoChangeFG.WWJ.cloudDriveEnabled
        let entranceSection = SpaceEntranceSection(userResolver: userResolver) {
            if cloudDriveEnable {
                enctranceProvider.myLibrary
                enctranceProvider.wiki
                enctranceProvider.cloudDrive
            } else {
                enctranceProvider.mySpace
                enctranceProvider.shareSpace
                enctranceProvider.wiki
            }

            enctranceProvider.favorites
            enctranceProvider.offline

            // 目前iPad没有模板中心
            if TemplateRemoteConfig.templateEnable {
                enctranceProvider.templateCenter
            }
        }
        
        let recentListSection  = makeRecentListSection()
        let quickAccessSection  = makeQuickAccessListSection()
        
        let multiListSection = SpaceMultiListSection<SpaceMultiListHeaderView>(userResolver: userResolver, homeType: homeType) {
            recentListSection
            quickAccessSection
        }
        
        var sections: [SpaceSection] = []
        sections.append(noticeSection)
        sections.append(bannerSection)
        sections.append(entranceSection)
        sections.append(multiListSection)   // 如果调整了 multiListSection 的顺序，请同时修改下面 indicesHelper 的 sectionIndex
        
        
        let home = SpaceHomeUI(sections: sections)

        homeVM.multiListSection = multiListSection
        let sectionIndex = 3
        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        recentListSection.visableIndicesHelper = homeViewController.visableIndicesHelper(sectionIndex: sectionIndex)
        // iPad SVC 的逻辑放在胶水层处理
        return homeViewController
    }
    
}
