//
//  UDTabsIndicatorLineView.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit

/// Indicator Line Style
public enum UDTabsIndicatorLineStyle {
    /// normal
    case normal
    /// lengthen
    case lengthen
    /// lengthenOffset
    case lengthenOffset
}

open class UDTabsIndicatorLineView: UDTabsIndicatorBaseView {
    open var lineStyle: UDTabsIndicatorLineStyle = .normal
    /// lineStyle为lengthenOffset时使用，滚动时x的偏移量
    open var lineScrollOffsetX: CGFloat = 10

    open var indicatorMaskedCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

    open var indicatorRadius: CGFloat = 2

    open override func commonInit() {
        super.commonInit()

        indicatorHeight = 3
    }

    open override func refreshIndicatorState(model: UDTabsIndicatorParamsModel) {
        super.refreshIndicatorState(model: model)

        backgroundColor = indicatorColor
        layer.cornerRadius = indicatorRadius
        layer.maskedCorners = indicatorMaskedCorners
        let width = getIndicatorWidth(itemFrame: model.currentSelectedItemFrame)
        let height = getIndicatorHeight(itemFrame: model.currentSelectedItemFrame)
        let newX = model.currentSelectedItemFrame.origin.x + (model
                                                                .currentSelectedItemFrame.size.width - width) / 2
        var newY = model.currentSelectedItemFrame.size.height - height - verticalOffset
        if indicatorPosition == .top {
            newY = verticalOffset
        }
        frame = CGRect(x: newX, y: newY, width: width, height: height)
    }

    open override func contentScrollViewDidScroll(model: UDTabsIndicatorParamsModel) {
        super.contentScrollViewDidScroll(model: model)

        if model.percent == 0 || !isScrollEnabled {
            //model.percent等于0时不需要处理，会调用selectItem(model: UDTabsIndicatorParamsModel)方法处理
            //isScrollEnabled为false不需要处理
            return
        }

        let rightItemFrame = model.rightItemFrame
        let leftItemFrame = model.leftItemFrame
        let percent = model.percent
        var targetX: CGFloat = leftItemFrame.origin.x
        var targetWidth = getIndicatorWidth(itemFrame: leftItemFrame)

        let leftWidth = targetWidth
        let rightWidth = getIndicatorWidth(itemFrame: rightItemFrame)
        let leftX = leftItemFrame.origin.x + (leftItemFrame.size.width - leftWidth) / 2
        let rightX = rightItemFrame.origin.x + (rightItemFrame.size.width - rightWidth) / 2

        switch lineStyle {
        case .normal:
            targetX = UDTabsViewTool.interpolate(from: leftX, to: rightX, percent: CGFloat(percent))
            if indicatorWidth == UDTabsViewAutomaticDimension {
                targetWidth = UDTabsViewTool.interpolate(from: leftWidth, to: rightWidth, percent: CGFloat(percent))
            }
        case .lengthen:
            //前50%，只增加width；后50%，移动x并减小width
            let maxWidth = rightX - leftX + rightWidth
            if percent <= 0.5 {
                targetX = leftX
                targetWidth = UDTabsViewTool
                    .interpolate(from: leftWidth,
                                 to: maxWidth,
                                 percent: CGFloat(percent * 2))
            } else {
                targetX = UDTabsViewTool
                    .interpolate(from: leftX,
                                 to: rightX,
                                 percent: CGFloat((percent - 0.5) * 2))
                targetWidth = UDTabsViewTool
                    .interpolate(from: maxWidth,
                                 to: rightWidth,
                                 percent: CGFloat((percent - 0.5) * 2))
            }
        case .lengthenOffset:
            //前50%，增加width，并少量移动x；后50%，少量移动x并减小width
            let maxWidth = rightX - leftX + rightWidth - lineScrollOffsetX * 2
            if percent <= 0.5 {
                targetX = UDTabsViewTool
                    .interpolate(from: leftX,
                                 to: leftX + lineScrollOffsetX,
                                 percent: CGFloat(percent * 2))
                targetWidth = UDTabsViewTool
                    .interpolate(from: leftWidth,
                                 to: maxWidth,
                                 percent: CGFloat(percent * 2))
            } else {
                targetX = UDTabsViewTool
                    .interpolate(from: leftX + lineScrollOffsetX,
                                 to: rightX,
                                 percent: CGFloat((percent - 0.5) * 2))
                targetWidth = UDTabsViewTool
                    .interpolate(from: maxWidth,
                                 to: rightWidth,
                                 percent: CGFloat((percent - 0.5) * 2))
            }
        }

        self.frame.origin.x = targetX
        self.frame.size.width = targetWidth
    }

    open override func selectItem(model: UDTabsIndicatorParamsModel) {
        super.selectItem(model: model)

        let targetWidth = getIndicatorWidth(itemFrame: model.currentSelectedItemFrame)
        var toFrame = self.frame
        toFrame.origin.x = model
            .currentSelectedItemFrame.origin.x +
            (model.currentSelectedItemFrame.size.width - targetWidth) / 2
        toFrame.size.width = targetWidth
        if isScrollEnabled && (model.selectedType == .click || model.selectedType == .code) {
            //允许滚动且选中类型是点击或代码选中，才进行动画过渡
            UIView.animate(withDuration: scrollAnimationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.frame = toFrame
            }, completion: nil)
        } else {
            frame = toFrame
        }
    }

}
