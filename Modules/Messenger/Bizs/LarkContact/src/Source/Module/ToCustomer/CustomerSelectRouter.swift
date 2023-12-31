//
//  CustomerSelectRouter.swift
//  LarkContact
//
//  Created by lichen on 2018/9/17.
//

import UIKit
import Foundation
import LarkUIKit
import LarkFoundation
import LarkContainer
import LarkModel
import RxSwift
import RxCocoa
import LKCommonsLogging
import Swinject
import EENavigator
import LarkMessengerInterface
import LarkNavigation
import AnimatedTabBar
import LarkTab

protocol CustomerSelectRouter: AnyObject {
    func openMyGroups(navigationController: UINavigationController)
}

final class CustomerSelectRouterImpl {
    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }
}

extension CustomerSelectRouterImpl: CustomerSelectRouter {
    func openMyGroups(navigationController: UINavigationController) {
        let body = GroupsViewControllerBody(title: BundleI18n.LarkContact.Lark_Legacy_MyGroup)
        resolver.navigator.push(body: body, from: navigationController)
    }
}

extension CustomerSelectRouterImpl: GroupsViewControllerRouter {
    func didSelectBotWithGroup(_ vc: GroupsViewController, chat: Chat, fromWhere: ChatFromWhere = .profile) {
        vc.dismiss(animated: false, completion: nil)
        let body = ChatControllerByChatBody(chat: chat, fromWhere: fromWhere)

        var params = NaviParams()
        params.switchTab = Tab.feed.url
        resolver.navigator.push(body: body, naviParams: params, from: vc)
    }
}
