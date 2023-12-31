//
//  ActionSheetAppearance.swift
//  ByteView
//
//  Created by 李凌峰 on 2020/2/12.
//

import Foundation
import ByteViewCommon
import ByteViewUI
import UIKit

struct ActionSheetAppearance {
    var style: ActionSheetController.Style = .actionSheet
    let backgroundColor: UIColor
    var contentViewColor: UIColor = .clear
    var titleColor: UIColor = .ud.textTitle
    var separatorColor: UIColor = .ud.lineDividerDefault
    var modalBackgroundColor: UIColor?
    var customTextHeight: CGFloat?
    var showBarView: Bool = false
    var tableViewInsets: UIEdgeInsets = .zero
    var tableViewCornerRadius: CGFloat = 12
    var tableViewScrollable: Bool = false
    var contentAlignment: NSTextAlignment = .left

    let highlightedColor: UIColor = .ud.fillHover
    let textColor: UIColor = .ud.textTitle

    var showDragIndicator: Bool {
        return style == .pan
    }

    var indicatorColor: UIColor {
        switch style {
        case .actionSheet:
            return .clear
        case .pan:
            return UIColor.ud.N300
        }
    }

    var viewControllerBackgroundColor: UIColor {
        switch style {
        case .actionSheet:
            return UIColor.ud.bgMask
        case .pan:
            return backgroundColor
        }
    }

    var textHeight: CGFloat {
        if let height = customTextHeight {
            return height
        }
        switch style {
        case .actionSheet:
            return ActionSheetController.Layout.actionSheetRowHeight
        case .pan:
            return ActionSheetController.Layout.panRowHeight
        }
    }

    var titleTopOffset: CGFloat {
        switch style {
        case .actionSheet:
            return ActionSheetController.Layout.actionSheetTitleTopOffset
        case .pan:
            return ActionSheetController.Layout.panTitleTopOffset
        }
    }

    var titleHorizontalOffset: CGFloat {
        switch style {
        case .actionSheet:
            return ActionSheetController.Layout.actionSheetTitleHorizontalOffset
        case .pan:
            return ActionSheetController.Layout.panTitleHorizontalOffset
        }
    }

    var titleAlignment: NSTextAlignment {
        switch style {
        case .actionSheet:
            return .center
        case .pan:
            return .left
        }
    }

    var titleTextStyleConfig: VCFontConfig {
        switch style {
        case .actionSheet:
            return VCFontConfig.bodyAssist
        case .pan:
            return VCFontConfig.h3
        }
    }

    func bottomOffset(isPhoneLandscape: Bool) -> CGFloat {
        switch style {
        case .actionSheet:
            return isPhoneLandscape
                ? ActionSheetController.Layout.landscapeBottomOffset
                : ActionSheetController.Layout.bottomOffset
        case .pan:
            return 0
        }
    }
}
