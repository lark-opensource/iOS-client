//
//  SheetNumKeyboardViewLayout.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/8.
//

import Foundation

class SheetNumKeyboardViewLayout {
    private var baseHeight: CGFloat = 258
    private var baseWidth: CGFloat = 375

    //按钮高占据面板高度的比例
    private let calcYRatio: CGFloat = 54 / 258
    private let numYRatio: CGFloat = 54 / 258
    private let helpYRatio: CGFloat = 54 / 258
    //按钮宽占据面板宽度的比例
    private let calcXRatio: CGFloat = 52.5 / 375
    private let numXRatio: CGFloat = 75 / 375
    private let helpXRatio: CGFloat = 52.5 / 375

    private var calcBtnWidth: CGFloat = 52.5
    private var calcBtnHeight: CGFloat = 54
    private var numBtnWidth: CGFloat = 75
    private var numBtnHeight: CGFloat = 54
    private var helpBtnWidth: CGFloat = 52.5
    private var helpBtnHeight: CGFloat = 54

    init(preferWidth: CGFloat, preferHeight: CGFloat) {
        baseWidth = preferWidth
        baseHeight = preferHeight
        calcBtnHeight = baseHeight * calcYRatio
        numBtnHeight = baseHeight * numYRatio
        helpBtnHeight = baseHeight * helpYRatio

        calcBtnWidth = baseWidth * calcXRatio
        numBtnWidth = baseWidth * numXRatio
        helpBtnWidth = baseWidth * helpXRatio
    }

    //货币，百分比这一列
    func calcButtonSize() -> CGSize {
        return CGSize(width: helpBtnWidth, height: helpBtnHeight)
    }

    // 1-9, 0, 00, .
    func numberButtonSize() -> CGSize {
        return CGSize(width: numBtnWidth, height: numBtnHeight)
    }
    //delete、右箭头
    func helpButtonSize() -> CGSize {
        return CGSize(width: helpBtnWidth, height: helpBtnHeight)
    }

    func downButtonSize() -> CGSize {
        return CGSize(width: helpBtnWidth, height: helpBtnHeight * 2.0 + itemInterPadding())
    }

    func topPadding() -> CGFloat {
        let padding = 8.0 / 258.0 * baseHeight
        return padding
    }

    func bottomPadding() -> CGFloat {
        let padding = 10.0 / 258.0 * baseHeight
        return padding
    }

    //横向布局，左右间距
    func itemLinePadding() -> CGFloat {
        let emptyWidth = baseWidth - calcBtnWidth - helpBtnWidth - numBtnWidth * 3
        guard emptyWidth > 0 else {
            return 0
        }
        return emptyWidth / 6
    }

    //横向布局，上下间距
    func itemInterPadding() -> CGFloat {
        var emptyHeight = baseHeight - topPadding() - bottomPadding()
        emptyHeight -= (numberButtonSize().height * 4)
        guard emptyHeight > 0 else {
            return 0
        }
        return emptyHeight / 3
    }

}
