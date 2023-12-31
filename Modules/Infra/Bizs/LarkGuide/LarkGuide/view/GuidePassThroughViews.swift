//
//  GuidePassThroughViews.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/13.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import UIKit
import LarkExtensions

final class GuideWindow: UIWindow {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.windowIdentifier = "LarkGuide.GuideWindow"
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView == self {
            return nil
        }

        return hitView
    }
}

/// Top view added to the window, forwarding touch events.
final class GuideRootView: UIView {

    var passthrough: Bool = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView == self && passthrough {
            return nil
        }

        return hitView
    }
}
