//
//  FeedTeamViewController+SwipeTableViewCellDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/19.
//

import UIKit
import Foundation
import LarkSwipeCellKit
import RustPB
import RxSwift
import LarkZoomable
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import LarkOpenFeed

extension FeedTeamViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath),
              let feedCell = cell as? FeedTeamChatCell else {
            return nil
        }
        guard let cellViewModel = feedCell.viewModel else { return nil }

        guard let team = viewModel.teamUIModel.getTeam(section: indexPath.section) else { return nil }
        let actionItems = self.getActionItems(team: team, feed: cellViewModel, event: .leftSwipe)
        return FeedActionViewUtil.transformToSwipeAction(items: actionItems, showIcon: false)
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        if orientation == .right, let rightOrientation = Self.rightOrientation {
            return rightOrientation
        }
        var options = SwipeOptions()

        let style = SwipeExpansionStyle(target: .edgeInset(TeamActionCons.swipeEdgeInset),
                                        additionalTriggers: [.overscroll(TeamActionCons.swipeOverscroll)],
            elasticOverscroll: true,
            completionAnimation: .fill(.manual(timing: .after)))

        options.expansionStyle = orientation == .left ? style : nil
        options.transitionStyle = orientation == .left ? .reveal : SwipeTransitionStyle.custom(FeedBorderTransitionLayout())
        options.buttonStyle = .horizontal
        options.buttonHorizontalPadding = TeamActionCons.swipeButtonHorizontalPadding
        options.buttonSpacing = 4
        options.maximumButtonWidth = TeamActionCons.swipeButtonWidth
        options.buttonWidthStyle = .auto

        options.shouldBegin = { (x, y) in
            return abs(y) * TeamActionCons.swipeTriggerRate < abs(x)
        }

        options.backgroundColor = orientation == .left ? UIColor.ud.T400 : .clear

        if orientation == .right {
            Self.rightOrientation = options
        }
        return options
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {
        if orientation == .right {
            viewModel.frozenDataQueue(.cellEdit)
        }
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
        guard orientation == .right else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + TeamActionCons.delaySecond) {
            self.viewModel.resumeDataQueue(.cellEdit)
        }
    }

    private func getActions(_ feedActionTypes: [FeedCardSwipeActionType],
                            _ indexPath: IndexPath,
                    _ cellViewModel: FeedTeamChatItemViewModel) -> [SwipeAction] {
        var actions: [SwipeAction] = []
        let feedPreview = cellViewModel.chatEntity
        for actionType in feedActionTypes {
            switch actionType {
            case .done: break
            case .shortcut: break
            case .flag: break
            case .hide:
                guard let team = viewModel.teamUIModel.getTeam(section: indexPath.section) else { break }
                guard let feedId = Int64(cellViewModel.chatEntity.id) else { break }
                guard feedId != team.teamEntity.defaultChatID else { break }
                let showState = !cellViewModel.chatItem.isHidden
                let title = showState ? BundleI18n.LarkFeed.Project_MV_HideRightNow : BundleI18n.LarkFeed.Project_MV_ShowNow
                let mark = SwipeAction(style: .default, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.viewModel.hideChat(cellViewModel, on: self.view.window)
                }
                let backgroundColor = showState ? UIColor.ud.R600 : UIColor.ud.colorfulIndigo
                mark.backgroundColor = backgroundColor
                let image = showState ? Resources.icon_visible_lock_outlined : Resources.icon_visible_outlined
                mark.image = image
                mark.hidesWhenSelected = true
                mark.textAlignment = .left
                mark.font = UIFont.ud.body1
                actions.append(mark)
            }
        }
        return actions
    }

    enum TeamActionCons {
        static let swipeEdgeInset: CGFloat = 120.0
        static let swipeOverscroll: CGFloat = 150.0
        static let swipeButtonHorizontalPadding: CGFloat = 12.0
        static let swipeTriggerRate: CGFloat = 1.4
        static let delaySecond: CGFloat = 0.2
        static let swipeButtonWidth: CGFloat = 84.0
    }
}
