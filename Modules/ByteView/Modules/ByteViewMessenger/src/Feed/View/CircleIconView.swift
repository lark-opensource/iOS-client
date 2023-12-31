//
//  CircleIconView.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/19.
//

import Foundation
import Lottie
import UniverseDesignIcon
import UniverseDesignShadow
import UniverseDesignColor

class CircleIconView: UIView {
    private var size: CGFloat = 20

    private var backgroundView: UIView = UIView()

    private var iconView: UIImageView?
    private var animationView: LOTAnimationView?

    private var icon: UDIconType = .errorFilled
    private var iconColor: UIColor = .ud.primaryOnPrimaryFill
    private var iconColorHighlighted: UIColor = .ud.primaryOnPrimaryFill
    private var backgroundViewColor: UIColor?
    private var backgroundViewColorHighlighted: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundView.clipsToBounds = true

        addSubview(backgroundView)

        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override var isHidden: Bool {
        get {
            super.isHidden
        }
        set {
            super.isHidden = newValue
            if newValue {
                animationView?.stop()
            } else {
                animationView?.play()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
        DispatchQueue.main.async {
            self.backgroundView.layer.cornerRadius = self.bounds.width / 2
        }
    }

    func config(icon: UDIconType,
                iconColor: UIColor,
                iconColorHighlighted: UIColor? = nil,
                backgroundViewColor: UIColor?,
                backgroundViewColorHighlighted: UIColor?) {
        resetIconView()

        self.icon = icon
        self.iconColor = iconColor
        self.iconColorHighlighted = iconColorHighlighted ?? iconColor
        self.backgroundViewColor = backgroundViewColor
        self.backgroundViewColorHighlighted = backgroundViewColorHighlighted

        let iconView = UIImageView()
        backgroundView.addSubview(iconView)
        self.iconView = iconView
    }

    func config(animationPath: String,
                backgroundViewColor: UIColor?,
                backgroundViewColorHighlighted: UIColor?) {
        resetIconView()

        self.backgroundViewColor = backgroundViewColor
        self.backgroundViewColorHighlighted = backgroundViewColorHighlighted

        let animationView = LOTAnimationView(filePath: animationPath)
        animationView.loopAnimation = true
        animationView.autoReverseAnimation = false
        animationView.contentMode = .scaleAspectFit
        backgroundView.addSubview(animationView)
        animationView.play()
        self.animationView = animationView
    }

    func updateLayout() {
        iconView?.snp.remakeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(size)
        }
        animationView?.snp.remakeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(size)
        }
    }

    func resetIconView() {
        iconView?.removeFromSuperview()
        animationView?.removeFromSuperview()
    }

    func setHighlighted(_ isHighlighted: Bool) {
        iconView?.image = UDIcon.getIconByKey(icon, iconColor: isHighlighted ? iconColorHighlighted : iconColor, size: CGSize(width: size, height: size))
        backgroundView.backgroundColor = isHighlighted ? backgroundViewColorHighlighted : backgroundViewColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
