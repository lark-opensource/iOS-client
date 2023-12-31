//
//  ProfileRouter.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/4/19.
//

import Foundation
import EENavigator

class ProfileRouter {
    let navigator: Navigatable
    private var routerProvider: RouterProxy?

    init(routerProvider: RouterProxy?, navigator: Navigatable) {
        self.routerProvider = routerProvider
        self.navigator = navigator
    }

    func openUserProfile(userId: String, fromVC: UIViewController) {
        routerProvider?.openUserProfile(userId: userId, fromVC: fromVC)
    }

    func openNameCard(accountId: String, address: String, name: String, fromVC: UIViewController, callBack: ((Bool) -> Void)? = nil) {
        if let saveCallBack = callBack {
            routerProvider?.openNameCard(accountId: accountId, address: address, name: name, fromVC: fromVC, callBack: saveCallBack)
        } else {
            routerProvider?.openNameCard(accountId: accountId, address: address, name: name, fromVC: fromVC, callBack: { _ in
            })
        }
    }
}
