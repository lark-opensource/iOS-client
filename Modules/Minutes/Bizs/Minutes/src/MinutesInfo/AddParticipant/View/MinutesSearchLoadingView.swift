//
//  MinutesSearchLoadingView.swift
//  Minutes
//
//  Created by sihuahao on 2021/10/15.
//

import Foundation
import UIKit
import UniverseDesignIcon

class MinutesSearchLoadingView: UIView {

    private lazy var toastView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgTips
        view.layer.cornerRadius = 10.0
        return view
    }()

    lazy var loadingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.loadingOutlined, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 36, height: 36))
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(.pi * 2.0)
        rotateAnimation.duration = 1.0
        rotateAnimation.isCumulative = true
        rotateAnimation.repeatCount = .greatestFiniteMagnitude
        rotateAnimation.isRemovedOnCompletion = false
        imageView.layer.add(rotateAnimation, forKey: "EventExceptionRotationAnimation")
        return imageView
    }()

    init() {
        super.init(frame: UIApplication.shared.keyWindow?.bounds ?? .zero)

        backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)

        addSubview(toastView)
        toastView.addSubview(loadingImageView)

        toastView.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalToSuperview()
            maker.width.equalTo(84)
            maker.height.equalTo(84)
        }

        loadingImageView.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalToSuperview()
            maker.size.equalTo(36)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoad() {
        UIApplication.shared.keyWindow?.addSubview(self)
    }

    func dissmissLoad() {
        self.removeFromSuperview()
    }

    public static func showLoad() {
        UIApplication.shared.keyWindow?.addSubview(MinutesSearchLoadingView())
    }

    public static func dissmissLoad() {
        guard let views = UIApplication.shared.keyWindow?.subviews else { return }
        for hud in views {
            if hud is MinutesSearchLoadingView {
                hud.removeFromSuperview()
            }
        }
    }

}
