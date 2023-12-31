//
//  BitableVCFactory.swift
//  SKSpace
//
//  Created by ByteDance on 2023/11/15.
//

import UIKit
import SpaceInterface
import LarkUIKit
import SKCommon
import SKFoundation
import SKUIKit
import SKInfra
import LarkContainer
import SKResource

public final class BitableVCFactoryImpl: BitableVCFactoryProtocol {

    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public func makeBitableMultiListController(context: BaseHomeContext) -> BitableMultiListControllerProtocol? {
        let userResolver = context.userResolver
        let homeType = SpaceHomeType.baseHomeType(context: context)
        let homeViewController = makeBitableMultiListController(userResolver: userResolver, homeType: homeType, context: context)
        return homeViewController
    }

    //MARK: homepageV4 section创建
    private func makeBitableMultiListController(userResolver: UserResolver, homeType: SpaceHomeType, context: BaseHomeContext) -> BitableMultiListController {
        
        //viewModel
        let homeVM = BitableMultiListViewModel.bitableHome(userResolver: userResolver, module: .baseHomePage(context: context))
        
        // 多列列表 最近&收藏&快速访问
        let recentListSection = makeMultiListRecentSection(userResolver:userResolver, homeType: homeType)
        let favoritesSection: BitableFavoritesSection = makeMultiListFavoritesSection(userResolver:userResolver, homeType: homeType)
        let quickAccessSection: BitableQuickAccessSection = makeMultiListQuickAccessSection(userResolver:userResolver, homeType: homeType)
     
        let multiListSection = BitableMultiListSection<BitableMultiSectionHeader>(userResolver: userResolver, homeType: homeType, subSections: [recentListSection, quickAccessSection, favoritesSection])
        
        var sections: [SpaceSection] = []
        sections.append(multiListSection)   // 如果调整了 multiListSection 的顺序，请同时修改下面 indicesHelper 的 sectionIndex
        let sectionIndex = sections.count - 1
        
        let home = SpaceHomeUI(sections: sections)
        let homeViewController =  BitableMultiListController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        recentListSection.visableIndicesHelper = homeViewController.visableIndicesHelper(sectionIndex: sectionIndex)
        // iPad SVC 的逻辑放在胶水层处理
        return homeViewController
    }
    
    private func makeMultiListRecentSection(userResolver: UserResolver, homeType: SpaceHomeType) -> BitableRecentListSection {
        let inLeanMode = !DocsConfigManager.isfetchFullDataOfSpaceList
        let recentDataModel = RecentListDataModel(userResolver: userResolver,
                                                  usingLeanModeAPI: inLeanMode,
                                                  homeType: homeType)
        return BitableRecentListSection(userResolver: userResolver,
                                      viewModel: BitableRecentListViewModel(dataModel: recentDataModel, homeType: homeType),
                                      homeType: homeType)
    }
    
    private func makeMultiListFavoritesSection(userResolver: UserResolver, homeType: SpaceHomeType = .spaceTab) -> BitableFavoritesSection {
        let usingV2API = LKFeatureGating.quickAccessOrStarUseV2Api
        let dataModel = FavoritesDataModel(userID: userResolver.userID, usingV2API: usingV2API, homeType: homeType)
        return BitableFavoritesSection(viewModel: BitableFavoritesViewModel(dataModel: dataModel, homeType: homeType), homeType: homeType)
    }
    
    private func  makeMultiListQuickAccessSection(userResolver: UserResolver, homeType: SpaceHomeType) -> BitableQuickAccessSection {
        let usingV2API = LKFeatureGating.quickAccessOrStarUseV2Api
        let dataModel = QuickAccessDataModel(userID: userResolver.userID, apiType: usingV2API ? .v2 : .v1)
        return BitableQuickAccessSection(userResolver: userResolver, viewModel: BitableQuickAccessViewModel(dataModel: dataModel, homeType: homeType))
    }
}

extension SpaceVCFactory {
    //MARK: homepageV4之前 section创建
    public func makeBaseHomeViewController(userResolver: UserResolver, homeType: SpaceHomeType, context: BaseHomeContext) -> SpaceHomeViewController {
        let homeVM = SpaceStandardHomeViewModel.bitableHome(userResolver: userResolver, module: .baseHomePage(context: context))
        // noticeSection
        let noticeViewModel = SpaceNoticeViewModel(userResolver: userResolver,bulletinManager: homeType.isBaseHomeType() ? nil : DocsContainer.shared.resolve(DocsBulletinManager.self),
                                                   commonTrackParams: homeVM.commonTrackParams)
        let noticeSection = SpaceNoticeSection(userResolver: userResolver, viewModel: noticeViewModel)
        
        // bannerSection
        var bannerSection: SpaceBannerSection?
        if context.containerEnv == .workbench, !UserScopeNoChangeFG.YY.bitableWorkbenchNewEnable {
            let spaceBannerViewModel = SpaceBannerViewModel(reachPointId: "RP_BITABLE_HOME_TOP", scenarioId: "SCENE_BITABLE_COMMON")
            bannerSection = SpaceBannerSection(userResolver: userResolver,
                                               viewModel: spaceBannerViewModel)
        }
        
        // recommendedSection
        // activitySection
        let recommendedHeaderSection = HeaderSection(userResolver: userResolver,
                                                     homeType: homeType)
        var recommendedSection: RecommendedSection?
        if !shouldHideRecommendSection (context: context) {
            recommendedSection = RecommendedSection(userResolver: userResolver,
                                                    dataModel: RecommendedDataModel(),
                                                    homeType: homeType,
                                                    headerSection: recommendedHeaderSection)
        }
        
        let activityHeaderSection = HeaderSection(userResolver: userResolver,
                                                  homeType: homeType)
        var activitySection: ActivitySection?
        if (context.containerEnv != .workbench || UserScopeNoChangeFG.YY.bitableWorkbenchNewEnable) && UserScopeNoChangeFG.YY.bitableTabActivityEnable {
            activitySection = ActivitySection(userResolver: userResolver,
                                              dataModel: ActivityDataModel(),
                                              homeType: homeType,
                                              headerSection: activityHeaderSection)
        }
        
        // multiListSection[recentListSection, quickAccessSection, favoritesSection]
        let recentListSection = makeBitableListSection(homeType: homeType)
        var quickAccessSection: SpaceQuickAccessSection?
        var favoritesSection: SpaceFavoritesSection?
        var multiListHeaderSection: HeaderSection?
        
        if context.containerEnv != .workbench || UserScopeNoChangeFG.YY.bitableWorkbenchNewEnable {
            quickAccessSection = makeBitableQuickAccessListSection(homeType: homeType)
            var header = SectionHeaderInfo(title: BundleI18n.SKResource.Bitable_Workspace_MyBase_Title)
            header.height = 36
            multiListHeaderSection = HeaderSection(userResolver: userResolver, homeType: homeType, headerInfo: header)
            if !UserScopeNoChangeFG.YY.bitableHomepageFavDisable {
                favoritesSection = makeFavoritesListSection(homeType: homeType)
            }
        }
        
        let multiListSection = SpaceMultiListSection<SpaceMultiListHeaderView>(userResolver: userResolver, homeType: homeType) {
            var sections: [SpaceListSubSection] = [
                recentListSection
            ]
            if let quickAccessSection = quickAccessSection {
                sections.append(quickAccessSection)
            }
            if let favoritesSection = favoritesSection {
                sections.append(favoritesSection)
            }
            return sections
        }
        
        var sections: [SpaceSection] = []
        sections.append(noticeSection)
        if let bannerSection = bannerSection {
            sections.append(bannerSection)
        }
                
        if let recommendedSection = recommendedSection {
            sections.append(recommendedHeaderSection)
            sections.append(recommendedSection)
        }
        
        if let activitySection = activitySection {
            if !self.shouldHideActivitySection(context: context) {
                sections.append(activityHeaderSection)
                sections.append(activitySection)
            }
        }
        
        if let multiListHeaderSection = multiListHeaderSection {
            if !self.shouldHideMultiListHeaderSection(context: context) {
                sections.append(multiListHeaderSection)
            }
        }
        sections.append(multiListSection)   // 如果调整了 multiListSection 的顺序，请同时修改下面 indicesHelper 的 sectionIndex
        let sectionIndex = sections.count - 1
        
        let home = SpaceHomeUI(sections: sections)
        let homeViewController = SpaceHomeViewController(userResolver: userResolver,
                                                         naviBarCoordinator: SpaceNaviBarCoordinator(),
                                                         homeUI: home,
                                                         homeViewModel: homeVM)
        recentListSection.visableIndicesHelper = homeViewController.visableIndicesHelper(sectionIndex: sectionIndex)
        // iPad SVC 的逻辑放在胶水层处理
        return homeViewController
    }

    public func makeBitableListSection(homeType: SpaceHomeType) -> SpaceRecentListSection {
        let inLeanMode = !DocsConfigManager.isfetchFullDataOfSpaceList
        let recentDataModel = RecentListDataModel(userResolver: userResolver,
                                                  usingLeanModeAPI: inLeanMode,
                                                  homeType: homeType)
        return SpaceRecentListSection(userResolver: userResolver,
                                      viewModel: RecentListViewModel(dataModel: recentDataModel, homeType: homeType),
                                      homeType: homeType)
    }

    public func makeBitableQuickAccessListSection(homeType: SpaceHomeType) -> SpaceQuickAccessSection {
        let usingV2API = LKFeatureGating.quickAccessOrStarUseV2Api
        let dataModel = QuickAccessDataModel(userID: userResolver.userID, apiType: usingV2API ? .v2 : .v1)
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
            return SpaceQuickAccessSection(userResolver: userResolver, viewModel: QuickAccessViewModel(dataModel: dataModel, homeType: homeType), subTitle: BundleI18n.SKResource.Bitable_Homepage_Pins_Tab)
        } else {
            return SpaceQuickAccessSection(userResolver: userResolver, viewModel: QuickAccessViewModel(dataModel: dataModel, homeType: homeType))
        }
    }

    //MARK: section展示与否逻辑
    private func shouldHideActivitySection(context: BaseHomeContext) -> Bool {
        guard context.containerEnv == .larkTab else {
            return false
        }
        let enable = context.shouldShowRecommend
        return enable
    }
    
    private func shouldHideRecommendSection(context: BaseHomeContext) -> Bool {
        return shouldHideSectionForV3(context: context)
    }
    
    private func shouldHideMultiListHeaderSection(context: BaseHomeContext) -> Bool {
        return shouldHideSectionForV3(context: context)
    }
    
    private func shouldHideSectionForV3(context: BaseHomeContext) -> Bool {
        if context.containerEnv == .larkTab {
            /*主导航场景
             * v2双列场景需要隐藏
             * 非双列v3场景需要隐藏
             * 其余场景正常展示
             */
            return context.shouldShowRecommend || UserScopeNoChangeFG.PXR.bitablehHomepageV3Enable
        } else if context.containerEnv == .workbench {
            /*工作台场景
             * 非双列v3场景需要隐藏
             * UserScopeNoChangeFG.YY.bitableWorkbenchNewEnable 开启了会展示
             * 其余场景不需要显示推荐
             */
            if UserScopeNoChangeFG.YY.bitableWorkbenchNewEnable {
                return UserScopeNoChangeFG.PXR.bitablehHomepageV3Enable
            }
            return true
        } else {
            return false
        }
    }
}
