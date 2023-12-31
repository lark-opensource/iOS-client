//
//  FeedActionViewUtil.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/7/20.
//

import LarkOpenFeed
import LarkSwipeCellKit
import LarkZoomable

final class FeedActionViewUtil {
    typealias FeedActionCons = BaseFeedsViewController.FeedActionCons
    @available(iOS 13.0, *)
    static func transformToUIAction(items: [FeedActionBaseItem]) -> [UIAction] {
        var actions: [UIAction] = []
        items.forEach { item in
            guard let viewModel = item.viewModel else { return }
            let action = UIAction(title: viewModel.title, image: viewModel.contextMenuImage) { _ in
                item.handler.executeTask()
            }
            actions.append(action)
        }
        return actions
    }

    static func transformToSwipeAction(items: [FeedActionBaseItem], showIcon: Bool = true) -> [SwipeAction] {
        var actions: [SwipeAction] = []
        items.forEach { item in
            guard let viewModel = item.viewModel else { return }
            let action = SwipeAction(style: .default, title: viewModel.title) { (_, _, _) in
                item.handler.executeTask()
            }
            action.backgroundColor = viewModel.swipeBgColor
            if showIcon {
                action.image = viewModel.swipeEditImage?.scaled(toPercentage: Zoom.currentZoom.scale)
            }
            action.hidesWhenSelected = true
            action.textAlignment = .center
            action.font = calculateFont(title: viewModel.title)
            actions.append(action)
        }
        return actions
    }

    static func verticalOptions(orientation: SwipeActionsOrientation, actionItems: [FeedActionBaseItem]) -> SwipeOptions {
        var options = SwipeOptions()

        options.buttonStyle = .vertical
        options.buttonHorizontalPadding = 4.0
        options.buttonSpacing = 4.0
        options.maximumButtonWidth = FeedActionCons.swipeButtonWidth
        options.minimumButtonWidth = FeedActionCons.swipeButtonWidth
        options.buttonWidthStyle = .auto
        options.buttonVerticalAlignment = .center

        // 优化Feed页左右/上下滑动触发机制, 调整角度使横向手势触发概率变小
        // 目前参数定制为拖拽角度小于 35 度触发 feed 菜单
        options.shouldBegin = { (x, y) in
            return abs(y) * FeedActionCons.swipeTriggerRate < abs(x)
        }
        if orientation == .left { // 右重滑
            if let type = actionItems.first?.type, type.swipeToDeleteRow {
                options.expansionStyle = SwipeExpansionStyle(target: .edgeInset(FeedActionCons.swipeEdgeInset),
                                                             additionalTriggers: [.overscroll(FeedActionCons.swipeOverscroll)],
                                                             elasticOverscroll: true,
                                                             completionAnimation: .fill(.manual(timing: .after)))
            } else {
                options.expansionStyle = SwipeExpansionStyle(target: .edgeInset(FeedActionCons.swipeEdgeInset),
                                                             additionalTriggers: [.overscroll(FeedActionCons.swipeOverscroll)],
                                                             elasticOverscroll: true,
                                                             completionAnimation: .bounce)
            }
            options.backgroundColor = actionItems.first?.viewModel?.swipeBgColor ?? .clear
            options.transitionStyle = .reveal
        } else {
            options.expansionStyle = nil
            options.transitionStyle = SwipeTransitionStyle.custom(FeedBorderTransitionLayout())
            options.backgroundColor = .clear
        }
        return options
    }

    private static func calculateFont(title: String) -> UIFont {
        if title.getTextWidth(font: UIFont.ud.body1, height: FeedActionCons.titleMaxHeight) <= FeedActionCons.swipeButtonWidth - 8 {
            return UIFont.ud.body1
        } else if title.getTextWidth(font: UIFont.ud.caption0, height: FeedActionCons.titleMaxHeight) <= FeedActionCons.swipeButtonWidth - 8 {
            return  UIFont.ud.caption0
        } else {
            return UIFont.ud.caption2
        }
    }
}
