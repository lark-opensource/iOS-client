//
//  CommentMenuLayout.swift
//  SKBrowser
//
//  Created by bupozhuang on 2021/2/28.
//

import Foundation
import LarkMenuController
import LarkUIKit

public final class CommentMenuLayout: MenuBarLayout {
    private let horizonPadding: CGFloat = 12.0 // 距离左右的最小间距
    private let topOffset: CGFloat = 12.0
    private let bottomOffset: CGFloat = 36.0
    
    var isOnlyActionBar: Bool = false
    
    public init( _ isOnlyActionBar: Bool = false) {
        self.isOnlyActionBar = isOnlyActionBar
    }
    
    public func calculate(info: MenuLayoutInfo) -> CGRect {
        guard let location = info.transformTrigerLocation() else {
            return self.defaultLayoutInfo(menuSize: info.menuSize, vcSize: info.menuVC.view.bounds.size)
        }
        if Display.pad || isOnlyActionBar {
            return self.layoutFrameBy(menuSize: info.menuSize, location: location, menuVCSize: info.menuVC.view.bounds.size)
        } else {
            return SimpleMenuLayout().calculate(info: info)
        }
            
    }

    public func calculateAppear(info: MenuLayoutInfo) -> CGRect {
        return self.calculate(info: info)
    }

    public func calculateDisappear(info: MenuLayoutInfo) -> CGRect {
        return info.origin ?? self.calculate(info: info)
    }

    public func calculateUpdate(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        return self.calculate(info: info)
    }

    private func defaultLayoutInfo(menuSize: CGSize, vcSize: CGSize) -> CGRect {
        let point = CGPoint(x: (vcSize.width - menuSize.width) / 2, y: (vcSize.height - menuSize.height) / 2)
        let rect = CGRect(origin: point, size: menuSize)
        return rect
    }

    private func layoutFrameBy(menuSize: CGSize, location: CGPoint, menuVCSize: CGSize) -> CGRect {
        let height: CGFloat = menuSize.height
        let width: CGFloat = menuSize.width

        var xPos: CGFloat
        
        if menuVCSize.width < width + 2 * horizonPadding {
            xPos = (menuSize.width - width) / 2 // 居中
        } else if location.x - width / 2 >= horizonPadding {
            if location.x + width / 2 <= menuVCSize.width - horizonPadding {
                xPos = location.x - width / 2
            } else {
                xPos = menuVCSize.width - width - horizonPadding
            }
        } else {
            xPos = horizonPadding
        }
        var yPos: CGFloat
        if location.y < menuVCSize.height / 2 {
            yPos = location.y + bottomOffset
        } else {
            yPos = location.y - height - topOffset
        }

        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }
}
