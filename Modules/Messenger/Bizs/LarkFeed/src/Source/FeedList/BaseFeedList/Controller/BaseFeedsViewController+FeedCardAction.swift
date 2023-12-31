//
//  BaseFeedsViewController+FeedCardAction.swift
//  LarkFeed
//
//  Created by bytedance on 2020/6/7.
//

import UIKit
import LarkFeatureGating
import LarkMessengerInterface
import LarkModel
import LarkOpenFeed
import LarkSceneManager
import LarkSDKInterface
import LarkSplitViewController
import LarkSwipeCellKit
import LarkZoomable
import RustPB
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast

extension BaseFeedsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard let cell = tableView.cellForRow(at: indexPath),
              let cellViewModel = feedsViewModel.cellViewModel(indexPath) else {
            return nil
        }

        let event: FeedActionEvent = orientation == .left ? .rightSwipe : .leftSwipe
        let actionItems = getActionItems(vm: cellViewModel, event: event)
        return FeedActionViewUtil.transformToSwipeAction(items: actionItems)
    }

    // 微调左右滑动的样式
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        if orientation == .left, let leftOrientation = Self.leftOrientation {
            return leftOrientation
        } else if orientation == .right, let rightOrientation = Self.rightOrientation {
            return rightOrientation
        }
        let event: FeedActionEvent = orientation == .left ? .rightSwipe : .leftSwipe
        guard let cellViewModel = feedsViewModel.cellViewModel(indexPath) else { return SwipeOptions() }
        let actionItems = getActionItems(vm: cellViewModel, event: event)
        guard !actionItems.isEmpty else { return SwipeOptions() }

        let options = FeedActionViewUtil.verticalOptions(orientation: orientation,
                                                         actionItems: actionItems)

        if orientation == .left {
            Self.leftOrientation = options
        } else {
            Self.rightOrientation = options
        }
        return options
    }

    /// Cell即将开始动画时: 当操作Cell标记，置顶时，如果不挂起队列，Push更新
    /// 很快就到了，会同时触发一次Cell的刷新，此时Cell可能在做左右滑动/收起的动画，会出现动画跳动。
    /// 原本预期的是Cell处于编辑态时，不阻塞刷新，但是因为上面这个原因，
    /// 也只能挂起队列，后续可做的优化是监听Cell左右滑动动画的开始结束状态，只在这开始结束操作队列即可
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {
        swipingCell = tableView.cellForRow(at: indexPath) as? SwipeTableViewCell
        if FeedSelectionEnable {
            let cell = tableView.cellForRow(at: indexPath)
            cell?.setBackViewLayout(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), 0)
        }
        // 这里有个特化，操作已完成时，不能挂起队列，因为已完成的删除动画是通过removeFeeds触发的
        if orientation == .right {
            feedsViewModel.changeQueueState(true, taskType: .cellEdit)
            FeedTracker.Main.Click.Leftslide(filter: self.feedsViewModel.getFilterType(), iPadStatus)
        } else {
            FeedTracker.Main.Click.Rightslide(filter: self.feedsViewModel.getFilterType(), iPadStatus)
        }
    }

    /// 动画完成: 延迟0.2s释放队列，否则还是会出现动画跳动(因为该方法回调较早)
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
        if FeedSelectionEnable, let indexPath = indexPath {
            let cell = tableView.cellForRow(at: indexPath)
            cell?.setBackViewLayout(UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6), 6)
        }

        // 这里有个特化，操作已完成时，不能挂起队列，因为已完成的删除动画是通过removeFeeds触发的
        guard orientation == .right else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + FeedActionCons.delaySecond) {
            self.feedsViewModel.changeQueueState(false, taskType: .cellEdit)
        }
    }

    /// 加入长按和右键的菜单
    /// ContextMenu的图片显示区域为24pt*31.5pt(fit)
    /// 图片是设计给好的24pt*24pt图，所以没有用代码调整
    /// 如果要调整图片记得让设计加上24pt*24pt的底板，或者用代码手动调整
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        /// 由于 iOS 13 没有 willDisplayContextMenu 和 willEndContextMenuInteraction 的回调函数。将里边逻辑进行移动。
        /// 移动这两个函数里边的逻辑会导致会话卡死。https://meego.feishu.cn/larksuite/issue/detail/4883932
        /// 最后结论，逻辑迁移回原来位置，初始化只支持 iOS 14 以上的设备。
        /// case study : https://bytedance.feishu.cn/docx/doxcn6UGgTRR7HahbOHH9xwJxzh
        guard #available(iOS 14.0, *) else {
            return nil
        }
        guard let cellViewModel = feedsViewModel.cellViewModel(indexPath),
              let cell = tableView.cellForRow(at: indexPath) as? FeedCardCellInterface,
              !cell.isSwiping else {
            return nil
        }

        FeedTracker.Main.Click.FeedPress(iPadStatus)
        var actions: [UIAction] = []
        let actionItems = getActionItems(vm: cellViewModel, event: .longPress)
        actions = FeedActionViewUtil.transformToUIAction(items: actionItems)

        // 其他 action
        // 创建 scene
        if SceneManager.shared.supportsMultipleScenes,
           let scene = cell.supportDragScene() {
            scene.sceneSourceID = self.currentSceneID()
            scene.createWay = "menu_click"
            let scenebtnItem = SceneButtonItem(clickCallBack: nil, sceneKey: "", sceneId: "")
            let image = scenebtnItem.getSceneIcon(targetVC: self)
            let isEnabled = scenebtnItem.getState(scene: scene)
            let createScene = UIAction(
                title: BundleI18n.LarkFeed.Lark_Core_OpenInNewWindow,
                image: isEnabled ? image : image.withTintColor((UIColor.ud.iconDisabled)),
                attributes: isEnabled ? [] : .disabled) { [weak self] _ in
                SceneManager.shared.active(
                    scene: scene,
                    from: self) { [weak self] (_, error) in
                    guard let self = self else {
                        return
                    }
                    if error != nil {
                        UDToast.showTips(
                            with: BundleI18n.LarkFeed.Lark_Core_SplitScreenNotSupported,
                            on: self.view
                        )
                    }
                }
            }
            actions.append(createScene)
        }
        if actions.isEmpty {
            return nil
        }
        let identifier = indexPath as NSCopying
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in

            return UIMenu(title: "", children: actions)
        }
    }

    // 定制 ContextMenu Preview，不定制会有操作白屏的现象
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetPreview(for: tableView, with: configuration)
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetPreview(for: tableView, with: configuration)
    }

    @available(iOS 14.0, *)
    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        FeedTracker.Press.View()
        /// menu 出现时对队列加锁
        self.feedsViewModel.changeQueueState(true, taskType: .menuShow)
    }

    @available(iOS 14.0, *)
    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        /// menu 消失时开启队列
        self.feedsViewModel.changeQueueState(false, taskType: .menuShow)
    }

    @available(iOS 13.0, *)
    func targetPreview(for tableView: UITableView, with configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath),
              tableView.window != nil else { return nil }
        cell.setHighlighted(false, animated: true)
        guard let copy = cell.snapshotView(afterScreenUpdates: true) else {
            return nil
        }
        // 再次判断tableView是否在window上，防止copy导致问题
        guard tableView.window != nil else { return nil }
        return UITargetedPreview(view: copy, parameters: UIPreviewParameters(),
                                 target: UIPreviewTarget(container: tableView, center: cell.center))
    }

    func visibleRect(for tableView: UITableView) -> CGRect? {
        tableView.safeAreaLayoutGuide.layoutFrame
    }

    enum FeedActionCons {
        static let swipeEdgeInset: CGFloat = 120.0
        static let swipeOverscroll: CGFloat = 150.0
        static let swipeButtonHorizontalPadding: CGFloat = 16.0
        static let swipeTriggerRate: CGFloat = 1.4
        static let delaySecond: CGFloat = 0.2
        static let swipeButtonWidth: CGFloat = 84.0
        static let titleMaxHeight: CGFloat = 32
    }
}

// MARK: - FeedActionService
extension BaseFeedsViewController {
    func getActionItems(vm: FeedCardCellViewModel, event: FeedActionEvent) -> [FeedActionBaseItem] {
        guard let feedAction = feedActionService else { return [] }
        let model = FeedActionModel(feedPreview: vm.feedPreview,
                                    channel: vm.bizData.shortcutChannel,
                                    event: event,
                                    groupType: vm.filterType,
                                    bizType: vm.bizType,
                                    fromVC: self,
                                    basicData: vm.basicData,
                                    bizData: vm.bizData,
                                    extraData: [:])
        let supplementTypes = feedAction.getSupplementTypes(model: model, event: event)
        let bizTypes = feedAction.getBizTypes(model: model, event: event, useSetting: true)
        let actionItems = feedAction.transformToActionItems(model: model, types: bizTypes + supplementTypes, event: event)
        subscribeActionStatus(actionItems: actionItems, vm: vm, event: event, model: model)
        return actionItems
    }

    private func subscribeActionStatus(actionItems: [FeedActionBaseItem], vm: FeedCardCellViewModel, event: FeedActionEvent, model: FeedActionModel) {
        let needSubscribeItems = actionItems.filter({ [.debug, .done, .flag].contains($0.type) })
        needSubscribeItems.forEach { [weak self] item in
            guard let self = self else { return }
            item.handler.actionStatus.subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                switch item.type {
                case .debug:
                    if case .didHandle(_) = status {
                        FeedContext.log.info("feedlog/dataStream/debug. \(self.feedsViewModel.listContextLog), "
                                             + "\(self.trace.description), \(vm.feedPreview.description)")
                    }
                case .done:
                    if case .willHandle = status {
                        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .markForDone)
                        self.feedsViewModel.removeFeedsOfUnsafe([vm.feedPreview.id], renderType: .animate(.fade), trace: trace)
                    } else if case .didHandle(_) = status {
                        // iPad: 自动选中下一 Feed
                        self.selectNextFeedIfNeeded(feedId: vm.feedPreview.id)
                    }
                case .flag:
                    if case .didHandle(_) = status {
                        self.markForFlagAction(vm: vm)
                    }
                default:
                    break
                }
            }).disposed(by: self.disposeBag)
        }
    }
}
