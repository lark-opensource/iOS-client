//
//  FeedMainViewController+NewRegisterGuide.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import LarkUIKit

/// 新注册用户引导(头像红点)
extension FeedMainViewController {

    func observeNewRegisterGuide() {
        guard mainViewModel.newRegisterGuideEnbale else {
            FeedContext.log.info("feedlog/guide/newRegister. newRegisterGuideEnbale not enabled")
            return
        }

        onViewAppeared.asDriver().skip(1).drive(onNext: { [weak self] appeared in
            guard let self = self else { return }
            let showNewRegisterGuide: Bool = self.mainViewModel.needShowGuide(key: .feedNaviBarDotGuide)
            FeedContext.log.info("feedlog/guide/newRegister. avatarDotBadge appeared = \(appeared), showNewRegisterGuide = \(showNewRegisterGuide)")
            guard let naviBar: NaviBarProtocol = self.naviBar as? NaviBarProtocol,
                  appeared,
                  showNewRegisterGuide
            else { return }
            naviBar.avatarDotBadgeShow.onNext(showNewRegisterGuide)
        }).disposed(by: disposeBag)
    }
}
