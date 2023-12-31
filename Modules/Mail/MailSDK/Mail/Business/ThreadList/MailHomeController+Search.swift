//
//  MailHomeController+Search.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/8.
//

import Foundation
import LarkUIKit
import EENavigator
import Homeric
#if MessengerMod
import LarkMessengerInterface
#endif

extension MailHomeController {
    var searchBarInherentHeight: CGFloat {
        return 0
    }

    func onSelectSearch() {
        guard !labelsMenuShowing else { return }
//		    #if MessengerMod
//        let body = SearchMainBody(topPriorityScene: .rustScene(.mail), sourceOfSearch: "mail")
//        navigator.push(body: body, from: self)
//				return
//        #endif
        MailTracker.log(event: Homeric.EMAIL_SEARCH_ENTER, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .searchBar)])
        let mailSearchVC = MailSearchViewController(accountContext: userContext.getCurrentAccountContext(), config: MailSearchConfig())
        mailSearchVC.delegate = self
        if rootSizeClassIsRegular {
            enterThread(with: nil)
        }
        //let nav = /*LkNavigationController*/(rootViewController: mailSearchVC)
        navigator?.push(mailSearchVC, from: self)
    }
}

extension MailHomeController: MailSearchViewControllerDelegate {
    func didCancelMailSearch() {
        if rootSizeClassIsRegular {
            enterThread(with: markSelectedThreadId)
        }
    }
}

extension MailHomeController: UIViewControllerTransitioningDelegate, CustomNaviAnimation {
    var naviBarView: UIView {
        return getLarkNavbar() ?? UIView()
    }

    var animationProxy: CustomNaviAnimation? {
        animatedTabBarController as? CustomNaviAnimation
    }

    func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarPresentTransition()
    }

    func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarDismissTransition()
    }
}

extension MailTabBarController: UIViewControllerTransitioningDelegate, CustomNaviAnimation {

    var mailHomeVC: MailHomeController? {
        return content as? MailHomeController
    }
    public var animationProxy: CustomNaviAnimation? {
        animatedTabBarController as? CustomNaviAnimation
    }

    var naviBarView: UIView {
        return mailHomeVC?.getLarkNavbar() ?? UIView()
    }

    public func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarPresentTransition()
    }

    public func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarDismissTransition()
    }
}
