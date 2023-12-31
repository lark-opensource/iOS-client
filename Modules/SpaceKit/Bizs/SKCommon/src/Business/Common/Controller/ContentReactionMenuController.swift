//
//  ContentReactionMenuController.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/23.
// swiftlint:disable pattern_matching_keywords


import SKUIKit
import Foundation
import SKFoundation
import LarkEmotionKeyboard
import LarkMenuController
import SKCommon

public struct ReactionMenuAction {
    
    public let reactionKey: String
    public let isUserCancelled: Bool
    
    public func toParams() -> [String: Any] {
        return ["reactionKey": reactionKey,
                "isUserCancelled": isUserCancelled]
    }
}

public final class ContentReactionMenuController: DocsReactionMenuViewController {
    
    private static let clickReactionNotification = NSNotification.Name(rawValue: "lark.ccm.contentReactionPanel.click")
    
    private let onItemClicked: ((ReactionMenuAction) -> Void)
    
    private var tempClickedKey: String? // 单次点击的表情key
    
    public enum TriggerFrom {
        case docContent(trigerView: UIView)
        case reactionCard(trigerView: UIView, trigerLocation: CGPoint)
    }
    
    public init(triggerFrom: TriggerFrom, onItemClicked: @escaping ((ReactionMenuAction) -> Void)) {
        
        self.onItemClicked = onItemClicked
        
        let action: (String) -> Void = { key in
            DocsLogger.info("click content reaction, key = \(key)")
            NotificationCenter.default.post(name: Self.clickReactionNotification, object: key)
        }
        
        let defaultReactions = EmojiImageService.default?.getDefaultReactions() ?? []
        let recentReactions = EmojiImageService.default?.getRecentReactions() ?? defaultReactions
        let itemsPerRow = 7
        let recentSlice = (recentReactions.count > itemsPerRow) ? Array(recentReactions.prefix(itemsPerRow)) : recentReactions
        let recent = recentSlice.map { $0.toMenuReactionItem(action: action) }
        
        let reactionGroups = EmojiImageService.default?.getAllReactions() ?? []
        let reactions = reactionGroups.flatMap { $0.entities }.map { $0.toMenuReactionItem(action: action) }
        let vm = SimpleMenuViewModel(recentReactionMenuItems: recent,
                                     scene: .ccm,
                                     allReactionMenuItems: reactions,
                                     allReactionGroups: reactionGroups,
                                     actionItems: [],
                                     isDirectShowMoreEmoji: true)
        vm.menuBar.reactionBarAtTop = true
        vm.menuBar.reactionSupportSkinTones = LKFeatureGating.reactionSkinTonesEnable
        let layout = CommentMenuLayout(recent.isEmpty)
        
        let trigerView: UIView
        let trigerLocation: CGPoint
        switch triggerFrom {
        case .docContent(let view):
            trigerView = view
            let menuMagicGap: CGFloat = 20 // magic number 组件不知道为什么多出这个空隙
            let bottom: CGFloat
            if SKDisplay.pad {
                bottom = trigerView.frame.maxY - trigerView.safeAreaInsets.bottom + menuMagicGap - 28
            } else {
                let value: CGFloat = (trigerView.safeAreaInsets.bottom == 0) ? 8 : 30 // 试验得出
                bottom = trigerView.frame.maxY - value + menuMagicGap
            }
            let point = CGPoint(x: trigerView.center.x, y: bottom)
            trigerLocation = point
        case .reactionCard(let view, let location):
            trigerView = view
            trigerLocation = location
        }
        super.init(viewModel: vm, layout: layout, trigerView: trigerView, trigerLocation: trigerLocation)
        self.autoDismissOnOrientationChange = true
        
        let name1 = MenuViewController.Notification.MenuControllerDidHideMenu
        NotificationCenter.default.addObserver(self, selector: #selector(onHide), name: name1, object: nil)
        let name2 = Self.clickReactionNotification
        NotificationCenter.default.addObserver(self, selector: #selector(onClickItem), name: name2, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public func showIn(controller: UIViewController) {
        show(in: controller)
        (viewModel as? SimpleMenuViewModel)?.openMoreReactionPanel()
    }
    
    @objc
    private func onHide() {
        if tempClickedKey == nil {
            onItemClicked(.init(reactionKey: "", isUserCancelled: true))
        }
        tempClickedKey = nil
    }
    
    @objc
    private func onClickItem(_ noti: NSNotification) {
        let key = (noti.object as? String) ?? ""
        tempClickedKey = key
        onItemClicked(.init(reactionKey: key, isUserCancelled: false))
    }
}

private extension ReactionEntity {
    
    func toMenuReactionItem(action: @escaping (String) -> Void) -> MenuReactionItem {
        MenuReactionItem(reactionEntity: self, action: action)
    }
}
