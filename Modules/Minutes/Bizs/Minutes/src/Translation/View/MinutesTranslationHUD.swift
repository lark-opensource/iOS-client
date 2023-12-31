//
//  MinutesTranslationHUD.swift
//  Minutes
//
//  Created by yangyao on 2021/2/26.
//

import UIKit
import UniverseDesignIcon

class MinutesTranslationHUD: UIView {
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

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_Translating
        label.font = .systemFont(ofSize: 15)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom, padding: 8)
        let image = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        button.addTarget(self, action: #selector(closeSelf), for: .touchUpInside)
        return button
    }()

    var closeBlock: (() -> Void)?

    @objc func closeSelf() {
        removeFromSuperview()
        closeBlock?()
    }

    let isTranslating: Bool

    init(isTranslating: Bool) {
        self.isTranslating = isTranslating
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)

        addSubview(toastView)
        toastView.addSubview(loadingImageView)

        if isTranslating {
            toastView.addSubview(titleLabel)
            toastView.addSubview(closeButton)

            toastView.snp.makeConstraints { (maker) in
                maker.centerX.centerY.equalToSuperview()
                maker.width.equalTo(128)
                maker.height.equalTo(84)
            }

            loadingImageView.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalToSuperview().offset(17)
                maker.size.equalTo(24)
            }

            titleLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(loadingImageView.snp.bottom).offset(8)
                maker.left.equalToSuperview().offset(10)
                maker.right.equalToSuperview().offset(-10)
            }

            closeButton.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(8)
                maker.right.equalToSuperview().offset(-8)
                maker.size.equalTo(14)
            }
        } else {
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
