//
//  FeedMainViewController+FeedBannerDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import LarkFeedBanner
import LarkUIKit

/// 依赖于Feed的UI，需要Feed提供实现
extension FeedMainViewController: FeedBannerDependency {
    // 升级团队关闭时，需要AvatarView做引导的cutoutView
    var naviAvatarView: UIView? {
        (self.naviBar as? NaviBarProtocol)?.getAvatarContainer()
    }
}
