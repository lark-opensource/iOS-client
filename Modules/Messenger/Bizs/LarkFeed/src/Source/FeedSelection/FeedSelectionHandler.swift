//
//  FeedSelectionHandler.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/4.
//

import Foundation
import EENavigator
import LarkMessengerInterface
import AnimatedTabBar
import LarkNavigation
import LarkTab
import LKCommonsLogging
import Swinject
import LarkNavigator
// feed 选中实现

// 旧方案：
// 1. 首先需要向路由注入观察者
// 2. 在场景处使用路由跳转时，需要构造context
// 3. 观察者监听到跳转事件，发送选中信号
// 4. feed 监听，进行刷新并选中cell
final class FeedSelectionHandler: UserMiddlewareHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }

    func handle(req: Request, res: Response) throws {
        guard let feedSelection = req.context[FeedSelection.contextKey] as? FeedSelection else { return }
        let feedSelectionService = try userResolver.resolve(assert: FeedSelectionService.self)
        if FeedSelectionEnable {
            FeedContext.log.info("feedlog/selection/send. \(feedSelection.feedId)")
            feedSelectionService.setSelected(feedId: feedSelection.feedId)
        }
        feedSelectionService.setSelectedFeed(selection: feedSelection)
    }
}

// 新方案：用于监听 Feed Tab 在 iPad 上执行 showDetail 操作，是否需要更新 feed 选中状态
// 1. 首先需要向路由注入中间件
// 2. 业务vc实现协议 FeedSelectionInfoProvider
// 2. 观察者监听到跳转事件，发送选中信号
// 4. feed 监听，进行刷新并选中cell
final class FeedSelectionObserver: UserMiddlewareHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(req: Request, res: Response) throws {
        /// 判断 enable
        guard FeedSelectionEnable else {
            return
        }
        /// 判断 openType 只处理 showDetail
        guard let openType = req.context.openType(),
              openType == .showDetail else {
            return
        }

        /// 判断 from vc
        guard let from = req.from.fromViewController,
              let tab = from.animatedTabBarController else {
            return
        }

        /// 判断是否在 Feed Tab 上
        var isInFeedTab = false
        if let toTab = req.context.naviParams?.switchTab,
           toTab == Tab.feed.url {
            isInFeedTab = true
        } else if tab.currentTab == Tab.feed {
            isInFeedTab = true
        }

        guard isInFeedTab else {
            return
        }
        guard
            let feedSelectionService = try? userResolver.resolve(assert: FeedSelectionService.self)
        else { return }

        FeedContext.log.info("feedlog/selection/check. feed selection")
        /// 判断 response 状态 以及是否实现 FeedSelectionInfoProvider 协议
        if res.status == .ended,
           let source = res.resource as? FeedSelectionInfoProvider,
           let feedID = source.getFeedIdForSelected() {
            FeedContext.log.info("feedlog/selection/check. feedId: \(feedID)")
            feedSelectionService.setSelected(feedId: feedID)
        } else if res.status == .pending,
            let async = res.resource as? AsyncResult {
            async.add { (result) in
                if let source = result.resource as? FeedSelectionInfoProvider,
                   let feedID = source.getFeedIdForSelected() {
                    FeedContext.log.info("feedlog/selection/check. feedId: \(feedID)")
                    feedSelectionService.setSelected(feedId: feedID)
                }
            }
        }
    }
}
