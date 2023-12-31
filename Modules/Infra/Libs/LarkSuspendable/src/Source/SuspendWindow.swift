//
//  SuspendWindow.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import LKWindowManager
import LarkExtensions

public final class SuspendWindow: LKWindow {

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 确保 SuspendWindow 的层级低于 QuickLaunchWindow
        windowLevel = UIWindow.Level(9.5)
        self.windowIdentifier = "LarkSuspendable.SuspendWindow"
        rootViewController = SuspendController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var suspendController: SuspendController {
        if let currentController = rootViewController as? SuspendController {
            return currentController
        } else {
            assertionFailure("SuspendController should not be nil")
            let newController = SuspendController()
            rootViewController = newController
            return newController
        }
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
            let rootVC = self.rootViewController else {
            return nil
        }
        if !hitView.isDescendant(of: rootVC.view) {
            return nil
        }
        return hitView
    }
}
