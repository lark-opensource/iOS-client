//
//  WikiRouterBaseAPI.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/7/11.
//

import Foundation
import SpaceInterface
import EENavigator


public protocol WikiRouterBaseAPIProtocol {
    func gotoWikiDetail(_ wikiNodeMeta: WikiNodeMeta,
                        extraInfo: [AnyHashable: Any],
                        fromVC: UIViewController,
                        treeContext: WikiTreeContext?,
                        completion: Completion?)
}
