//
//  GuideMarkHelper.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/14.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import UIKit

public final class GuideMarkHelper {
    let guideRootView: GuideRootView
    let guideFlowManager: GuideFlowManager

    init(guideRootView: GuideRootView, guideFlowManager: GuideFlowManager) {
        self.guideRootView = guideRootView
        self.guideFlowManager = guideFlowManager
    }

    public func update(guideMark: inout GuideMark,
                       usingView view: UIView? = nil) {
        guard let view = view else { return }

        let convertedFrame = guideRootView.convert(view.frame, from: view.superview)

        let bezierPath: UIBezierPath

        bezierPath = UIBezierPath(roundedRect: convertedFrame.insetBy(dx: guideMark.cutoutPathinsetByX, dy: guideMark.cutoutPathinsetByY),
                                  byRoundingCorners: .allCorners,
                                  cornerRadii: guideMark.cutoutCornerRadii)

        guideMark.cutoutPath = bezierPath
    }
}
