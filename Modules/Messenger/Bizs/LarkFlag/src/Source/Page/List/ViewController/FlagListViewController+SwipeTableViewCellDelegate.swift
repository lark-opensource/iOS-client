//
//  FlagListViewController+SwipeTableViewCellDelegate.swift
//  LarkFeed
//
//  Created by Fan Hui on 2022/5/13.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSwipeCellKit
import LarkZoomable
import LarkSceneManager
import UniverseDesignToast
import RustPB
import ServerPB
import LarkModel
import RxSwift
import LarkMessageBase
import LarkSDKInterface
import LarkContainer
import LarkCore
import UniverseDesignIcon
import LarkOpenFeed
import LarkMessageCore

public enum FlagCellSwipeAction {
    case flag               // 标记
    case quickSwitcher      // 添加到置顶
    case forward            // 转发
}

public enum FlagCellLongPressAction {
    case flag               // 标记
    case quickSwitcher      // 添加到置顶
    case forward            // 转发
    case mute               // 免打扰
    case label
    case team
    case clearBadge
}

extension FlagListViewController: SwipeTableViewCellDelegate {
    enum ActionCons {
        static let swipeEdgeInset: CGFloat = 120.0
        static let swipeOverscroll: CGFloat = 150.0
        static let swipeTriggerRate: CGFloat = 1.4
        static let swipeButtonWidth: CGFloat = 84.0
        static let titleMaxHeight: CGFloat = 32.0
    }
    // 根据Index以及orientation（方向）返回相应cell的Action
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        guard indexPath.row < datasource.count else { return nil }
        let flagItem = datasource[indexPath.row]
        FlagTracker.Main.Swipe(flagItem, viewModel.dataDependency.iPadStatus)
        return getActions(flagItem, orientation: orientation)
    }

    // 根据Index以及orientation（方向）返回相应cell的Action相关属性，如是否销毁等
    public func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        if orientation == .right, let rightOrientation = Self.rightOrientation {
            return rightOrientation
        }
        let options: SwipeOptions = verticalOptions(orientation: orientation)

        if orientation == .right {
            Self.rightOrientation = options
        }
        return options
    }

    private func verticalOptions(orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()

        options.expansionStyle = nil
        options.transitionStyle = SwipeTransitionStyle.custom(FlagBorderTransitionLayout())
        options.buttonStyle = .vertical
        options.buttonHorizontalPadding = 4.0
        options.buttonSpacing = 4.0
        options.maximumButtonWidth = ActionCons.swipeButtonWidth
        options.minimumButtonWidth = ActionCons.swipeButtonWidth
        options.buttonWidthStyle = .auto
        options.buttonVerticalAlignment = .center

        // 优化Feed页左右/上下滑动触发机制, 调整角度使横向手势触发概率变小
        // 目前参数定制为拖拽角度小于 35 度触发 feed 菜单
        options.shouldBegin = { (x, y) in
            return abs(y) * ActionCons.swipeTriggerRate < abs(x)
        }
        options.backgroundColor = .clear
        return options
    }

    // MARK: Helpers
    func getActions(_ flagItem: FlagItem, orientation: SwipeActionsOrientation) -> [SwipeAction] {
        var flagActions: [FlagCellSwipeAction] = []
        if flagItem.type == .message {
            if let messageVM = flagItem.messageVM, let chat = messageVM.chat, chat.role == .member, messageVM.message.isRecalled == false,
               !messageVM.message.isCleaned,
               let chatSecurityControlService = self.chatSecurityControlService,
               chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                       message: messageVM.message,
                                                                       anonymousId: chat.anonymousId).authorityAllowed {
                if messageVM.message.type == .audio || messageVM.message.type == .vote {
                    flagActions = [.flag]
                } else {
                    flagActions = [.flag, .forward]
                }
            } else {
                // 不在群组内的话先不支持转发，消息没有接收权限也不支持转发
                flagActions = [.flag]
            }
        } else if flagItem.type == .feed {
            if let feedVM = flagItem.feedVM {
                let event: FeedActionEvent = orientation == .left ? .rightSwipe : .leftSwipe
                let actionItems = getActionItems(vm: feedVM, event: event)
                return self.transformToSwipeAction(items: actionItems)
            } else {
                flagActions = viewModel.isShortCutOn ? [.flag, .quickSwitcher] : [.flag]
            }
        }
        var actions: [SwipeAction] = []
        for action in flagActions {
            switch action {
            case .flag:
                let title = BundleI18n.LarkFlag.Lark_IM_MarkAMessageToArchive_CancelButton
                let mark = SwipeAction(style: .default, title: title) { [weak self] (_, _, _) in
                    guard let self = self else {
                        return
                    }
                    // 出现在标记列表里面的item肯定是已经标记过的，所以无脑取消标记
                    self.markForFlag(flagItem: flagItem, isFlaged: false)
                }
                mark.backgroundColor = UIColor.ud.R600
                let image = UDIcon.getIconByKey(.flagUnavailableOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 18, height: 18))
                mark.image = image.scaledImage(toPercentage: Zoom.currentZoom.scale)
                mark.hidesWhenSelected = true
                mark.textAlignment = .center
                mark.font = calculateFont(title: title)
                actions.append(mark)
            case .quickSwitcher:
                // 只有feed类型才能置顶
                guard flagItem.type == .feed, let feedVM = flagItem.feedVM else {
                    return []
                }
                let isQuickSwitcher = feedVM.feedPreview.basicMeta.isShortcut
                let title = isQuickSwitcher ?
                    BundleI18n.LarkFlag.Lark_Chat_FeedClickTipsUnpin : BundleI18n.LarkFlag.Lark_Feed_AddQuickSwitcher
                let short = SwipeAction(style: .default, title: title) { [weak self] (_, _, _) in
                    guard let self = self else {
                        return
                    }
                    self.markForShortcut(flagItem: flagItem)
                }
                short.backgroundColor = UIColor.ud.primaryPri400
                let image = isQuickSwitcher ? Resources.quickSwitcher_top : Resources.quickSwitcher_toTop
                short.image = image.scaledImage(toPercentage: Zoom.currentZoom.scale)
                short.hidesWhenSelected = true
                short.textAlignment = .center
                short.font = calculateFont(title: title)
                actions.append(short)
            case .forward:
                guard flagItem.type == .message else { break }
                let mark = SwipeAction(style: .default, title: BundleI18n.LarkFlag.Lark_Legacy_Forward) { [weak self] (_, _, _) in
                    guard let self = self else {
                        return
                    }
                    self.markForForward(flagItem: flagItem)
                }
                mark.backgroundColor = UIColor.ud.N500
                let image = UDIcon.getIconByKey(.forwardOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 18, height: 18))
                mark.image = image.scaledImage(toPercentage: Zoom.currentZoom.scale)
                mark.hidesWhenSelected = true
                mark.textAlignment = .center
                mark.font = calculateFont(title: BundleI18n.LarkFlag.Lark_Legacy_Forward)
                actions.append(mark)
            }
        }
        return actions
    }

    private func calculateFont(title: String) -> UIFont {
        if title.getTextWidth(font: UIFont.ud.body1, height: ActionCons.titleMaxHeight) <= ActionCons.swipeButtonWidth - 8 {
            return UIFont.ud.body1
        } else if title.getTextWidth(font: UIFont.ud.caption0, height: ActionCons.titleMaxHeight) <= ActionCons.swipeButtonWidth - 8 {
            return  UIFont.ud.caption0
        } else {
            return UIFont.ud.caption2
        }
    }

    // 加入长按和右键的菜单
    // ContextMenu的图片显示区域为24pt*31.5pt(fit)
    // 图片是设计给好的24pt*24pt图，所以没有用代码调整
    // 如果要调整图片记得让设计加上24pt*24pt的底板，或者用代码手动调整
    @available(iOS 13.0, *)
    public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
                          point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < datasource.count, let rawCell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        let flagItem = datasource[indexPath.row]
        FlagTracker.Main.Click(flagItem, viewModel.dataDependency.iPadStatus)
        var flagActions: [FlagCellLongPressAction] = []
        var dragScene: Scene?
        if flagItem.type == .message, let cell = rawCell as? FlagMessageCell, !cell.isSwiping, let messageVM = flagItem.messageVM {
            // 处理消息cell
            if let chat = messageVM.chat,
               chat.role == .member,
               messageVM.message.isRecalled == false,
               !messageVM.message.isCleaned,
               let chatSecurityControlService = self.chatSecurityControlService,
               chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                       message: messageVM.message,
                                                                       anonymousId: chat.anonymousId).authorityAllowed {
                if messageVM.message.type == .audio || messageVM.message.type == .vote {
                    flagActions = [.flag]
                } else {
                    flagActions = [.forward, .flag]
                }
            } else {
                // 不在群组内的话先不支持转发，同理消息被撤回的话也不支持转发，消息没有接收权限也不支持转发
                flagActions = [.flag]
            }
            dragScene = cell.supportDragScene()
            // 目前长按/右键的菜单是左滑+右滑的菜单
            let actions = getActions(by: flagActions, flagItem: flagItem, dragScene: dragScene)
            if actions.isEmpty {
                return nil
            }
            let identifier = indexPath as NSCopying
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return UIMenu(title: "", children: actions)
            }
        } else if flagItem.type == .feed, let cell = rawCell as? FeedCardCellInterface, !cell.isSwiping, let feedVM = flagItem.feedVM {
            // 处理feedCell
            return getContextMenuConfig(vm: feedVM, dragScene: cell.supportDragScene(), indexPath: indexPath)
        } else {
            // 目前只能处理上面两种Cell
            return nil
        }
    }

    @available(iOS 13.0, *)
    private func getActions(by flagActions: [FlagCellLongPressAction], flagItem: FlagItem, dragScene: Scene?) -> [UIAction] {
        var actions: [UIAction] = []
        for action in flagActions {
            if action == .flag {
                let unFlagImage = UDIcon.getIconByKey(.flagUnavailableOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
                let mark = UIAction(
                    title: BundleI18n.LarkFlag.Lark_IM_MarkAMessageToArchive_CancelButton,
                    image: unFlagImage) { [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        // 在标记列表的肯定是已经标记过的，所以无脑取消标记
                        // 延迟 0.9 秒让第一个动画走完， 和feed处理保持一致
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            self.markForFlag(flagItem: flagItem, isFlaged: false)
                            switch flagItem.type {
                            case .feed:     FlagTracker.BaseFeed.Unmark(flagItem)
                            case .message:  FlagTracker.MsgTypeFeed.Unmark(flagItem)
                            }
                        }
                }
                actions.append(mark)
            } else if action == .forward {
                let forwardImage = UDIcon.getIconByKey(.forwardOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
                let forward = UIAction(
                    title: BundleI18n.LarkFlag.Lark_Legacy_Forward,
                    image: forwardImage) { [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        self.markForForward(flagItem: flagItem)
                        FlagTracker.MsgTypeFeed.Forward(flagItem)
                }
                actions.append(forward)
            }
        }
        // 创建 scene
        if SceneManager.shared.supportsMultipleScenes, let scene = dragScene {
            scene.sceneSourceID = self.currentSceneID()
            scene.createWay = "menu_click"
            let createScene = UIAction(
                title: BundleI18n.LarkFlag.Lark_Core_OpenInNewWindow,
                image: Resources.feed_create_scene_contextmenu) { [weak self] _ in
                SceneManager.shared.active(
                    scene: scene,
                    from: self) { [weak self] (_, error) in
                    guard let self = self else {
                        return
                    }
                    if error != nil {
                        UDToast.showTips(
                            with: BundleI18n.LarkFlag.Lark_Core_SplitScreenNotSupported,
                            on: self.view
                        )
                    }
                }
            }
            actions.append(createScene)
        }
        return actions
    }

    // 定制 ContextMenu Preview，不定制会有操作白屏的现象
    @available(iOS 13.0, *)
    public func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetPreview(for: tableView, with: configuration)
    }

    @available(iOS 13.0, *)
    public func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetPreview(for: tableView, with: configuration)
    }

    @available(iOS 14.0, *)
    public func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        /// menu 出现时对队列加锁
        self.viewModel.frozenDataQueue()
    }

    @available(iOS 14.0, *)
    public func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        /// menu 消失时开启队列
        self.viewModel.resumeDataQueue()
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
        return UITargetedPreview(view: copy, parameters: UIPreviewParameters(),
                                 target: UIPreviewTarget(container: tableView, center: cell.center))
    }
}

// MARK: - FeedActionService
extension FlagListViewController {
    @available(iOS 13.0, *)
    func getContextMenuConfig(vm: FeedCardViewModelInterface,
                              dragScene: Scene?,
                              indexPath: IndexPath) -> UIContextMenuConfiguration? {
        let actionItems = getActionItems(vm: vm, event: .longPress)
        var actions = self.transformToUIAction(items: actionItems)
        // 创建 scene
        if SceneManager.shared.supportsMultipleScenes, let scene = dragScene {
            scene.sceneSourceID = self.currentSceneID()
            scene.createWay = "menu_click"
            let createScene = UIAction(
                title: BundleI18n.LarkFlag.Lark_Core_OpenInNewWindow,
                image: Resources.feed_create_scene_contextmenu) { [weak self] _ in
                SceneManager.shared.active(
                    scene: scene,
                    from: self) { [weak self] (_, error) in
                    guard let self = self else {
                        return
                    }
                    if error != nil {
                        UDToast.showTips(
                            with: BundleI18n.LarkFlag.Lark_Core_SplitScreenNotSupported,
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

    func getActionItems(vm: FeedCardViewModelInterface, event: FeedActionEvent) -> [FeedActionBaseItem] {
        guard let feedAction = try? userResolver.resolve(type: FeedActionService.self) else { return [] }
        let model = FeedActionModel(feedPreview: vm.feedPreview,
                                    channel: vm.bizData.shortcutChannel,
                                    event: event,
                                    groupType: .flag,
                                    fromVC: self,
                                    basicData: vm.basicData,
                                    bizData: vm.bizData,
                                    extraData: [:])
        let supplementTypes = feedAction.getSupplementTypes(model: model, event: event)
        // flag不支持侧滑设置
        let bizTypes = feedAction.getBizTypes(model: model, event: event, useSetting: false)
        let actionItems = feedAction.transformToActionItems(model: model, types: bizTypes + supplementTypes, event: event)
        return actionItems
    }

    @available(iOS 13.0, *)
    private func transformToUIAction(items: [FeedActionBaseItem]) -> [UIAction] {
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

    private func transformToSwipeAction(items: [FeedActionBaseItem]) -> [SwipeAction] {
        var actions: [SwipeAction] = []
        items.forEach { item in
            guard let viewModel = item.viewModel else { return }
            let action = SwipeAction(style: .default, title: viewModel.title) { (_, _, _) in
                item.handler.executeTask()
            }
            action.backgroundColor = viewModel.swipeBgColor
            action.image = viewModel.swipeEditImage?.scaledImage(toPercentage: Zoom.currentZoom.scale)
            action.hidesWhenSelected = true
            action.textAlignment = .center
            action.font = calculateFont(title: viewModel.title)
            actions.append(action)
        }
        return actions
    }
}

extension FlagMessageCell {
    var isSwiping: Bool {
        swipeView.frame.origin.x != 0
    }

    public func supportDragScene() -> Scene? { return nil }
}

extension UIImage {
    /// 将图片按比例缩放，返回缩放后的图片
    /// - Parameter percentage: 缩放比例
    /// - Parameter opaque: 当前图片是否有透明部分
    func scaledImage(toPercentage percentage: CGFloat, opaque: Bool = false) -> UIImage? {
        let factor = scale == 1.0 ? UIScreen.main.scale : 1.0
        let newWidth = floor(size.width * percentage / factor)
        let newHeight = floor(size.height * percentage / factor)
        let newRect = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(newRect.size, opaque, 0)
        draw(in: newRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension String {
    func getTextWidth(font: UIFont, height: CGFloat) -> CGFloat {
        let rect = NSString(string: self).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                                       options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                       attributes: [NSAttributedString.Key.font: font],
                                                       context: nil)
        return ceil(rect.width)
    }
}

final class FlagBorderTransitionLayout: SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
    }

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
