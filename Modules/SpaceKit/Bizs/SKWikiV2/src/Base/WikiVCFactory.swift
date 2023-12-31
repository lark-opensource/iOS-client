//
//  WikiVCFactory.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/22.
//  

import UIKit
import SKCommon
import SKBrowser
import SKSpace
import SKResource
import SKWorkspace
import SpaceInterface
import LarkContainer

public final class WikiVCFactory {

    public static func isTopViewController(_ curVC: UIViewController, topBrowser: UIViewController) -> Bool {
        if let vc = curVC as? WikiContainerViewController { // 如果当前是WikiContainerViewController
            return vc.lastChildVC as? BaseViewController == topBrowser
        }
        return false
    }

    /// url超链接打开wiki详情L
    public static func makeWikiContainerVC(userResolver: UserResolver,
                                           wikiURL: URL,
                                           params: [AnyHashable: Any]?,
                                           extraInfo: [AnyHashable: Any]) -> UIViewController {
        return WikiVCFactory.makeWikiContainerViewController(userResolver: userResolver,
                                                             url: wikiURL,
                                                             params: params,
                                                             extraInfo: extraInfo)
    }

    public static func makeWikiContainerVC(userResolver: UserResolver,
                                           wikiInfo: WikiInfo,
                                           params: [AnyHashable: Any]?,
                                           extraInfo: [AnyHashable: Any]) -> UIViewController {
        return WikiVCFactory
            .makeWikiContainerViewController(userResolver: userResolver,
                                             wikiNode: WikiNodeMeta(wikiToken: wikiInfo.wikiToken,
                                                                    objToken: wikiInfo.objToken,
                                                                    docsType: wikiInfo.docsType,
                                                                    spaceID: wikiInfo.spaceId),
                                             treeContext: nil,
                                             params: params,
                                             extraInfo: [:])
    }

    
    public static func makeWikiWorkSpaceController(userResolver: UserResolver, wikiWorkSpaceType: WikiWorkSpaceType) -> UIViewController {
        return WikiWorkSpaceViewController(userResolver: userResolver,
                                           spaces: [:],
                                           pickerType: wikiWorkSpaceType)
    }
    
    
    public static func makeWikiHomePageVC(userResolver: UserResolver,
                                          params: [AnyHashable: Any]?,
                                          openWikiHomeWhenClosedWikiTree: Bool = false,
                                          navigationBarDependency: WikiHomePageViewController.NavigationBarDependency = .default) -> UIViewController {
        return _makeWikiHomeViewController(userResolver: userResolver, openWikiHomeWhenClosedWikiTree: openWikiHomeWhenClosedWikiTree, params: params)
    }

    public static func makeWikiSpaceVC(userResolver: UserResolver,
                                       spaceId: String,
                                       wikiToken: String? = nil,
                                       url: URL? = nil) -> UIViewController {
        return WikiTreeCoverViewController(userResolver: userResolver,
                                           viewModel: WikiTreeCoverViewModel(userResolver: userResolver, spaceId: spaceId, wikiToken: wikiToken),
                                           wikiSpaceUrl: url)
    }
    
    public static func makeWikiMyLibraryVC(userResolver: UserResolver) -> UIViewController {
        let vm = MyLibraryViewModel(userResolver: userResolver)
        return MyLibraryViewController(userResolver: userResolver, viewModel: vm)
    }

    static func makeWikiContainerViewController(userResolver: UserResolver,
                                                url: URL,
                                                params: [AnyHashable: Any]?,
                                                extraInfo: [AnyHashable: Any]) -> WikiContainerViewController {
        let from = url.queryParameters["from"] ?? params?["from"] as? String ?? "file_link"
        var finalExtraInfo = extraInfo
        finalExtraInfo["from"] = from
        let vm = WikiContainerViewModel(userResolver: userResolver, url: url, params: params, extraInfo: finalExtraInfo)
        return WikiContainerViewController(userResolver: userResolver, viewModel: vm)
    }

    static func makeWikiContainerViewController(userResolver: UserResolver,
                                                wikiNode: WikiNodeMeta,
                                                treeContext: WikiTreeContext?,
                                                params: [AnyHashable: Any]?,
                                                extraInfo: [AnyHashable: Any]) -> WikiContainerViewController {
        let from = params?["from"] as? String ?? "file_link"
        var finalExtraInfo = extraInfo
        finalExtraInfo["from"] = from
        let vm = WikiContainerViewModel(userResolver: userResolver,
                                        wikiNode: wikiNode,
                                        treeContext: treeContext,
                                        params: params,
                                        extraInfo: finalExtraInfo)
        return WikiContainerViewController(userResolver: userResolver, viewModel: vm)
    }

    /// Wiki 首页接入云空间 Tab
    private static func _makeWikiHomeViewController(userResolver: UserResolver, openWikiHomeWhenClosedWikiTree: Bool, params: [AnyHashable: Any]? = nil) -> UIViewController {
        let navigationBarDependency = WikiHomePageViewController.NavigationBarDependency(navigationBarHeight: 0,
                                                                                         shouldShowCustomNaviBar: false,
                                                                                         shouldShowNetworkBanner: false)
        WikiPerformanceTracker.shared.reportStartLoading()
        WikiPerformanceTracker.shared.begin(stage: .createVC)
        defer {
            WikiPerformanceTracker.shared.end(stage: .createVC, succeed: true, dataSize: 0)
        }
        let wikiHome = WikiHomePageViewController(userResolver: userResolver,
                                                  params: params,
                                                  navigationBarDependency: navigationBarDependency,
                                                  openWikiHomeWhenClosedWikiTree: openWikiHomeWhenClosedWikiTree)
        
        let title = BundleI18n.SKResource.Doc_Facade_Wiki
        return CustomHomeWrapperViewController(wrappee: wikiHome, title: title)
    }

    public static func makeWikiSpaceViewController(userResolver: UserResolver, spaceID: String) -> UIViewController {
        let viewModel = WikiTreeCoverViewModel(userResolver: userResolver, spaceId: spaceID)
        let treeVC = WikiTreeCoverViewController(userResolver: userResolver, viewModel: viewModel)
        return treeVC
    }
}
