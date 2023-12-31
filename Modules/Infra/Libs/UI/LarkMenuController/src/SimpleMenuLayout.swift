//
//  SimpleMenuLayout.swift
//  LarkMenuController
//
//  Created by 李晨 on 2019/6/11.
//

import UIKit
import Foundation

public final class SimpleMenuLayout: MenuBarLayout {
    public init() {}

    public var offset: CGFloat = 20

    public func calculate(info: MenuLayoutInfo) -> CGRect {
        guard let location = info.transformTrigerLocation() else {
            return self.defaultLayoutInfo(menuSize: info.menuSize, vcSize: info.menuVC.view.bounds.size)
        }

        return self.layoutFrameBy(menuSize: info.menuSize, location: location, menuVCSize: info.menuVC.view.bounds.size)
    }

    public func calculateAppear(info: MenuLayoutInfo) -> CGRect {
        return self.calculate(info: info)
    }

    public func calculateDisappear(info: MenuLayoutInfo) -> CGRect {
        return info.origin ?? self.calculate(info: info)
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

    private func defaultLayoutInfo(menuSize: CGSize, vcSize: CGSize) -> CGRect {
        let point = CGPoint(x: (vcSize.width - menuSize.width) / 2, y: (vcSize.height - menuSize.height) / 2)
        let rect = CGRect(origin: point, size: menuSize)
        return rect
    }

    private func layoutFrameBy(menuSize: CGSize, location: CGPoint, menuVCSize: CGSize) -> CGRect {
        let height: CGFloat = menuSize.height
        let width: CGFloat = menuSize.width

        let xPos = (menuVCSize.width - menuSize.width) / 2
        var yPos: CGFloat
        if location.y < menuVCSize.height / 2 {
            yPos = location.y + offset
        } else {
            yPos = location.y - height - offset
        }
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }
}
