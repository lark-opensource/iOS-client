//
//  HoverMenuViewModel.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/18.
//

import Foundation
import LarkEmotionKeyboard
import LarkMenuController
import Homeric
import LarkCore
import LKCommonsTracker
import LarkSetting

internal class HoverMenuViewModel: MenuBarViewModel {
    func update(rect: CGRect, info: LarkMenuController.MenuLayoutInfo, isFirstTime: Bool) {
        if isFirstTime {
            var reactionBarAtTop: Bool = true
            if let location = info.transformTrigerLocation() {
                reactionBarAtTop = abs(location.y - rect.top) < abs(location.y - rect.bottom)
            } else if let rect = info.transformTrigerView() {
                reactionBarAtTop = abs(rect.centerY - rect.top) < abs(rect.centerY - rect.bottom)
            }
            self.menuBar.reactionBarAtTop = reactionBarAtTop
        }
    }

    weak public var menu: MenuVCProtocol?

    public var type: String = "simple.menu.view.model"
    public var identifier: String = "simple.menu.view.model"
    public var menuView: UIView {
        return self.menuBar
    }

    public var menuSize: CGSize {
        return self.menuBar.menuSize
    }
    public var menuBar: MenuBar!

    // reaction注入服务
    private let dependency: EmojiDataSourceDependency? = EmojiImageService.default

    private var showMoreReactionBar: Bool = false {
        didSet {
            if FeatureGatingManager.shared.featureGatingValue(with: "im.emoji.commonly_used_abtest") {
                self.menuBar.hideReactionBar()
            }
            self.menu?.reloadMenu(
                animation: true,
                downward: menuBar.reactionBarAtTop,
                offset: .zero,
                action: { [weak self] in
                    guard let `self` = self else { return }
                    self.menuBar.showMoreReactionBar = self.showMoreReactionBar
                })
        }
    }

    var transformRecent: [MenuReactionItem] = []
    public var isDirectShowMoreEmoji: Bool = false

    public init(
        recentReactionMenuItems: [MenuReactionItem],
        clickReactionBlock: @escaping ClickReactionBlock,
        allReactionGroups: [ReactionGroup],
        actionItems: [MenuActionItem],
        style: MenuBarStyle? = nil,
        triggerGesture: UIGestureRecognizer? = nil) {

        transformRecent = recentReactionMenuItems.map { [weak self] (item) -> MenuReactionItem in
            return MenuReactionItem(reactionEntity: item.reactionEntity, action: { [weak self] (reaction) in
                if let `self` = self,
                    let menu = self.menu {
                    menu.dismiss(animated: true, params: nil, completion: {
                        item.action(reaction)
                    })
                }
            })
        }

        self.menuBar = MenuBar(
            reactions: transformRecent,
            allReactionGroups: allReactionGroups,
            actionItems: actionItems,
            supportMoreReactions: self.isDirectShowMoreEmoji ? false : true,
            style: style,
            triggerGesture: triggerGesture)

        self.menuBar.userReactionBar.clickMoreBlock = { [weak self] in
            guard let `self` = self else { return }
            self.showMoreReactionBar = !self.showMoreReactionBar
            Tracker.post(TeaEvent(Homeric.REACTION_MORE))
            PublicTracker.Reaction.View(scene: .im)
        }
        self.menuBar.reactionPanel.clickReactionBlock = clickReactionBlock
    }

    public func update(showEmojiHeader: Bool, actionItems: [MenuActionItem]) {
        self.menuBar.reloadMenuBarByItems(actionItems, relactionItems: showEmojiHeader ? transformRecent : [] )
        if let menuVC = self.menu as? MenuViewController, menuVC.hadShowAnimation {
            self.showMoreReactionBar = false
            self.menu?.reloadMenu(
                animation: false,
                downward: menuBar.reactionBarAtTop,
                offset: .zero,
                action: nil)
        }
    }

    public func updateMenuVCSize(_ size: CGSize) {
        menuBar.viewControllerWidth = size.width
    }

    public func openMoreReactionPanel() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.showMoreReactionBar = true
        }
    }
}
