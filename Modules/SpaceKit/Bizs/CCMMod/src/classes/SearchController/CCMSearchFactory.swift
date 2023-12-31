//
//  CCMSearchFactory.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/15.
//

import Foundation
import SKSpace
import SpaceInterface
import SKFoundation
import SKCommon
import SKWikiV2
import SKResource
import LarkContainer
#if MessengerMod
import LarkSearchCore
import LarkModel
#endif

final class CCMSearchFactory: WorkspaceSearchFactory {
    /// 供"我的空间"和"共享空间"的搜索
    
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    func createSpaceSearchController(docsSearchType: DocsSearchType,
                                     searchFrom: DocsSearchFromType,
                                     statisticFrom: SearchFromStatisticName) -> UIViewController {
        #if MessengerMod
            return createPickerSpaceSearchController(searchFrom: searchFrom)
        #else
            return BaseViewController()
        #endif
    }

    /// 供"知识库首页"的 [知识空间｜云文档] 的搜索
    func createWikiSearchController() -> UIViewController {
        #if MessengerMod
            return createPickerWikiSearchController()
        #else
            return BaseViewController()
        #endif
    }

    /// 供"单个知识库首页"的Wiki树节点搜索
    func createWikiTreeSearchController(spaceID: String, delegate: WikiTreeSearchDelegate) -> UIViewController {
        #if MessengerMod
            return createPickerWikiTreeSearchController(spaceID: spaceID, delegate: delegate)
        #else
            return BaseViewController()
        #endif
    }

    /// 供"移快副"场景使用的 [知识空间｜文件夹｜文件] 的搜索
    func createWikiAndFolderSearchController(config: WorkspacePickerConfig) -> UIViewController {
        #if MessengerMod
            return createPickerWikiAndFolderSearchController(config: config)
        #else
            return BaseViewController()
        #endif
    }

    /// 搜索文件夹
    func createFolderSearchController(config: WorkspacePickerConfig) -> UIViewController {
        #if MessengerMod
            return createPickerFolderSearchController(config: config)
        #else
            return BaseViewController()
        #endif
    }

    /// 搜索Wiki空间
    func createWikiSpaceSearchController(delegate: WikiTreeSearchDelegate) -> UIViewController {
        #if MessengerMod
            return createPickerWikiSpaceSearchController(delegate: delegate) 
        #else
            return BaseViewController()
        #endif
    }
}

//// Legacy
//private extension CCMSearchFactory {
//
//    func createLegacyWikiSearchController() -> UIViewController {
//        return WikiUniversalSearchViewController(userResolver: userResolver)
//    }
//
//    func createLegacyWikiTreeSearchController(type: WikiSearchType, spaceID: String, delegate: WikiTreeSearchDelegate) -> UIViewController {
//        let controller = WikiTreeSearchWrapperController(spaceId: spaceID, type: type)
//        controller.delegate = delegate
//        return controller
//    }
//
//    func createLegacyFolderSearchController(config: WorkspacePickerConfig) -> UIViewController {
//        let completion = config.completion
//        let callback: DirectoryUtilCallback = { location, picker in
//            completion(.folder(location: location.folderPickerLocation), picker)
//        }
//        let context = DirectorySearchVCContext(action: .callback(completion: callback),
//                                               ownerTypeChecker: config.ownerTypeChecker)
//        context.actionName = config.actionName
//        return DirectorySearchViewController(userResolver: userResolver, context: context, isPick: false)
//    }
//}

#if MessengerMod
// Picker Impl
private extension CCMSearchFactory {
    func createPickerSpaceSearchController(searchFrom: DocsSearchFromType) -> UIViewController {
        //SearchPickerNavigationController
        //SearchPickerViewController
        let controller = SearchPickerViewController(resolver: userResolver)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmSearchInSpace,
                                                       searchBar: searchBarConfig)
        let folderInfo: CCMSearchFolderInfo?
        switch searchFrom {
        case .normal, .quickAccess:
            folderInfo = nil
        case let .folder(token, name, isShareFolder):
            folderInfo = CCMSearchFolderInfo(token: token, name: name, isShareFolder: isShareFolder)
        }
        let viewModel = CCMSpaceSearchViewModel(currentFolder: folderInfo, resolver: userResolver)
        let defaultSearchConfig = viewModel.generateSearchConfig()
        controller.searchConfig = defaultSearchConfig
        let filterConfigView = CCMSearchFilterConfigView(viewModel: viewModel)
        filterConfigView.hostController = controller
        controller.topView = filterConfigView
        controller.pickerDelegate = viewModel
        controller.defaultView = PickerRecommendListView(resolver: userResolver)
        return controller
    }

    func createPickerWikiSearchController() -> UIViewController {
        let controller = SearchPickerViewController(resolver: userResolver)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmSearchInWiki,
                                                       searchBar: searchBarConfig)
        let viewModel = CCMWikiSearchViewModel(resolver: userResolver)
        let defaultView = PickerRecommendListView(resolver: userResolver)
        defaultView.add(provider: CCMWikiSearchSpaceRecommendProvider(),
                        for: CCMWikiSearchViewModel.wikiSpaceRecommendProviderKey)
        defaultView.switchProvider(by: CCMWikiSearchViewModel.wikiSpaceRecommendProviderKey)
        viewModel.defaultView = defaultView
        let segmentView = CCMSearchFilterSegmentView(viewModel: viewModel)
        segmentView.bind(searchController: controller)
        controller.topView = segmentView
        controller.defaultView = defaultView
        return controller
    }

    private func createPickerWikiTreeSearchController(spaceID: String, delegate: WikiTreeSearchDelegate) -> UIViewController {
        let delegateProxy = CCMWikiTreeSearchProxy(delegate: delegate)
        let controller = SearchPickerViewController(resolver: userResolver)
        // topView 没有内容，目的是为了强持有 delegateProxy，否则 proxy 会因为没有强引用直接析构
        controller.topView = CCMPickerPlaceHolderTopView(proxy: delegateProxy)
        controller.defaultView = PickerRecommendListView(resolver: userResolver)
        controller.pickerDelegate = delegateProxy
        controller.searchConfig = PickerSearchConfig(entities: [
            PickerConfig.WikiEntityConfig(spaceIds: [spaceID])
        ])
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmSearchInWikiTree,
                                                       searchBar: searchBarConfig)

        return controller
    }

    func createPickerWikiAndFolderSearchController(config: WorkspacePickerConfig) -> UIViewController {
        let controller = SearchPickerViewController(resolver: userResolver)
        let defaultView = PickerRecommendListView(resolver: userResolver)
        defaultView.add(provider: CCMWikiSearchSpaceRecommendProvider(),
                        for: CCMWikiAndFolderSearchSegmentViewModel.workspaceRecommendProviderKey)
        controller.defaultView = defaultView

        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true,
                                                            hasCancelBtn: false)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmSearchInWikiAndFolder,
                                                       searchBar: searchBarConfig)
        let viewModel = CCMWikiAndFolderSearchSegmentViewModel(userResolver: userResolver, config: config)
        viewModel.defaultView = defaultView
        let segmentView = CCMSearchFilterSegmentView(viewModel: viewModel)
        segmentView.bind(searchController: controller)
        controller.topView = segmentView

        let vc = BaseViewController()
        vc.navigationBar.title = viewModel.searchbarTitle
        vc.addChild(controller)
        vc.view.addSubview(controller.view)
        controller.didMove(toParent: vc)
        controller.view.snp.makeConstraints { (make) in
            make.top.equalTo(vc.navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        return vc
    }

    func createPickerFolderSearchController(config: WorkspacePickerConfig) -> UIViewController {
        let searchVC = SearchPickerViewController(resolver: userResolver)
        let viewModel = CCMFolderSearchViewModel(userResolver: userResolver, config: config) // 即 SearchPickerDelegate
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false, autoFocus: true, hasCancelBtn: false)
        searchVC.defaultView = PickerRecommendListView(resolver: userResolver)
        searchVC.pickerDelegate = viewModel
        searchVC.searchConfig = viewModel.generateSearchConfig()
        searchVC.featureConfig = PickerFeatureConfig(scene: .ccmSearchFolder, searchBar: searchBarConfig)
        let vc = CCMSearchHolderController(searchVC: searchVC, viewModel: viewModel)
        vc.navigationBar.title = SKResource.BundleI18n.SKResource.Doc_Facade_SelectFolder

        return vc
    }

    func createPickerWikiSpaceSearchController(delegate: WikiTreeSearchDelegate) -> UIViewController {
        let delegateProxy = CCMWikiTreeSearchProxy(delegate: delegate, type: .wikiSpace)
        let viewModel = CCMWikiSpaceSearchViewModel(userResolver: userResolver)
        let defaultView = PickerRecommendListView(resolver: userResolver)
        defaultView.add(provider: CCMWikiSearchSpaceRecommendProvider(), for: "wiki-space")
        let controller = SearchPickerViewController(resolver: userResolver)
        controller.topView = CCMPickerPlaceHolderTopView(proxy: delegateProxy)
        controller.defaultView = defaultView
        controller.pickerDelegate = delegateProxy
        controller.searchConfig = viewModel.generateSearchConfig()
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmSearchWikiSpace,
                                                       searchBar: searchBarConfig)
        return controller
    }

}

#endif

extension CCMSearchFactory: DocsPickerFactory {
    
    func createDocsPicker(delegate: DocsPickerDelegate) -> UIViewController {
        #if MessengerMod
        let proxy = CCMDocsPickerProxy(delegate: delegate)
        let controller = SearchPickerNavigationController(resolver: userResolver)
        controller.searchConfig = PickerSearchConfig(entities: [
            PickerConfig.DocEntityConfig(types: [.doc, .docx],
                                         searchContentTypes: [.onlyTitle]),
            PickerConfig.WikiEntityConfig(types: [.doc, .docx],
                                          searchContentTypes: [.onlyTitle])
        ])
        controller.defaultView = PickerRecommendListView(resolver: userResolver)
        
        let placeHolderView = CCMDocsSearchPlaceHolderTopView(proxy: proxy)
        
        controller.topView = placeHolderView

        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: SKResource.BundleI18n.SKResource.LarkCCM_Docs_MyAi_MentionDocs_Title,
                                                              showSure: false)
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true,
                                                            autoCorrect: true)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmSearchInSpace,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: searchBarConfig)
        controller.pickerDelegate = proxy
        return controller
        #else
        return BaseViewController()
        #endif
    }
    
}
