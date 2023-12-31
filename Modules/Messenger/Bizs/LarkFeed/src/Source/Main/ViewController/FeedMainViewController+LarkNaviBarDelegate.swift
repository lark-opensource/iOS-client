//
//  FeedMainViewController+LarkNaviBarDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import LarkMessengerInterface

extension FeedMainViewController: LarkNaviBarDelegate {

    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search:
            pushSearchController()
        case .first:
            presentProcessor.processIfNeeded(type: .floatAction, source: button.defaultSource)
        default:
            break
        }
    }

    func onDefaultAvatarTapped() {
        FeedTracker.Navigation.Click.Avatar()

        guard let naviBar: NaviBarProtocol = self.naviBar as? NaviBarProtocol else {
            let errorMsg = "avatarTap, avatarDotBadge naviBar is nil!"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.Navi.action(node: .onDefaultAvatarTapped, info: info)
            return
        }

        let newRegisterGuideEnbale = mainViewModel.newRegisterGuideEnbale
        let showNewRegisterGuide = mainViewModel.needShowGuide(key: .feedNaviBarDotGuide)
        // 关闭红点UI信号
        naviBar.avatarDotBadgeShow.onNext(false)
        if newRegisterGuideEnbale {
            // 上报「新用户红点」引导消费
            mainViewModel.didShowGuide(key: .feedNaviBarDotGuide)
        }

        FeedContext.log.info("feedlog/navi/action/avatarTap. avatarDotBadge close newRegisterGuideEnbale: \(newRegisterGuideEnbale), showNewRegisterGuide: \(showNewRegisterGuide)")
    }
}
