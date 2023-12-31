//
//  MaskView.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/13.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import UIKit

// Overlay a blocking view on top of the screen and handle the cutout path
// around the point of interest.
final class MaskView: UIView {
    internal static let sublayerName = "Instructions.OverlaySublayer"

    var cutoutPath: UIBezierPath?

    var holder: UIView
    let ornaments: UIView

    /// Used to temporarily enable touch forwarding isnide the cutoutPath.
    public var allowTouchInsideCutoutPath: Bool = false

    // MARK: - Initialization
    init() {
        holder = UIView()
        ornaments = UIView()

        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false

        holder.translatesAutoresizingMaskIntoConstraints = false
        ornaments.translatesAutoresizingMaskIntoConstraints = false

        holder.isUserInteractionEnabled = false
        ornaments.isUserInteractionEnabled = false

        addSubview(holder)
        addSubview(ornaments)

        holder.fillSuperview()
        ornaments.fillSuperview()

    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    // MARK: - Internal methods
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView == self {
            guard let cutoutPath = self.cutoutPath else {
                return hitView
            }

            if !self.allowTouchInsideCutoutPath {
                return hitView
            }

            if cutoutPath.contains(point) {
                return nil
            } else {
                return hitView
            }
        }

        return hitView
    }
}
