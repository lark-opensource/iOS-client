//
//  HomeTreeSectionFactory.swift
//  SKSpace
//
//  Created by majie.7 on 2023/6/28.
//

import Foundation
import SKWorkspace
import SKUIKit
import LarkContainer
import SKFoundation
import SKCommon
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import LarkUIKit


public class HomeTreeSectionFactory {
    
    public static func makeHomeClipDocumentSection(userResolver: UserResolver,
                                                   coordinator: RefreshCoordinator, slideMutexHelper: SKCustomSlideMutexHelper) -> HomeTreeListSection {
        let dataModel = HomeClipDocumentDataModel()
        let viewModel = HomeTreeSectionViewModel(userResolver: userResolver,
                                                 scene: .clipDocument,
                                                 dataModel: dataModel,
                                                 coordinator: coordinator)
        let section = HomeTreeListSection(userResolver: userResolver,
                                          scene: .clipDocument,
                                          viewModel: viewModel,
                                          slideMutexHelper: slideMutexHelper)
        return section
    }
    
    public static func makeHomeClipWikiSpaceSection(userResolver: UserResolver,
                                                    coordinator: RefreshCoordinator,
                                                    slideMutexHelper: SKCustomSlideMutexHelper) -> HomeTreeListSection {
        let dataModel = WikiMutilTreeDataModel()
        let viewModel = HomeTreeSectionViewModel(userResolver: userResolver,
                                                 scene: .clipWikiSpace,
                                                 dataModel: dataModel,
                                                 coordinator: coordinator)
        let section = HomeTreeListSection(userResolver: userResolver,
                                          scene: .clipWikiSpace,
                                          viewModel: viewModel,
                                          slideMutexHelper: slideMutexHelper)
        return section
    }
    
    // 个人目录树SectionUI样式比较特殊，因此不复用HomeTreeListSection
    public static func makeHomePersonalSecton(userResolver: UserResolver,
                                              coordinator: RefreshCoordinator,
                                              slideMutexHelper: SKCustomSlideMutexHelper) -> HomePersonalSection {
        let section = HomePersonalSection(userResolver: userResolver,
                                          refreshCoordinator: coordinator,
                                          slideMutexHelper: slideMutexHelper)
        return section
    }
    
    // 共享目录树，后续FG关掉后删除代码
    public static func makeShareTreeSection(userResolver: UserResolver,
                                            coordinator: RefreshCoordinator,
                                            slideMutexHelper: SKCustomSlideMutexHelper) -> HomeTreeListSection {
        let dataModel = HomeSharedDataModel()
        let viewModel = HomeTreeSectionViewModel(userResolver: userResolver, scene: .shared, dataModel: dataModel, coordinator: coordinator)
        
        let section = HomeTreeListSection(userResolver: userResolver, scene: .shared, viewModel: viewModel, slideMutexHelper: slideMutexHelper)
        return section
    }
    
    // 多树合一的section
    public static func makeHomeTreeAssembleListSection(userResolver: UserResolver, coordinator: RefreshCoordinator, slideMutexHelper: SKCustomSlideMutexHelper) -> HomeTreeAssembleListSection {
        // 置顶云文档目录树
        let documentDM = HomeClipDocumentDataModel()
        let documentVM = HomeTreeSectionViewModel(userResolver: userResolver, scene: .clipDocument, dataModel: documentDM, coordinator: coordinator)
        // 置顶知识库目录树
        let wikiSpaceDM = WikiMutilTreeDataModel()
        let wikiSpaceVM = HomeTreeSectionViewModel(userResolver: userResolver, scene: .clipWikiSpace, dataModel: wikiSpaceDM, coordinator: coordinator)
        // 共享目录树
        let sharedDM = HomeSharedDataModel()
        let sharedVM = HomeTreeSectionViewModel(userResolver: userResolver, scene: .shared, dataModel: sharedDM, coordinator: coordinator)
        
        var treeViewModels = [HomeTreeSectionViewModel]()
        if UserScopeNoChangeFG.MJ.sidebarSharedEnable {
            treeViewModels = [documentVM, wikiSpaceVM, sharedVM]
        } else {
            treeViewModels = [documentVM, wikiSpaceVM]
        }
        
        let viewModel = HomeTreeAssembleListViewModel(userResolver: userResolver, treeViewModels: treeViewModels, coordinator: coordinator)
        let section = HomeTreeAssembleListSection(viewModel: viewModel, slideMutexHelper: slideMutexHelper)
        return section
    }
    
}

// 导航栏更多按钮列表相关逻辑
public class SpaceHomeListPanelNavigator {
    
    public static func showSpaceListPanel(userResolver: UserResolver, from: UIViewController, sourceView: UIView) {
        guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            return
        }
        let sharedItem = SpaceCommonListItem(leadingLeftIcon: .init(image: UDIcon.groupOutlined, size: CGSize(width: 20, height: 20)),
                                             leadingTitle: .init(title: BundleI18n.SKResource.Doc_List_Share_With_Me,
                                                                 color: UDColor.textTitle,
                                                                 font: .systemFont(ofSize: 16)),
                                             leadingItemSpacing: 12) {
            
            let shareVC = vcFactory.makeNewSharedSpaceViewController(showFolderSection: false)
            let containerVC = SpaceListContainerController(contentViewController: shareVC, title: BundleI18n.SKResource.Doc_List_MainTabHomeShareWithMe)
            userResolver.navigator.push(containerVC, from: from)
        }
        
        let tempelate = SpaceCommonListItem(leadingLeftIcon: .init(image: UDIcon.templateOutlined, size: CGSize(width: 20, height: 20)),
                                            leadingTitle: .init(title: BundleI18n.SKResource.CreationMobile_Onboarding_Templates_Button,
                                                                color: UDColor.textTitle,
                                                                font: .systemFont(ofSize: 16)),
                                            leadingItemSpacing: 12) {
            let vc = TemplateCenterViewController(mountLocation: .default, source: .fromSpaceIcon)
            vc.trackParamter = DocsCreateDirectorV2.TrackParameters(source: .recent,
                                                                    module: .home(.recent),
                                                                    ccmOpenSource: .templateCenter)
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
            if SKDisplay.pad {
                userResolver.navigator.present(vc, wrap: LkNavigationController.self, from: from)
            } else {
                userResolver.navigator.push(vc, from: from)
            }
        }
        
        let conifg = SpaceCommonListConfig(items: [sharedItem, tempelate])
        let panel = SpaceCommonListPanel(title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_MoreOptions_Title, config: conifg)
        panel.setupPopover(sourceView: sourceView, direction: .any)
        userResolver.navigator.present(panel, from: from)
    }
}
