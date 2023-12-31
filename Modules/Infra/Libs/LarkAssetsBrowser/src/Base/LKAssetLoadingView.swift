//
//  LKAssetLoadingView.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2022/2/16.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class LKAssetLoadingView: UIView {
    private let loadingImageView = UIImageView(image: UDIcon.chatLoadingOutlined.withRenderingMode(.alwaysTemplate))
    private var shown: Bool = false

    init(view: UIView) {
        super.init(frame: view.bounds)
        alpha = 0
        addSubview(loadingImageView)
        loadingImageView.tintColor = UIColor.ud.primaryOnPrimaryFill
        loadingImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(animated: Bool) {
        if !shown {
            snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalTo(96)
            }
            shown = true
        }
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1
            }
        } else {
            alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {
                return
            }
            if self.loadingImageView.layer.animation(forKey: "rotate") != nil {
                return
            }
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            animation.duration = 1
            animation.fillMode = .forwards
            animation.repeatCount = .infinity
            animation.values = [0, Double.pi * 2]
            animation.keyTimes = [NSNumber(value: 0.0), NSNumber(value: 1.0)]

            self.loadingImageView.layer.add(animation, forKey: "rotate")
        }
    }

    func hide(animated: Bool) {
        // progressHUD被remove后，约束会消失。将shown置为false，下次展示时重新添加约束
        shown = false
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0
            }, completion: { [weak self] _ in
                self?.stopRotate()
            })
        } else {
            alpha = 0
            stopRotate()
        }
    }

    private func stopRotate() {
        if self.loadingImageView.layer.animation(forKey: "rotate") != nil {
            self.loadingImageView.layer.removeAnimation(forKey: "rotate")
        }
    }
}
