//
//  ChatFeedGuideDelegate.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/1.
//

import UIKit
import Foundation
import RustPB
import LarkModel
import LarkOpenFeed

/// Feed引导(At/At All/Badge)
/// 由于ChatFeedTableCell抽离成Plugin了，所以需要ChatFeedTableCell实现此代理
/// 提供引导必须的信息
public protocol ChatFeedGuideDelegate: AnyObject {
    var isChat: Bool { get }

    var hasAtInfo: Bool { get }

    var atInfo: FeedPreviewAt { get }

    var isRemind: Bool { get }

    var unreadCount: Int { get }

    var atView: UIView? { get }

    var badgeView: UIView? { get }

    func routerToNextPage(from: UIViewController, context: FeedContextService?)
}
