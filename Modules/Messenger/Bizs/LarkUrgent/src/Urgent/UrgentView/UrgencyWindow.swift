//
//  UrgencyWindow.swift
//  LarkUrgent
//
//  Created by 白镜吾 on 2022/10/11.
//

import Foundation
import UIKit
import LKWindowManager

final class UrgencyWindow: LKVirtualWindow {
    override class func canCreate(by config: VirtualWindowConfig) -> Bool {
        if config.identifier == .UrgencyWindow {
            return true
        }
        return false
    }

    override class func create(by config: VirtualWindowConfig) -> LKVirtualWindow? {
        let window = UrgencyWindow(frame: .zero)
        window.identifier = config.identifier.rawValue
        window.windowLevel = .alert + 100
        window.rootViewController = UrgencyViewController()
        window.isHidden = true
        return window
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var urgencyViewController: UrgencyViewController {
        if let currentController = rootViewController as? UrgencyViewController {
            return currentController
        } else {
            assertionFailure("pushCardController should not be nil")
            let newController = UrgencyViewController()
            rootViewController = newController
            return newController
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else {
            return nil
        }

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

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
        return self.urgencyViewController.checkVisiableArea(point)
    }
}
