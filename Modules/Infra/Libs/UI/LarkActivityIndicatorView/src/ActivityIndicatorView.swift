//
//  ActivityIndicatorView.swift
//  LarkUIKit
//
//  Created by zhouyuan on 2018/4/11.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

protocol ActivityIndicatorAnimationDelegate: AnyObject {
    func setUpAnimation(in layer: CALayer, size: CGSize, color: UIColor)
}

/// Activity indicator view with nice animations
open class ActivityIndicatorView: UIView {

    public static var defaultColor = UIColor.white

    public static var defaultBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    /// Color of activity indicator view.
    public var color: UIColor = ActivityIndicatorView.defaultColor

    /// Current status of animation, read-only.
    private(set) public var isAnimating: Bool = false

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        isHidden = true
    }

    public init(frame: CGRect = .zero, color: UIColor? = nil) {
        self.color = color ?? ActivityIndicatorView.defaultColor
        super.init(frame: frame)
        isHidden = true
    }

    public override var bounds: CGRect {
        didSet {
            // setup the animation again for the new bounds
            if oldValue != bounds && isAnimating {
                setUpAnimation()
            }
        }
    }

    public final func startAnimating() {
        isHidden = false
        isAnimating = true
        layer.speed = 1
        setUpAnimation()
    }

    public final func stopAnimating() {
        isHidden = true
        isAnimating = false
        layer.sublayers?.removeAll()
    }

    private final func setUpAnimation() {
        let animation: ActivityIndicatorAnimationDelegate = ActivityIndicatorAnimation()
        var animationRect = frame.inset(by: .zero)
        let minEdge = min(animationRect.width, animationRect.height)

        layer.sublayers = nil
        animationRect.size = CGSize(width: minEdge, height: minEdge)
        animation.setUpAnimation(in: layer, size: animationRect.size, color: color)
    }
}
