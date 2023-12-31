//
//  ShortcutLayout.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/16.
//

import UIKit
import Foundation
struct ShortcutLayout {

    static var labelFont: UIFont = .systemFont(ofSize: 11)
    static var avatarSize: CGFloat = 40
    static var avatarBorderSize: CGFloat = 44
    static var avatarTopInset: CGFloat = 6

    static let edgeInset: UIEdgeInsets = UIEdgeInsets(top: 6, left: 9, bottom: 0, right: 9)

    static let itemWidth: CGFloat = 54
    static var itemHeight: CGFloat = 80
    static let minItemSpace: CGFloat = CGFloat.leastNormalMagnitude
    static let singleLineHeight: CGFloat = ShortcutLayout.edgeInset.top + ShortcutLayout.itemHeight + ShortcutLayout.edgeInset.bottom

    static let shortcutsLoadingExpansionTrigger: CGFloat = 60 // 下拉到yOffset 60以上时，就可以触发shortcuts展开
    static let loadingHeight: CGFloat = 15
    static let bottomLineHeight: CGFloat = (1 / UIScreen.main.scale)
}
