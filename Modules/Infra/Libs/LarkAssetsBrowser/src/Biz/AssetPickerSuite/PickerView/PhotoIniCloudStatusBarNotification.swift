//
//  PhotoIniCloudStatusBarNotification.swift
//  LarkUIKit
//
//  Created by zc09v on 2017/9/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkExtensions
import UniverseDesignColor

class BaseStatusBarNotification: UIWindow, CAAnimationDelegate {
    var showAlpha: CGFloat = 1

    func show(reNew: Bool = false) {
        func prepareAnimation() {
            self.isHidden = false
            self.alpha = showAlpha
            let animation = CATransition()
            animation.duration = 0.3
            animation.subtype = CATransitionSubtype.fromBottom
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.type = CATransitionType.moveIn
            self.layer.add(animation, forKey: "AppearAnimation")
        }
        if self.isHidden {
            prepareAnimation()
            self.perform(#selector(dismiss), with: nil, afterDelay: 3)
        } else {
            if reNew {
                prepareAnimation()
            }
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismiss), object: nil)
            self.perform(#selector(dismiss), with: nil, afterDelay: 3)
        }
    }

    @objc
    func dismiss() {
        self.alpha = 0
        let animation = CATransition()
        animation.delegate = self
        animation.duration = 0.3
        animation.subtype = .fromTop
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = CATransitionType(rawValue: "push")
        self.layer.add(animation, forKey: "DissmissAnimation")
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.isHidden = true
    }
}

final class PhotoIniCloudStatusBarNotification: BaseStatusBarNotification {
    public static let shared = PhotoIniCloudStatusBarNotification()

    private let label: UILabel
    private let icon: UIImageView
    let rect = UIApplication.shared.statusBarFrame

    private init() {
        label = UILabel()
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.numberOfLines = 0
        icon = UIImageView(image: Resources.photInCloud)

        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0))
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 20

        self.backgroundColor = UIColor.white
        self.windowLevel = .normal

        self.addSubview(label)
        self.addSubview(icon)
    }

    func showNotification(content: String, reNew: Bool = false) {
        icon.frame.size = CGSize(width: 22, height: 22)
        icon.frame.left = 15

        label.text = content
        label.frame = CGRect(x: icon.frame.right + 10,
                             y: 0,
                             width: UIScreen.main.bounds.width - label.frame.left - 10,
                             height: 0)
        label.sizeToFit()

        let maxHeight = max(label.frame.size.height, icon.frame.size.height)
        let totoalHeight = rect.height + 11 + maxHeight + 11

        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: totoalHeight)
        icon.frame.centerY = rect.height + 11 + maxHeight / 2
        label.frame.centerY = icon.frame.centerY

        self.show(reNew: reNew)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
