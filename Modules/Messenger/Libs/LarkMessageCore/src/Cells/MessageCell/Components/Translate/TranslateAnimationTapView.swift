//
//  TranslateAnimationTapView.swift
//  LarkMessageCore
//
//  Created by Patrick on 3/11/2022.
//

import Foundation
import UIKit
import UniverseDesignIcon

public final class TranslateAnimationTapView: TappedView {
    static let circleTime: CGFloat = 1
    public var identifier: String = ""
    public private(set) var isAnimationPlaying: Bool = false
    private lazy var outsideIcon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.translateCircleOutlined.ud.withTintColor(.ud.textLinkNormal)
        view.isHidden = true
        return view
    }()

    private lazy var insideIcon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.translateInsideOutlined.ud.withTintColor(.ud.textLinkNormal)
        view.isHidden = true
        return view
    }()

    private lazy var placeHolderIcon: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        view.image = UDIcon.translateOutlined.ud.withTintColor(.ud.textLinkNormal)
        return view
    }()

    public func play(_ completion: (() -> Void)?) {
        outsideIcon.isHidden = false
        insideIcon.isHidden = false
        placeHolderIcon.isHidden = true
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Double.pi * 2
        rotationAnimation.duration = Self.circleTime
        rotationAnimation.repeatCount = .infinity
        outsideIcon.layer.add(rotationAnimation, forKey: nil)
        isAnimationPlaying = true
    }

    public func stop() {
        outsideIcon.isHidden = true
        insideIcon.isHidden = true
        placeHolderIcon.isHidden = false
        outsideIcon.layer.removeAllAnimations()
        isAnimationPlaying = false
    }

    public func show() {
        outsideIcon.isHidden = true
        insideIcon.isHidden = true
        placeHolderIcon.isHidden = false
    }

    public func hide() {
        outsideIcon.isHidden = true
        insideIcon.isHidden = true
        placeHolderIcon.isHidden = true
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(outsideIcon)
        addSubview(insideIcon)
        addSubview(placeHolderIcon)
        outsideIcon.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        insideIcon.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        placeHolderIcon.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
