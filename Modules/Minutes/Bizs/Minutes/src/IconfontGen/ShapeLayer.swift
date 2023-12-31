//
//  ShapeLayer.swift
//  IconfontGen
//
//  Created by yangyao on 2019/10/10.
//

import UIKit

public final class ShapeLayer: CALayer {
    public var iconDrawable: IconDrawable? {
        didSet {
            guard let iconDrawable = iconDrawable else { return }
            draw(iconDrawable)
        }
    }

    private var shape: CAShapeLayer?
    private var path: CGPath?
    public var transformedPath: CGPath?
    public var fillColor: CGColor?

    public override var contentsGravity: CALayerContentsGravity {
        didSet {
            setNeedsLayout()
        }
    }

    public override init() {
        super.init()
        Iconfont.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    private func draw(_ iconDrawable: IconDrawable) {
        guard let path = iconDrawable.path else {
            return
        }
        self.path = path

        if shape == nil {
            let newShape = CAShapeLayer()
            addSublayer(newShape)
            shape = newShape
        }
        guard let shape = shape else { return }

        if shape.path !== path {
            CATransaction.begin()
            CATransaction.disableActions()

            shape.path = path
            shape.contentsScale = UIScreen.main.scale
            setNeedsLayout()

            CATransaction.commit()
        }
    }

    public override func preferredFrameSize() -> CGSize {
        guard let path = shape?.path else {
            return super.preferredFrameSize()
        }
        return path.boundingBoxOfPath.size
    }

    public override func layoutSublayers() {
        super.layoutSublayers()
        guard let shape = shape, let path = shape.path else { return }

        CATransaction.begin()
        if let animationKey = animationKeys()?.first, let animation = animation(forKey: animationKey) {
            CATransaction.setAnimationDuration(animation.duration)
            CATransaction.setAnimationTimingFunction(animation.timingFunction)
        } else {
            CATransaction.setAnimationDuration(0)
            CATransaction.disableActions()
        }

        shape.fillColor = fillColor ?? UIColor.ud.primaryOnPrimaryFill.cgColor
        shape.bounds = path.boundingBoxOfPath

        var scaleX: CGFloat
        var scaleY: CGFloat
        var translationX: CGFloat
        var translationY: CGFloat

        switch contentsGravity {
        case .resizeAspect:
            // 取最小
            scaleX = min(bounds.width / shape.bounds.width,
                         bounds.height / shape.bounds.height)
            scaleY = scaleX
            translationX = bounds.width * 0.5
            translationY = bounds.height * 0.5
        case .resizeAspectFill:
            // 取最大
            scaleX = max(bounds.width / shape.bounds.width,
                         bounds.height / shape.bounds.height)
            scaleY = scaleX
            translationX = bounds.width * 0.5
            translationY = bounds.height * 0.5
        case .center:
            scaleX = 1.0
            scaleY = 1.0
            translationX = bounds.width * 0.5
            translationY = bounds.height * 0.5
        case .top:
            scaleX = 1.0
            scaleY = 1.0
            translationX = bounds.width * 0.5
            translationY = bounds.height - shape.bounds.height * 0.5
        case .bottom:
            scaleX = 1.0
            scaleY = 1.0
            translationX = bounds.width * 0.5
            translationY = shape.bounds.height * 0.5
        case .left:
            scaleX = 1.0
            scaleY = 1.0
            translationX = shape.bounds.width * 0.5
            translationY = bounds.height * 0.5
        case .right:
            scaleX = 1.0
            scaleY = 1.0
            translationX = bounds.width - shape.bounds.width * 0.5
            translationY = bounds.height * 0.5
        case .topLeft:
            scaleX = 1.0
            scaleY = 1.0
            translationX = shape.bounds.width * 0.5
            translationY = bounds.height - shape.bounds.height * 0.5
        case .topRight:
            scaleX = 1.0
            scaleY = 1.0
            translationX = bounds.width - shape.bounds.width * 0.5
            translationY = bounds.height - shape.bounds.height * 0.5
        case .bottomLeft:
            scaleX = 1.0
            scaleY = 1.0
            translationX = shape.bounds.width * 0.5
            translationY = shape.bounds.height * 0.5
        case .bottomRight:
            scaleX = 1.0
            scaleY = 1.0
            translationX = bounds.width - shape.bounds.width * 0.5
            translationY = shape.bounds.height * 0.5
        default:
            // 同比放大缩小
            scaleX = bounds.width / shape.bounds.width
            scaleY = bounds.height / shape.bounds.height
            translationX = bounds.width * 0.5
            translationY = bounds.height * 0.5
        }

        var scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let translation = CGAffineTransform(translationX: translationX, y: translationY)
        let transform = scale.concatenating(translation)
        transformedPath = path.copy(using: &scale)
        shape.setAffineTransform(transform)

        CATransaction.commit()
    }
}
