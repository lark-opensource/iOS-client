//
//  SpaceListRefreshTipView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/8/7.
//

import UIKit
import SnapKit
import SKResource
import SKUIKit
import UniverseDesignColor

class SpaceListRefreshTipView: UIControl {

    var clickHandler: (() -> Void)?

    private lazy var animationView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SKResource.Common.Tips.icon_tips_loading_nor
        return imageView
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SKResource.Common.Tips.icon_tips_refresh_nor
        return imageView
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = BundleI18n.SKResource.Space_List_Refresh_Tips
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()

    private var dismissTimer: Timer?

    private(set) var isAnimating: Bool = false

    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            update(isHighlighted: newValue)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius: CGFloat
        if frame.height > 40 {
            cornerRadius = 8
        } else {
            cornerRadius = frame.height / 2
        }
        layer.cornerRadius = cornerRadius
    }

    private func setupUI() {
        clipsToBounds = true
        backgroundColor = UDColor.primaryContentDefault
        layer.ud.setShadowColor(UDColor.N900)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 5, height: 10)

        addTarget(self, action: #selector(didClickTips), for: .touchUpInside)

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.right.equalToSuperview().inset(20)
            make.top.bottom.equalToSuperview().inset(10)
            make.height.greaterThanOrEqualTo(20)
        }
    }

    @objc
    private func didClickTips() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        isUserInteractionEnabled = false
        isAnimating = true

        addSubview(animationView)
        animationView.alpha = 0
        animationView.snp.makeConstraints { make in
            make.center.equalTo(iconImageView)
            make.size.equalTo(iconImageView)
        }

        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.duration = 1.0
        rotateAnimation.repeatCount = Float.infinity
        rotateAnimation.fillMode = .forwards
        rotateAnimation.isRemovedOnCompletion = false

        animationView.layer.add(rotateAnimation, forKey: "rotate.animation")

        UIView.animate(withDuration: 0.25) {
            self.animationView.alpha = 1
            self.iconImageView.alpha = 0
        }

        clickHandler?()
    }

    private func update(isHighlighted: Bool) {
        let alpha: CGFloat = isHighlighted ? 0.5 : 1
        backgroundColor = UDColor.primaryContentDefault.withAlphaComponent(alpha)
    }

    func set(timeout: TimeInterval, handler: (() -> Void)?) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        let timer = Timer(timeInterval: timeout, repeats: false) { [weak self] _ in
            self?.dismissTimer?.invalidate()
            self?.dismissTimer = nil
            handler?()
        }
        RunLoop.main.add(timer, forMode: .common)
        dismissTimer = timer
    }
}
