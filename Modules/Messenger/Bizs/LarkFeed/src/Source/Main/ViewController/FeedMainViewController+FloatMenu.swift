//
//  FeedMainViewController+FloatMenu.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import LarkAppConfig
import LarkMessengerInterface
import LarkAccountInterface
import LarkFoundation
import LarkOpenFeed

extension FeedMainViewController {

    func presentFromFloatAction(source: PopoverSource?,
                                dismissAction: @escaping () -> Void,
                                completion: @escaping (FeedPresentAnimationViewController) -> Void) {
        FeedTracker.Plus.View()
        let menuContext = mainViewModel.moduleContext.floatMenuContext
        FeedFloatMenuModule.onLoad(context: menuContext)
        let floatMenuView = FeedFloatMenuView(menuModule: FeedFloatMenuModule(context: menuContext))
        present(source: source, compactVC: {
            let maskVC = FeedFloatMenuMaskViewController(menuView: floatMenuView)
            maskVC.menuView.delegate = self
            maskVC.dismissAction = dismissAction
            return maskVC
        }, regularVC: {
            let popoverVC = FeedFloatMenuPopoverViewController(menuView: floatMenuView)
            popoverVC.menuView.delegate = self
            return popoverVC
        }, completion: completion)
    }
}

extension FeedMainViewController: FloatMenuDelegate {
    func floatMenu(_ menuView: FeedFloatMenuView, select type: FloatMenuOptionType) {
        presentProcessor.dismissCurrentIfNeeded(animate: false, checkType: .floatAction) {
            menuView.didClick(type)
        }
    }
}
