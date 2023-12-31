//
//  FeedCardActionAdapter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/6/7.
//

import UIKit
import LarkFeatureGating
import LarkMessengerInterface
import LarkModel
import LarkOpenFeed
import LarkSceneManager
import LarkSDKInterface
import LarkSwipeCellKit
import LarkZoomable
import RustPB
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignDialog

extension LabelMainListTableAdapter: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        guard let feed = vm.viewDataStateModule.getFeed(indexPath: indexPath)?.feedViewModel,
              let label = vm.viewDataStateModule.getLabel(section: indexPath.section) else {
            return SwipeOptions()
        }
        let event: FeedActionEvent = orientation == .left ? .rightSwipe : .leftSwipe
        let actionItems = getActionItems(cellVM: feed, label: label, event: event)
        return swipeActionPlugin.configSwipeOptions(orientation: orientation, actionItems: actionItems)
    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard let feed = vm.viewDataStateModule.getFeed(indexPath: indexPath)?.feedViewModel,
              let label = vm.viewDataStateModule.getLabel(section: indexPath.section) else {
            return nil
        }

        let event: FeedActionEvent = orientation == .left ? .rightSwipe : .leftSwipe
        let actionItems = getActionItems(cellVM: feed, label: label, event: event)
        if case SwitchModeModule.Mode.threeBarMode = vm.switchModeModule.mode {
            return FeedActionViewUtil.transformToSwipeAction(items: actionItems, showIcon: true)
        } else {
            return FeedActionViewUtil.transformToSwipeAction(items: actionItems, showIcon: false)
        }
    }

    func visibleRect(for tableView: UITableView) -> CGRect? {
        swipeActionPlugin.visibleRect(for: tableView)
    }

    /// Cell即将开始动画时: 当操作Cell标记，置顶时，如果不挂起队列，Push更新很快就到了
    /// 会同时触发一次Cell的刷新，此时Cell可能在做左右滑动/收起的动画，会出现动画跳动。
    /// 原本预期的是Cell处于编辑态时，不阻塞刷新，但是因为上面这个原因，
    /// 也只能挂起队列，后续可做的优化是监听Cell左右滑动动画的开始结束状态，只在这开始结束操作队列即可
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {
        swipingCell = tableView.cellForRow(at: indexPath) as? SwipeTableViewCell
        if orientation == .right {
            // 这里有个特化，操作已完成时，不能挂起队列，因为已完成的删除动画是通过removeFeeds触发的
            self.page?.vm.dataModule.dataQueue.frozenDataQueue(.cellEdit)
        }
        swipeActionPlugin.willBeginEditing(tableView: tableView, indexPath: indexPath, orientation: orientation)

        if orientation == .right {
            FeedTracker.Main.Click.Leftslide(filter: .tag, vm.dependency.iPadStatus)
        } else {
            FeedTracker.Main.Click.Rightslide(filter: .tag, vm.dependency.iPadStatus)
        }
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
        if orientation == .right {
            // 这里有个特化，操作已完成时，不能挂起队列，因为已完成的删除动画是通过removeFeeds触发的
            // 延迟0.2s释放队列，否则还是会出现动画跳动(因为该方法回调较早)
            DispatchQueue.main.asyncAfter(deadline: .now() + LabelActionCons.delaySecond) {
                self.page?.vm.dataModule.dataQueue.resumeDataQueue(.cellEdit)
            }
        }
        swipeActionPlugin.didEndEditing(tableView: tableView, indexPath: indexPath, orientation: orientation)
    }
}

// MARK: 长按菜单
extension LabelMainListTableAdapter {
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard longPressActionPlugin.isSupportLongPress else { return nil }
        guard let page = self.page,
              let label = vm.viewDataStateModule.getLabel(section: indexPath.section),
              let feed = vm.viewDataStateModule.getFeed(indexPath: indexPath) else {
                  return nil
              }
        var actions: [UIAction] = []
        if let cell = tableView.cellForRow(at: indexPath) as? FeedSwipingCellInterface,
           cell.isSwiping {
            return nil
        }
        FeedTracker.Main.Click.FeedPress(vm.dependency.iPadStatus)
        let actionItems = getActionItems(cellVM: feed.feedViewModel, label: label, event: .longPress)
        actions = FeedActionViewUtil.transformToUIAction(items: actionItems)

        if actions.isEmpty {
            return nil
        }
        let identifier = indexPath as NSCopying
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
            return UIMenu(title: "", children: actions)
        }
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return longPressActionPlugin.highlightingMenu(tableView: tableView, configuration: configuration)
    }

    @available(iOS 14.0, *)
    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        /// menu 出现时对队列加锁
        self.page?.vm.dataModule.dataQueue.frozenDataQueue(.menuShow)
        longPressActionPlugin.willDisplayMenu(tableView: tableView, configuration: configuration, animator: animator)
    }

    @available(iOS 14.0, *)
    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        /// menu 消失时开启队列
        self.page?.vm.dataModule.dataQueue.resumeDataQueue(.menuShow)
        longPressActionPlugin.willEndMenu(tableView: tableView, configuration: configuration, animator: animator)
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return longPressActionPlugin.dismissMenu(tableView: tableView, configuration: configuration)
    }

    enum LabelActionCons {
        static let delaySecond: CGFloat = 0.2
    }
}

// MARK: - FeedActionService
extension LabelMainListTableAdapter {
    func getActionItems(cellVM: FeedCardViewModelInterface, label: LabelViewModel, event: FeedActionEvent) -> [FeedActionBaseItem] {
        guard let feedAction = self.page?.actionHandlerAdapter.feedActionService else { return [] }
        let model = FeedActionModel(feedPreview: cellVM.feedPreview,
                                    channel: cellVM.bizData.shortcutChannel,
                                    event: event,
                                    groupType: .tag,
                                    bizType: .label,
                                    labelId: Int64(label.item.id),
                                    fromVC: self.page,
                                    basicData: cellVM.basicData,
                                    bizData: cellVM.bizData,
                                    extraData: [:])
        let supplementTypes = feedAction.getSupplementTypes(model: model, event: event)
        let bizTypes = feedAction.getBizTypes(model: model, event: event, useSetting: true)
        let actionItems = feedAction.transformToActionItems(model: model, types: bizTypes + supplementTypes, event: event)
        subscribeActionStatus(actionItems: actionItems, model: model, label: label)
        return actionItems
    }

    private func subscribeActionStatus(actionItems: [FeedActionBaseItem], model: FeedActionModel, label: LabelViewModel) {
        let needSubscribeItems = actionItems.filter({ [.debug, .done].contains($0.type) })
        needSubscribeItems.forEach { item in
            item.handler.actionStatus.subscribe(onNext: { status in
                switch item.type {
                case .debug:
                    if case .didHandle(_) = status {
                        FeedContext.log.info("feedlog/label/debug/feed: label: \(label.meta.description), feed: \(model.feedPreview.description)")
                    }
                case .done:
                    if case .willHandle = status {
                        // TODO: 待优化
                        // let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .markForDone)
                        // self.feedsViewModel.removeFeedsOfUnsafe([vm.feedPreview.id], renderType: .animate(.fade), trace: trace)
                    }
                default:
                    break
                }
            }).disposed(by: self.disposeBag)
        }
    }
}
