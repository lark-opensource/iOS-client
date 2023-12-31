//
//  ImMeetingMoreActionViewModel.swift
//  ByteView
//
//  Created by LUNNER on 2019/1/6.
//

import Foundation
import RxSwift
import Action
import RxCocoa
import RxDataSources
import UIKit
import ByteViewCommon

struct SheetAction {

    enum Style {
        case `default`
        case iconAndLabel
        case iconLabelAndBadge
        case warning
        case cancel
        case iconLabelAndBeta
        case withContent
        case callIn
    }

    let title: String
    var titleColor: UIColor = .ud.textTitle
    var titleFontConfig: VCFontConfig?
    var titleMargin: UIEdgeInsets?
    var titleHeight: CGFloat = 0
    var content: String?
    var contentColor: UIColor?
    var contentFontConfig: VCFontConfig?
    var contentMargin: UIEdgeInsets?
    var contentHeight: CGFloat = 0
    var icon: UIImage?
    var showBottomSeparator: Bool = true
    var isSelected: Bool = false
    var sheetStyle: Style = .default
    var isNewMS: Bool = false
    let handler: (SheetAction) -> Void
    /// 水平方向相对于ActionSheet是否有缩进：true则有缩进；false则无
    var isSelectedIndent: Bool = true
    var iconSize: CGFloat {
        isNewMS ? ActionSheetCell.Layout.enlargedIconSize : ActionSheetCell.Layout.iconSize
    }

    // disable-lint: magic number
    var intrinsicWidth: CGFloat {
        let font = titleFontConfig?.font ?? UIFont.systemFont(ofSize: 17)
        let titleWidth = title.size(withAttributes: [NSAttributedString.Key.font: font]).width
        switch sheetStyle {
        case .default, .cancel:
            return titleWidth + 2 * ActionSheetCell.Layout.leftRightOffset
        case .iconAndLabel:
            var width = titleWidth + 2 * ActionSheetCell.Layout.leftRightOffset
            if icon != nil {
                width += (self.iconSize + ActionSheetCell.Layout.titleLeftOffset)
            }
            return width
        case .iconLabelAndBadge:
            var width = titleWidth + 2 * ActionSheetCell.Layout.leftRightOffset
            if icon != nil {
                width += (self.iconSize + ActionSheetCell.Layout.titleLeftOffset)
            }
            width += 6 + 6
            return width
        case .warning:
            var width = titleWidth + 2 * ActionSheetCell.Layout.leftRightOffset
            // left icon
            if icon != nil {
                width += (self.iconSize + ActionSheetCell.Layout.titleLeftOffset)
            }
            // warning icon
            width += (ActionSheetCell.Layout.iconSize + ActionSheetCell.Layout.titleRightOffset)
            return width
        case .iconLabelAndBeta:
            var width = titleWidth + 2 * ActionSheetCell.Layout.leftRightOffset
            // icon
            if icon != nil {
                width += (self.iconSize + ActionSheetCell.Layout.titleLeftOffset)
            }
            // beta
            width += 35 + 4
            return width
        case .withContent:
            var width = titleWidth
            if let content = content {
            let contentFont = contentFontConfig?.font ?? UIFont.systemFont(ofSize: 12)
            let contentWidth = content.size(withAttributes: [NSAttributedString.Key.font: contentFont]).width
                width = max(titleWidth, contentWidth)
            }
            width += 2 * ActionSheetCell.Layout.leftRightOffset
            if icon != nil {
                var titleLeftOffset = ActionSheetCell.Layout.titleLeftOffset
                if let contentMargin = contentMargin {
                    titleLeftOffset = contentMargin.left
                }
                width += (self.iconSize + titleLeftOffset)
            }
            return width
        case .callIn:
            var width = titleWidth + 2 * ActionSheetCell.Layout.leftRightOffset
            // icon
            if icon != nil {
                width += (ActionSheetCell.Layout.iconSize + ActionSheetCell.Layout.titleLeftOffset)
            }
            // 对勾
            width += 12 + 20
            width = width > 180 ? width : 180
            return CGFloat(width)
        }
    }
    // enable-lint: magic number
}

struct ActionSheetSectionModel: SectionModelType {
    init(original: ActionSheetSectionModel, items: [SheetAction]) {
        self = original
        self.items = items
    }

    init(items: [SheetAction]) {
        self.items = items
    }

    var items: [SheetAction]

    typealias Item = SheetAction


}

class ActionSheetViewModel {
    lazy var defaultActions: BehaviorRelay<[ActionSheetSectionModel]> = {
        return BehaviorRelay(value: [])
    }()

    lazy var cancelAction: BehaviorRelay<ActionSheetSectionModel?> = {
        return BehaviorRelay(value: nil)
    }()

    func addAction(_ action: SheetAction) {
        if action.sheetStyle == .cancel {
            cancelAction.accept(ActionSheetSectionModel(items: [action]))
        } else {
            var value = defaultActions.value
            value.append(ActionSheetSectionModel(items: [action]))
            defaultActions.accept(value)
        }
    }

    func addActions(_ actions: [SheetAction]) {
        for action in actions {
            addAction(action)
        }
    }
}
