//
//  FeedBannerDependency.swift
//  LarkFeedBanner
//
//  Created by 袁平 on 2020/6/28.
//

/// Banner对Feed的依赖，由Feed实现
import UIKit
public protocol FeedBannerDependency: AnyObject {
    var naviAvatarView: UIView? { get }
}
