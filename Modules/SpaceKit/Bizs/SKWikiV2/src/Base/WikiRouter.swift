//
//  WikiRouter.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/10/21.
//

import Foundation
import EENavigator
import LarkUIKit
import SKCommon
import SKFoundation
import SKWorkspace
import SpaceInterface
import LarkContainer

class WikiRouter {
    /// 使用wiki树节点数据跳转到wiki详情界面
    @discardableResult
    static func gotoWikiDetail(_ wikiNodeMeta: WikiNodeMeta,
                               userResolver: UserResolver,
                               extraInfo: [AnyHashable: Any],
                               fromVC: UIViewController,
                               treeContext: WikiTreeContext? = nil,
                               completion: Completion? = nil) -> WikiContainerViewController? {
        let params: [AnyHashable: Any] = ["from": treeContext?.params?["from"] ?? extraInfo["from"] ?? "pages"]
        let vc = WikiVCFactory.makeWikiContainerViewController(userResolver: userResolver,
                                                               wikiNode: wikiNodeMeta,
                                                               treeContext: treeContext,
                                                               params: params,
                                                               extraInfo: extraInfo)
        if let svc = fromVC.lkSplitViewController,
           !(svc.secondaryViewController?.children.contains(fromVC) ?? false) {
            userResolver.navigator.docs.showDetailOrPush(vc, wrap: LkNavigationController.self, from: fromVC, animated: true, completion: completion)
        } else {
            userResolver.navigator.push(vc, from: fromVC, animated: true, completion: completion)
        }
        return vc
    }

    /// 跳转到知识库详情页面
    /// - Parameter space: 要跳转的知识库
    static func goToSpaceDetail(userResolver: UserResolver,
                                space: WikiSpace,
                                fromVC: UIViewController) {
        let viewModel = WikiSpaceDetailViewModel(space: space)
        let detailVC = WikiSpaceDetailViewController(viewModel: viewModel)
        if fromVC.isMyWindowRegularSizeInPad {
            detailVC.modalPresentationStyle = .formSheet
            fromVC.present(detailVC, animated: true, completion: nil)
        } else {
            userResolver.navigator.push(detailVC, from: fromVC)
        }
    }
}

extension WikiRouter {
    static func goToMigrationTip(userResolver: UserResolver, from: UIViewController) {
        do {
            let finalURL = try HelpCenterURLGenerator.generateURL(article: .wikiRouterHelpCenter)
            if let svc = from.lkSplitViewController,
               !(svc.secondaryViewController?.children.contains(from) ?? false) {
                userResolver.navigator.docs.showDetailOrPush(finalURL, wrap: LkNavigationController.self, from: from)
            } else {
                userResolver.navigator.push(finalURL, from: from)
            }
        } catch {
            DocsLogger.error("failed to generate helper center URL when linkButtonAction from secret banner", error: error)
        }
    }
}

public class WikiRouterBaseAPI: WikiRouterBaseAPIProtocol {
    
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public func gotoWikiDetail(_ wikiNodeMeta: SpaceInterface.WikiNodeMeta,
                               extraInfo: [AnyHashable : Any],
                               fromVC: UIViewController,
                               treeContext: SKWorkspace.WikiTreeContext? = nil,
                               completion: EENavigator.Completion? = nil) {
        WikiRouter.gotoWikiDetail(wikiNodeMeta,
                                  userResolver: userResolver,
                                  extraInfo: extraInfo,
                                  fromVC: fromVC,
                                  treeContext: treeContext,
                                  completion: completion)
    }
    
}
