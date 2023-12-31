//
//  CoverLoadingIndicator.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/5/11.
//

import Foundation
import UniverseDesignIcon
import UIKit

final class CoverLoadingIndicator: UIView {
    var circle = UIImageView(image: UDIcon.loadingOutlined.withRenderingMode(.alwaysTemplate))
    var retryAction: (() -> Void)?

    override var tintColor: UIColor? {
        didSet {
            retryButton.tintColor = tintColor
            circle.tintColor = tintColor
        }
    }

    private var retryButton = UIButton(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(circle)
        circle.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        retryButton.isHidden = true
        addSubview(retryButton)
        retryButton.tintAdjustmentMode = .normal
        retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        retryButton.setImage(UDIcon.refreshOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        retryButton.tintColor = .ud.primaryContentDefault
        retryButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        layer.speed = 1
        circle.isHidden = false

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation]
        groupAnimation.duration = 1.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        circle.layer.add(groupAnimation, forKey: "animation")

        retryButton.isHidden = true
    }

    func showRetryState() {
        stopAnimation()
        circle.isHidden = true
        retryButton.isHidden = false
    }

    func stopAnimation() {
        circle.layer.removeAllAnimations()
    }

    @objc
    private func retry() {
        retryAction?()
    }
}
