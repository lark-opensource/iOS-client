//
//  SystemBlurView.swift
//  FigmaKit
//
//  Created by Hayden on 2023/3/17.
//

import UIKit

public class SystemBlurView: UIView, UIViewBlurable {

    public var blurRadius: CGFloat = 20 {
        didSet {
            // BlurRadius 无法和 Figma 的数值对齐，要乘一个参数
            // Tricky-0: 这个数值是根据对比 Figma 设计稿根据个人观感决定的，可能并不精确
            let convertedBlurRadius = blurRadius * 1.2
            intensityBlurView?.customIntensity = max(0, min(1, convertedBlurRadius / 100))
        }
    }

    public var fillColor: UIColor? {
        get { backgroundColor }
        set { backgroundColor = newValue }
    }

    public var fillOpacity: CGFloat = 0.0 {
        didSet {
            backgroundColor = backgroundColor?.withAlphaComponent(fillOpacity)
        }
    }

    private lazy var blurView: UIVisualEffectView = {
        if #available(iOS 12.0, *) {
            return CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .regular), intensity: 0.2)
        } else {
            return UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        }
    }()

    private var intensityBlurView: CustomIntensityVisualEffectView? {
        if #available(iOS 12.0, *) {
            return blurView as? CustomIntensityVisualEffectView
        } else {
            return nil
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        super.addSubview(blurView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
    }

    public override func addSubview(_ view: UIView) {
        blurView.contentView.addSubview(view)
    }
}

/// 使用 `UIViewPropertyAnimator` 动画实现可变 blurRadius 的模糊视图（不使用私有 API）
final class CustomIntensityVisualEffectView: UIVisualEffectView {

    var customIntensity: CGFloat {
        didSet {
            setNeedsDisplay()
        }
    }

    private let theEffect: UIVisualEffect

    private var animator: UIViewPropertyAnimator?

    init(effect: UIVisualEffect, intensity: CGFloat) {
        theEffect = effect
        customIntensity = intensity
        super.init(effect: nil)
        /* 某些场景有问题，暂时没适配，先注掉
        // Tricky-1: UIVisualEffectView 在 LM/DM 模糊程度不统一，所以此处统一使用 LM
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }
         */
    }

    required init?(coder aDecoder: NSCoder) { nil }

    deinit {
        animator?.stopAnimation(true)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Tricky-2: 使用 PropertyAnimator 强行设置模糊度，模拟 blurRadius
        effect = nil
        animator?.stopAnimation(true)
        animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [unowned self] in
            self.effect = theEffect
        }
        animator?.fractionComplete = customIntensity
        /* 某些场景有问题，暂时没适配，先注掉
        // Tricky-3: 消除 UIVisalEffectView 子视图背景色，避免影响底层颜色
        self.subviews.first { subview in
            String(describing: type(of: subview)).contains("VisualEffectSubview")
        }?.backgroundColor = nil
         */
    }
}
