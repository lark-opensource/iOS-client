//
//  ReactionPanelConfig.swift
//  LarkReactionPanel
//
//  Created by 王元洵 on 2021/2/8.
//

import UIKit
import Foundation
import LarkFloatPicker
import UniverseDesignColor
import UniverseDesignTheme

/// MoreReactionPanelConfig
public struct MoreReactionPanelConfig {
    public static let defaultSpaceBetweenRow: CGFloat = 14
    
    let pageIndicatorTintColor: UIColor
    let currentPageIndicatorTintColor: UIColor
    let numberOfRow: Int
    let numberInRow: Int
    let reactionGroups: [ReactionGroup]
    let clickReactionBlock: ClickReactionBlock?
    let clickCloseBlock: (() -> Void)?
    let scrollViewDidScrollBlock: ((_ contentOffset: CGPoint) -> Void)?
    let closeInTop: Bool
    let closeIconColor: UIColor?
    let closeIconSize: CGSize
    let backgroundColor: UIColor
    let reactionCollectionBackgroundColor: UIColor
    let reactionLayoutEdgeInset: UIEdgeInsets
    let pageControlBackgroundColor: UIColor
    let hasCloseIcon: Bool
    let iconSize: CGSize
    let spaceBetweenRow: CGFloat

    /// init
    public init(pageIndicatorTintColor: UIColor = UIColor.ud.iconN3,
                currentPageIndicatorTintColor: UIColor = UIColor.ud.primaryContentDefault,
                numberOfRow: Int = 5,
                numberInRow: Int = 7,
                reactionGroups: [ReactionGroup],
                clickReactionBlock: ClickReactionBlock? = nil,
                clickCloseBlock: (() -> Void)? = nil,
                scrollViewDidScrollBlock: ((_ contentOffset: CGPoint) -> Void)? = nil,
                closeInTop: Bool = true,
                closeIconColor: UIColor? = nil,
                closeIconSize: CGSize = CGSize(width: 24, height: 24),
                backgroundColor: UIColor = UIColor.clear,
                reactionCollectionBackgroundColor: UIColor = UIColor.clear,
                reactionLayoutEdgeInset: UIEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 20, right: 16),
                pageControlBackgroundColor: UIColor = UIColor.clear,
                hasCloseIcon: Bool = true,
                iconSize: CGSize = CGSize(width: 28, height: 28),
                spaceBetweenRow: CGFloat = defaultSpaceBetweenRow) {
        self.pageIndicatorTintColor = pageIndicatorTintColor
        self.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        self.numberOfRow = numberOfRow
        self.numberInRow = numberInRow
        self.reactionGroups = reactionGroups
        self.clickReactionBlock = clickReactionBlock
        self.clickCloseBlock = clickCloseBlock
        self.scrollViewDidScrollBlock = scrollViewDidScrollBlock
        self.closeInTop = closeInTop
        self.closeIconSize = closeIconSize
        self.closeIconColor = closeIconColor
        self.backgroundColor = backgroundColor
        self.reactionCollectionBackgroundColor = reactionCollectionBackgroundColor
        self.reactionLayoutEdgeInset = reactionLayoutEdgeInset
        self.pageControlBackgroundColor = pageControlBackgroundColor
        self.hasCloseIcon = hasCloseIcon
        self.iconSize = iconSize
        self.spaceBetweenRow = spaceBetweenRow
    }
}

/// RecentReactionPanelConfig
public struct RecentReactionPanelConfig {
    public static let defaultReactionBarHeight: CGFloat = 28
    
    let reactionSize: CGSize
    let reactionBarHeight: CGFloat
    let moreIconColor: UIColor?
    let moreIconSize: CGSize
    let items: [MenuReactionItem]
    let clickMoreBlock: (() -> Void)?
    let supportMoreReactions: Bool
    let reactionCollectionBackgroundColor: UIColor
    let reactionLayoutEdgeInset: UIEdgeInsets
    let supportSheetMenu: Bool

    /// init
    public init(reactionSize: CGSize = CGSize(width: 28, height: 28),
                reactionBarHeight: CGFloat = defaultReactionBarHeight,
                moreIconColor: UIColor? = nil,
                moreIconSize: CGSize = CGSize(width: 24, height: 24),
                items: [MenuReactionItem],
                clickMoreBlock: (() -> Void)? = nil,
                supportMoreReactions: Bool = false,
                reactionCollectionBackgroundColor: UIColor = UIColor.clear,
                reactionLayoutEdgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16),
                supportSheetMenu: Bool = false) {
        self.reactionSize = reactionSize
        self.reactionBarHeight = reactionBarHeight
        self.moreIconColor = moreIconColor
        self.moreIconSize = moreIconSize
        self.items = items
        self.clickMoreBlock = clickMoreBlock
        self.supportMoreReactions = supportMoreReactions
        self.reactionLayoutEdgeInset = reactionLayoutEdgeInset
        self.reactionCollectionBackgroundColor = reactionCollectionBackgroundColor
        self.supportSheetMenu = supportSheetMenu
    }
}
