//
//  LoadingSkeletonView.swift
//  SKSpace
//
//  Created by majie.7 on 2023/12/12.
//

import Foundation
import UniverseDesignColor
import UniverseDesignShadow
import SkeletonView


class LoadingSkeletonView: UIView {

    private static var animationKey: String { "LoadingSkeletionViewAnimation" }

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        layer.cornerRadius = 6
        clipsToBounds = true
        layer.addSublayer(gradientLayer)
        let baseColor = UDColor.getValueByKey(.loadingSpinIndicatorPrimary) ?? UDColor.N200
        let gradientColors = SkeletonGradient(baseColor: baseColor)
        gradientLayer.ud.setColors(gradientColors.colors)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func playAnimation() {
        let animation = makeSlidingAnimation()
        gradientLayer.add(animation, forKey: Self.animationKey)
    }

    func stopAnimation() {
        gradientLayer.removeAnimation(forKey: Self.animationKey)
    }

    private func makeSlidingAnimation() -> CAAnimation {
        let startPointAnim = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.startPoint))
        startPointAnim.fromValue = CGPoint(x: -1, y: 0.5)
        startPointAnim.toValue = CGPoint(x:1, y: 0.5)

        let endPointAnim = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.endPoint))
        endPointAnim.fromValue = CGPoint(x: 0, y: 0.5)
        endPointAnim.toValue = CGPoint(x:2, y: 0.5)

        let animGroup = CAAnimationGroup()
        animGroup.animations = [startPointAnim, endPointAnim]
        animGroup.duration = 1.5
        animGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animGroup.repeatCount = .infinity
        return animGroup
    }
}
