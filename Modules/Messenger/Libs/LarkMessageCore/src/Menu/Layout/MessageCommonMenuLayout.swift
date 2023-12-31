//
//  MessageDetailMenuLayout.swift
//  LarkChat
//
//  Created by 李晨 on 2019/1/29.
//

import UIKit
import Foundation
import LarkMenuController
import LarkUIKit

// with triggerLocation:
//  1. for menu's origin y:  when click in upper part of host vc, menu show under the click point; when click in lower part of host vc, menu show up the click point
//  2. for menu's origin x: take the click point as the menu's midpoint, but ensure the min leading/trailing insets (leadingInset) in host vc
// without triggerLocation: show in center

public final class NewMessageCommonMenuLayout: CommonMenuLayout {
    public init(leadingInset: CGFloat = 10.0) {
        let xLayoutRules: [MenuLayoutRule] = [XMiddleRule(), XFollowGestureRule()]
        let yLayoutRules: [MenuLayoutRule] = [YScreenSideRule(offset: 20), YMiddleRule()]
        super.init(xLayoutRules: xLayoutRules, yLayoutRules: yLayoutRules)
        self.insets = UIEdgeInsets(top: 0, left: leadingInset, bottom: 0, right: leadingInset)
    }

    public init(insets: UIEdgeInsets) {
        let xLayoutRules: [MenuLayoutRule] = [XMiddleRule(), XFollowGestureRule()]
        let yLayoutRules: [MenuLayoutRule] = [YScreenSideRule(offset: 20), YMiddleRule()]
        super.init(xLayoutRules: xLayoutRules, yLayoutRules: yLayoutRules)
        self.insets = insets
    }

    public override func menuUpdateLayout(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        if let origin = info.origin {
            let originX = origin.origin.x + offset.x
            var originY: CGFloat = origin.origin.y + (downward ? offset.y : (origin.height - info.menuSize.height + offset.y))
            return CGRect(origin: CGPoint(x: originX, y: originY), size: info.menuSize)
        }
        return menuLayout(info: info)
    }

    public override func menuDisappearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        return menuLayout(info: info)
    }
}

public final class MessageCommonMenuLayout: MenuBarLayout {
    let insets: UIEdgeInsets
    private let horizontalCenter: Bool

    public init(leadingInset: CGFloat = 10.0, horizontalCenter: Bool = Display.phone) {
        self.insets = UIEdgeInsets(top: 0, left: leadingInset, bottom: 0, right: leadingInset)
        self.horizontalCenter = horizontalCenter
    }

    public init(insets: UIEdgeInsets, horizontalCenter: Bool = Display.phone) {
        self.insets = insets
        self.horizontalCenter = horizontalCenter
    }

    public func calculate(info: MenuLayoutInfo) -> CGRect {
        guard let location = info.transformTrigerLocation() else {
            return self.defaultLayoutInfo(
                menuSize: info.menuSize,
                controllerSize: info.menuVC.view.bounds.size
            )
        }

        return self.layoutFrameBy(
            info: info,
            location: location,
            controllerSize: info.menuVC.view.bounds.size
        )
    }

    public func calculateAppear(info: MenuLayoutInfo) -> CGRect {
        return self.calculate(info: info)
    }

    public func calculateDisappear(info: MenuLayoutInfo) -> CGRect {
        return self.calculate(info: info)
    }

    public func calculateUpdate(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        if let origin = info.origin {
            let vcSize = info.menuVC.view.bounds.size
            var rect: CGRect
            if downward {
                var originX = origin.origin.x + offset.x
                // menuSize 宽度大于一半，则居中展示
                if info.menuSize.width > vcSize.width / 2 {
                    originX = self.xLayout(info: info)
                }
                let originY = origin.origin.y + offset.y
                let origin = CGPoint(x: originX, y: originY)
                rect = CGRect(origin: origin, size: info.menuSize)
            } else {
                var originX = origin.origin.x + offset.x
                // menuSize 宽度大于一半，则居中展示
                if info.menuSize.width > vcSize.width / 2 {
                    originX = self.xLayout(info: info)
                }
                let originY = origin.origin.y + origin.height - info.menuSize.height + offset.y
                let origin = CGPoint(x: originX, y: originY)
                rect = CGRect(origin: origin, size: info.menuSize)
            }
            return transform(rect: rect, info: info)
        } else {
            return self.calculate(info: info)
        }
    }

    private func defaultLayoutInfo(menuSize: CGSize, controllerSize: CGSize) -> CGRect {
        let point = CGPoint(
            x: (controllerSize.width - menuSize.width) / 2,
            y: (controllerSize.height - menuSize.height) / 2
        )
        let rect = CGRect(origin: point, size: menuSize)
        return rect
    }

    private func layoutFrameBy(info: MenuLayoutInfo, location: CGPoint, controllerSize: CGSize) -> CGRect {
        let height: CGFloat = info.menuSize.height
        let width: CGFloat = info.menuSize.width

        let xPos = self.xLayout(info: info)
        let yPos = self.yLayout(info: info, location: location, controllerSize: controllerSize)
        let rect = CGRect(x: xPos, y: yPos, width: width, height: height)
        return transform(rect: rect, info: info)
    }

    private func yLayout(info: MenuLayoutInfo, location: CGPoint, controllerSize: CGSize) -> CGFloat {
        let menuSize = info.menuSize
        var yPos: CGFloat = 0
        if location.y < controllerSize.height / 2 {
            yPos = location.y + 20
        } else {
            yPos = location.y - menuSize.height - 20
        }
        return yPos
    }

    private func xLayout(info: MenuLayoutInfo) -> CGFloat {
        let vcSize = info.menuVC.view.bounds.size
        if horizontalCenter {
            return (vcSize.width - info.menuSize.width) / 2
        }
        guard let point = info.transformTrigerLocation() else {
            return (vcSize.width - info.menuSize.width) / 2
        }
        let x = point.x - info.menuSize.width / 2
        return min(max(x, self.insets.left), vcSize.width - info.menuSize.width - self.insets.right)
    }

    // 返回 menu 绘制区域
    private func renderRect(info: MenuLayoutInfo) -> CGRect {

        guard let window = info.menuVC.view.window else { return .zero }
        // window safe Rect
        let windowSafeRect = window.bounds.inset(by: window.safeAreaInsets)
        // menu 在 window 上的 frame
        let menuVcFrame = self.menuVCRect(info: info)
        let menuRenderFrame = windowSafeRect.intersection(menuVcFrame)
        if menuRenderFrame.height <= 0 {
            assertionFailure()
            return .zero
        }
        let menuInsetsFrame = menuRenderFrame.inset(by: insets)
        return window.convert(menuInsetsFrame, to: info.menuVC.view)
    }

    private func menuVCRect(info: MenuLayoutInfo) -> CGRect {
        return info.menuVC.view.convert(info.menuVC.view.bounds, to: info.menuVC.view.window)
    }

    // 判断 rect 边界 保证 rect 合法
    private func transform(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        var rect = rect
        let renderRect = self.renderRect(info: info)

        // 首先需要 rect 的范围在 menuVC 内部
        if rect.minX < renderRect.minX { rect = CGRect(origin: CGPoint(x: renderRect.minX, y: rect.origin.y), size: rect.size) }
        if rect.minY < renderRect.minY { rect = CGRect(origin: CGPoint(x: rect.origin.x, y: renderRect.minY), size: rect.size) }
        if rect.maxX > renderRect.maxX { rect = CGRect(origin: CGPoint(x: renderRect.maxX - rect.width, y: rect.origin.y), size: rect.size) }
        if rect.maxY > renderRect.maxY { rect = CGRect(origin: CGPoint(x: rect.origin.x, y: renderRect.maxY - rect.height), size: rect.size) }

        return rect
    }
}
