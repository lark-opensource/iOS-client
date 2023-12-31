//
//  AICommonMenuLayout.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/3/23.
//

import UIKit
import Foundation
import LarkMenuController
import LarkUIKit

// with triggerLocation:
//  1. for menu's origin y:  when click in upper part of host vc, menu show under the click point; when click in lower part of host vc, menu show up the click point
//  2. for menu's origin x: take the click point as the menu's midpoint, but ensure the min leading/trailing insets (leadingInset) in host vc
// without triggerLocation: show in center

public final class AICommonMenuLayout: MenuBarLayout {
    private let leadingInset: CGFloat
    private let horizontalCenter: Bool

    public init(leadingInset: CGFloat = 10.0, horizontalCenter: Bool = Display.phone) {
        self.leadingInset = leadingInset
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
            if downward {
                let origin = CGPoint(x: origin.origin.x + offset.x, y: origin.origin.y + offset.y)
                return CGRect(origin: origin, size: info.menuSize)
            } else {
                let origin = CGPoint(
                    x: origin.origin.x + offset.x,
                    y: origin.origin.y + origin.height - info.menuSize.height + offset.y
                )
                return CGRect(origin: origin, size: info.menuSize)
            }
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

        var xPos: CGFloat
        var yPos: CGFloat
        if controllerSize.width > 700 || controllerSize.width > controllerSize.height {
            yPos = self.yLayout(info: info)
            if location.x < controllerSize.width / 2 {
                xPos = location.x + 20
            } else {
                xPos = location.x - width - 20
            }
        } else {
            xPos = self.xLayout(info: info)
            if location.y < controllerSize.height / 2 {
                yPos = location.y + 20
            } else {
                yPos = location.y - height - 20
            }
        }
        // 防止卡片超出屏幕
        if xPos < 0 {
            xPos = 0
        }
        if yPos < 0 {
            yPos = 0
        }
        if width + xPos > controllerSize.width {
            xPos = controllerSize.width - width
        }
        if height + yPos > controllerSize.height {
            yPos = controllerSize.height - height
        }

        let navBarHeight = info.menuVC.navigationController?.navigationBar.frame.size.height ?? 0
        yPos = max(yPos, navBarHeight)
        return CGRect(x: xPos, y: yPos, width: width, height: height)
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
        return min(max(x, leadingInset), vcSize.width - info.menuSize.width - leadingInset)
    }
    private func yLayout(info: MenuLayoutInfo) -> CGFloat {
        let vcSize = info.menuVC.view.bounds.size
        let navBarHeight = info.menuVC.navigationController?.navigationBar.frame.size.height ?? 0
        guard let point = info.transformTrigerLocation() else {
            return (vcSize.height - info.menuSize.height) / 2
        }
        let y = point.y - info.menuSize.height / 2
        return min(max(y, leadingInset, navBarHeight), vcSize.height - info.menuSize.height - leadingInset)
    }
}
