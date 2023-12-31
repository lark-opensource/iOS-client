//
//  LarkProgressHUD.swift
//  LarkUIKit
//
//  Created by PGB on 2019/8/13.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class LarkProgressHUD: UIView {
    private let progressView = UIImageView(image: UDIcon.chatLoadingOutlined.withRenderingMode(.alwaysTemplate))
    private var shown: Bool = false

    init(view: UIView) {
        super.init(frame: view.bounds)

        addSubview(progressView)
        progressView.tintColor = UIColor.ud.N00
        progressView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
        self.alpha = 0
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
            if self.progressView.layer.animation(forKey: "rotate") != nil {
                return
            }
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            animation.duration = 1
            animation.fillMode = .forwards
            animation.repeatCount = .infinity
            animation.values = [0, Double.pi * 2]
            animation.keyTimes = [NSNumber(value: 0.0), NSNumber(value: 1.0)]

            self.progressView.layer.add(animation, forKey: "rotate")
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
        if self.progressView.layer.animation(forKey: "rotate") != nil {
            self.progressView.layer.removeAnimation(forKey: "rotate")
        }
    }
}
