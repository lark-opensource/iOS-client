//
//  FeedCardSwipeActionPlugin.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/6/8.
//

import Foundation
import LarkSwipeCellKit
import RustPB
import RxSwift
import RxCocoa
import LarkZoomable
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignToast
import UIKit
import LarkModel
import LarkFeatureGating
import UniverseDesignIcon
import LarkOpenFeed
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignDialog
import LKCommonsLogging
import LarkPerf
import AppReciableSDK
import LKCommonsTracker
import Homeric
import EENavigator
import LarkUIKit

// MARK: 滑动操作
final class FeedCardSwipeActionPlugin {
    let filterType: Feed_V1_FeedFilter.TypeEnum
    let userResolver: UserResolver
    // 缓存 避免重复计算
    static var leftOrientation: SwipeOptions?
    static var rightOrientation: SwipeOptions?
    init(filterType: Feed_V1_FeedFilter.TypeEnum,
         userResolver: UserResolver) {
        self.filterType = filterType
        self.userResolver = userResolver
    }

    // 微调左右滑动的样式
    func configSwipeOptions(orientation: SwipeActionsOrientation, actionItems: [FeedActionBaseItem]) -> SwipeOptions {
        guard !actionItems.isEmpty else { return SwipeOptions() }
        if orientation == .left, let leftOrientation = Self.leftOrientation {
            return leftOrientation
        } else if orientation == .right, let rightOrientation = Self.rightOrientation {
            return rightOrientation
        }
        let options: SwipeOptions = FeedActionViewUtil.verticalOptions(orientation: orientation,
                                                                       actionItems: actionItems)

        if orientation == .left {
            Self.leftOrientation = options
        } else {
            Self.rightOrientation = options
        }
        return options
    }

    func visibleRect(for tableView: UITableView) -> CGRect? {
        return tableView.safeAreaLayoutGuide.layoutFrame
    }

    /// Cell即将开始动画时: 当操作Cell标记，置顶时，如果不挂起队列，Push更新
    /// 很快就到了，会同时触发一次Cell的刷新，此时Cell可能在做左右滑动/收起的动画，会出现动画跳动。
    /// 原本预期的是Cell处于编辑态时，不阻塞刷新，但是因为上面这个原因，
    /// 也只能挂起队列，后续可做的优化是监听Cell左右滑动动画的开始结束状态，只在这开始结束操作队列即可
    func willBeginEditing(tableView: UITableView, indexPath: IndexPath, orientation: SwipeActionsOrientation) {
        if FeedSelectionEnable {
            let cell = tableView.cellForRow(at: indexPath)
            cell?.setBackViewLayout(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), 0)
        }
    }

    /// 动画完成: 延迟0.2s释放队列，否则还是会出现动画跳动(因为该方法回调较早)
    func didEndEditing(tableView: UITableView, indexPath: IndexPath?, orientation: SwipeActionsOrientation) {
        if FeedSelectionEnable, let indexPath = indexPath {
            let cell = tableView.cellForRow(at: indexPath)
            cell?.setBackViewLayout(UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6), 6)
        }
    }

    enum Cons {
        static let swipeEdgeInset: CGFloat = 120
        static let swipeOverscroll: CGFloat = 150
        static let swipeButtonHorizontalPadding: CGFloat = 16
        static let swipeTriggerRate: CGFloat = 1.4
    }
}

final class FeedBorderTransitionLayout: SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {}

    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext) {
        if context.contentWidths.indices.contains(index) {
            let sum = context.contentWidths.reduce(0, +)
            var proportion: CGFloat = 0
            for (contentIndex, item) in context.contentWidths.enumerated() {
                if contentIndex >= index {
                    break
                }
                proportion += item / sum
            }
            view.frame.origin.x = (context.contentSize.width * proportion) * context.orientation.scale
        } else {
            let diff = context.visibleWidth - context.contentSize.width
            view.frame.origin.x = (CGFloat(index) * context.contentSize.width / CGFloat(context.numberOfActions) + diff) * context.orientation.scale
        }
    }

    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {
        // visible widths are all the same regardless of the action view position
        return context.contentWidths
    }
}
