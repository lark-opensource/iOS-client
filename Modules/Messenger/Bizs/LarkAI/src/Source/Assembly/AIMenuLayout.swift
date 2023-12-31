//
//  SmartCorrectMenuLayout.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/6/15.
//

import UIKit
import Foundation
import LarkMenuController
import LarkUIKit

public final class AIMenuLayout: MenuBarLayout {
    private let leadingInset: CGFloat
    private let horizontalCenter: Bool
    public private(set) var layoutX: CGFloat = 0.0

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

        let xPos = self.xLayout(info: info)
        let yPos: CGFloat = location.y - height - 20
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
        let layoutX = min(max(x, leadingInset), vcSize.width - info.menuSize.width - leadingInset)
        self.layoutX = layoutX
        return layoutX
    }
}
