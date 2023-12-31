//
//  FeedCardCell+BGColor.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/19.
//

import UIKit
import Foundation
import LarkTraitCollection
import LarkUIKit
import LarkOpenFeed
import UniverseDesignColor

extension FeedCardCell {
    enum ColorMode {
        case normal(UIColor) // 正常
        case press(UIColor) // 点击 feed 时
        case selected(UIColor) // iPad 选中
        case tempTop(UIColor) // 临时置顶
    }

    func easySetColor() {
        resetColor()
        let colorMode = getColorMode(press: self.isHighlighted || self.isSelected,
                                     selected: cellViewModel?.selected ?? false,
                                     tempTop: cellViewModel?.basicData.isTempTop ?? false)
        setColor(mode: colorMode)
    }

    func setColor(mode: ColorMode) {
        switch mode {
        case .normal(let color):
            setBackViewColor(color)
        case .press(let color):
            if cellViewModel?.basicData.isTempTop == true {
                // TODO: feed的点击态颜色区域是带圆角的卡片，临时置顶feed的背景色区域是通栏的，以上是前提。UX同学@赵永强要求临时置顶的点击态颜色区域需要通栏，所以需要特化下，后续跟ux同学沟通看如何消化掉这个特化逻辑
                swipeView.backgroundColor = color
            } else {
                setBackViewColor(color)
            }
        case .selected(let color):
            setBackViewColor(color)
        case .tempTop(let color):
            swipeView.backgroundColor = color
        }
    }

    func resetColor() {
        swipeView.backgroundColor = .clear
        backgroundView?.backgroundColor = defaultColor
    }

    func getColorMode(press: Bool,
                      selected: Bool,
                      tempTop: Bool) -> ColorMode {
        // 有优先级的概念
        if FeedSelectionEnable, selected {
            let isRegular = self.cellViewModel?.dependency.feedBarStyle?.currentStyle == .padRegular
            if isRegular {
                return .selected(self.selectedColor)
            }
        }
        if press {
            return .press(self.pressColor)
        }
        if tempTop {
            return .tempTop(self.tempTopColor)
        }
        return .normal(self.defaultColor)
    }
}
