//
//  SimpleMenuViewModel.swift
//  LarkMenuController
//
//  Created by 李晨 on 2019/6/11.
//

import UIKit
import Foundation
import LarkEmotionKeyboard
import LarkSetting

open class SimpleMenuViewModel: MenuBarViewModel {
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

    // 所有的表情菜单项
    var allReactionMenuItems: [MenuReactionItem] = []
    public var isDirectShowMoreEmoji: Bool = false

    public init(
        recentReactionMenuItems: [MenuReactionItem],
        scene: ReactionPanelScene = .unknown,
        allReactionMenuItems: [MenuReactionItem],
        allReactionGroups: [ReactionGroup],
        actionItems: [MenuActionItem],
        style: MenuBarStyle? = nil,
        triggerGesture: UIGestureRecognizer? = nil,
        isDirectShowMoreEmoji: Bool = false) {

        let transformRecent = recentReactionMenuItems.map { [weak self] (item) -> MenuReactionItem in
            return MenuReactionItem(reactionEntity: item.reactionEntity, action: { [weak self] (reaction) in
                if let `self` = self,
                    let menu = self.menu {
                    menu.dismiss(animated: true, params: nil, completion: {
                        item.action(reaction)
                        // 最常使用reaction面板点击
                        MenuTracker.emotionPanelClick(reaction,
                                                      scene: scene,
                                                      tab: "mru",
                                                      isSkintonePanel: false,
                                                      skintoneEmojiSelectWay: nil,
                                                      chatId: nil)
                    })
                }
            })
        }

        let transformAction = actionItems.map { [weak self] (item) -> MenuActionItem in
            return MenuActionItem(
                name: item.name,
                image: item.image,
                enable: true,
                action: { [weak self] (_) in
                    if let `self` = self,
                        let menu = self.menu {
                        menu.dismiss(animated: true, params: nil, completion: {
                            item.action(item)
                        })
                    }
                })
        }

        if scene == .unknown {
            assertionFailure()
        }
        self.allReactionMenuItems = allReactionMenuItems
        self.isDirectShowMoreEmoji = isDirectShowMoreEmoji
        self.menuBar = MenuBar(
            reactions: transformRecent,
            allReactionGroups: allReactionGroups,
            actionItems: transformAction,
            supportMoreReactions: self.isDirectShowMoreEmoji ? false : true,
            style: style,
            triggerGesture: triggerGesture,
            scene: scene)

        self.menuBar.userReactionBar.clickMoreBlock = { [weak self] in
            guard let `self` = self else { return }
            self.showMoreReactionBar = !self.showMoreReactionBar
            MenuTracker.reactionPanelView(scene: scene)
        }
        self.menuBar.reactionPanel.clickReactionBlock = { [weak self] reactionKey, _, isSkintonePanel, skintoneEmojiSelectWay in
            if let `self` = self,
                let menu = self.menu,
               let reactionItem = self.allReactionMenuItems.first(where: { ($0.type == reactionKey || $0.subTypes.contains(reactionKey)) }) {
                menu.dismiss(animated: true, params: nil, completion: {
                    reactionItem.action(reactionKey)
                    MenuTracker.emotionPanelClick(reactionKey,
                                                  scene: scene,
                                                  tab: "all",
                                                  isSkintonePanel: isSkintonePanel,
                                                  skintoneEmojiSelectWay: skintoneEmojiSelectWay,
                                                  chatId: nil)
                })
            }
        }
    }

    open func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool) {
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
