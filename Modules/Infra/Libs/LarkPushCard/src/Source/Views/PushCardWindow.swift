//
//  PushCardWindow.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import Foundation
import UIKit
import LKWindowManager

final class PushCardWindow: LKVirtualWindow {

    override class func canCreate(by config: VirtualWindowConfig) -> Bool {
        if config.identifier == .PushCardWindow {
            return true
        }
        return false
    }

    override class func create(by config: VirtualWindowConfig) -> LKVirtualWindow? {
        let window = PushCardWindow(frame: .zero)
        window.identifier = config.identifier.rawValue
        return window
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.windowLevel = .alert + 50
        self.rootViewController = PushCardViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var pushCardController: PushCardViewController {
        if let currentController = rootViewController as? PushCardViewController {
            return currentController
        } else {
            assertionFailure("pushCardController should not be nil")
            let newController = PushCardViewController()
            rootViewController = newController
            return newController
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 视图必须显示且可交互，否则返回 nil
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else {
            return nil
        }
        // 点击位置必须在视图区域内，否则返回 nil
        guard self.point(inside: point, with: event) else {
            return nil
        }
        // 倒序遍历子视图
        for subview in subviews.reversed() {
            let insidePoint = convert(point, to: subview)
            if let hitView = subview.hitTest(insidePoint, with: event) {
                return hitView
            }
        }
        return self
    }

    func resetConstraints() {
        self.pushCardController.resetConstraints()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
        return self.pushCardController.checkVisiableArea(point)
    }
}
