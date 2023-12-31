//
//  LarkSheetMenuViewModel.swift
//  LarkSheetMenu
//
//  Created by Zigeng on 2023/1/23.
//

import Foundation
import UIKit
import LarkEmotionKeyboard

public enum LarkSheetMenuHeader {
    case emoji([MenuReactionItem])
    case custom(UIView)
    case invisible
}

public enum LarkSheetMenuMoreView {
    case emoji([ReactionGroup], ClickReactionBlock)
    case custom(UIView)
    case invisible
}

public class LarkSheetMenuViewModel {
    public var dataSource: [LarkSheetMenuActionSection]
    public var header: LarkSheetMenuHeader
    public var moreView: LarkSheetMenuMoreView

    public init(dataSource: [LarkSheetMenuActionSection],
                header: LarkSheetMenuHeader,
                moreView: LarkSheetMenuMoreView) {
        self.dataSource = dataSource
        self.header = header
        self.moreView = moreView
    }
}

public struct LarkSheetMenuActionSection {
    public var sectionItems: [LarkSheetMenuActionItem]
    public init(_ sectionItems: [LarkSheetMenuActionItem]) {
        self.sectionItems = sectionItems
    }
}

public struct LarkSheetMenuActionItem {
    public typealias MenuCellTapAction = (() -> Void)
    /// sub结构
    public private(set) var subItems: [LarkSheetMenuActionItem] = []
    /// 目前 仅对于!subItems.isEmpty的Item，支持添加一段描述
    public var subText: String?

    public var tapAction: MenuCellTapAction
    public var icon: UIImage
    public var text: String
    public var isShowDot: Bool
    public var isGrey: Bool

    public init(icon: UIImage,
                text: String,
                isShowDot: Bool,
                isGrey: Bool,
                subItems: [LarkSheetMenuActionItem],
                subText: String?,
                tapAction: @escaping MenuCellTapAction) {
        self.tapAction = tapAction
        self.icon = icon
        self.text = text
        self.isShowDot = isShowDot
        self.isGrey = isGrey
        self.subItems = subItems
        self.subText = subText
    }
}
