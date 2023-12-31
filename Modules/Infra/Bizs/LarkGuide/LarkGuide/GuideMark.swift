//
//  GuideMark.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/13.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import LarkUIKit
import UIKit

public struct GuideMark {

    // cutoutPath is the cut-out's path
    // that you can set it directly
    // or set cutoutView
    // or set cutoutShapeLayer
    public var cutoutPath: UIBezierPath?
    public var lazyCutoutPath: (() -> UIBezierPath?)?

    // cutoutShapeLayer is must memberOf CAShapeLayer
    // we need CAShapeLayer.path to cutoutPath
    public var cutoutShapeLayer: CAShapeLayer?

    // these parameters can adjust cutoutPath size and cornerRadii
    public var cutoutPathinsetByX: CGFloat = -4
    public var cutoutPathinsetByY: CGFloat = -4
    public var cutoutCornerRadii: CGSize = CGSize(width: 4,
                                                  height: 4)

    // public weak var cutoutView: UIView?
    public var cutoutView: () -> UIView?

    public var cutoutPoint: CGPoint?

    public var bodyViewClass: viewClass.Type?

    public var bodyViewParamStyle: bodyViewParamStyle?

    /// Set this property to `true` to display the coach mark over the cutoutPath.
    public var displayOverCutoutPath: Bool = true

    /// Set this property to `true` to disable a tap on the overlay.
    /// (only if the tap capture was enabled)
    ///
    /// If you need to disable the tap for all the coachmarks, prefer setting
    /// `CoachMarkController.allowOverlayTap`.
    public var disableOverlayTap: Bool = false

    /// Set this property to `true` to allow touch forwarding inside the cutoutPath.
    public var allowTouchInsideCutoutPath: Bool = false

    public var willStartActionNeedTime: ( () -> Double )?

    public var willEndActionNeedTime: ( () -> Double )?

    // if you want to doSomething like do animations,that you can excute in this block
    public var layoutFinish: ( () -> Void )?

    public var bodyViewClick: ( () -> Void )?

    // MARK: - Initialization
    /// Allocate and initialize a Coach mark with default values.
    public init<V> (initWith cutoutView: @escaping () -> UIView?, bodyViewClass: BodyViewClass<V>.Type? = nil) {
        self.cutoutView = cutoutView
        self.bodyViewClass = bodyViewClass
    }

    // do something while startGuide
    internal func startAction(completion: @escaping () -> Void) {
        if let willStartAction = self.willStartActionNeedTime {
            let spendTime = willStartAction()
            DispatchQueue.main.asyncAfter(deadline: .now() + spendTime + 0.01) {
                completion()
            }
        } else {
            completion()
        }
    }

    // do something while guide remove
    internal func endAction(completion: @escaping () -> Void) {
        if let willEndAction = self.willEndActionNeedTime {
            let spendTime = willEndAction()
            DispatchQueue.main.asyncAfter(deadline: .now() + spendTime + 0.01) {
                completion()
            }
        } else {
            completion()
        }
    }
}
