//
//  ProfileAvatarView.swift
//  LarkProfile
//
//  Created by Hayden Wang on 2021/7/5.
//

import Foundation
import UIKit
import ByteWebImage
import UniverseDesignColor

public final class ProfileAvatarView: UIView {

    public var customView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            addCustomView(customView)
        }
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.bgBodyOverlay
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var borderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    public var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    public var borderWidth: CGFloat = 2.5 {
        didSet { updateBorder() }
    }

    public var borderColor: UIColor? {
        get { borderView.backgroundColor }
        set { borderView.backgroundColor = newValue }
    }

    public var shadowColor: UIColor = .clear {
        didSet { layer.ud.setShadowColor(shadowColor) }
    }

    public var shadowOpacity: Float {
        get { layer.shadowOpacity }
        set { layer.shadowOpacity = newValue }
    }

    public var shadowOffset: CGSize {
        get { layer.shadowOffset }
        set { layer.shadowOffset = newValue }
    }

    public var shadowRadius: CGFloat {
        get { layer.shadowRadius }
        set { layer.shadowRadius = newValue / 2 }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(borderView)
        addSubview(imageView)
        borderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview().inset(borderWidth)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius = min(bounds.height, bounds.width) / 2
        borderView.layer.cornerRadius = cornerRadius
        imageView.layer.cornerRadius = cornerRadius - borderWidth
        layer.masksToBounds = false
        let spread: CGFloat = 0
        let dx = -spread
        let rect = bounds.insetBy(dx: dx, dy: dx)
        layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius + spread).cgPath
    }

    private func updateBorder() {
        imageView.snp.updateConstraints { update in
            update.width.height.equalToSuperview().inset(borderWidth)
        }
        imageView.layer.cornerRadius = bounds.width / 2 - borderWidth
    }

    private func addCustomView(_ view: UIView?) {
        guard let customView = view else { return }
        customView.removeFromSuperview()
        self.imageView.addSubview(customView)
        customView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
