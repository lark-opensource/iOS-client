//
//  ProfileCTAView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/5.
//

import Foundation
import UniverseDesignColor
import UniverseDesignToast
import UIKit
import LarkUIKit

public struct ProfileCTAItem {
    public var title: String
    public var icon: UIImage
    public var enable: Bool
    public var denyDescribe: String
    public var tapCallback: (() -> Void)?
    public var longPressCallback: (() -> Void)?

    public init(title: String,
                icon: UIImage,
                enable: Bool,
                denyDescribe: String,
                tapCallback: (() -> Void)?,
                longPressCallback: (() -> Void)?) {
        self.title = title
        self.icon = icon
        self.enable = enable
        self.denyDescribe = denyDescribe
        self.tapCallback = tapCallback
        self.longPressCallback = longPressCallback
    }
}

public final class ProfileCTAControl: UIControl {
    public enum Style {
        case horizontal
        case vertical
    }

    public override var isHighlighted: Bool {
        didSet {
            self.backgroundColor =
                (isHighlighted && item.enable)
                ? Cons.buttonHighlightBgColor
                : Cons.buttonBgColor
        }
    }

    private var item: ProfileCTAItem

    private var wrapperView = UIView()

    public var style: Style {
        didSet {
            self.layoutView()
        }
    }

    private var iconView: UIImageView = UIImageView()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.textColor = Cons.buttonTintColor
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 11)
        return titleLabel
    }()

    public init(item: ProfileCTAItem, style: Style) {
        self.item = item
        self.style = style
        super.init(frame: .zero)

        self.backgroundColor = Cons.buttonBgColor
        self.layer.cornerRadius = 10

        self.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        let longPressGes = UILongPressGestureRecognizer(target: self,
                                                        action: #selector(longPressHandle(ges:)))
        self.addGestureRecognizer(longPressGes)

        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(iconView)

        self.addSubview(wrapperView)
        wrapperView.isUserInteractionEnabled = false

        self.layoutView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateItem(_ item: ProfileCTAItem, style: Style) {
        self.iconView.image = item.icon.ud.withTintColor(Cons.buttonTintColor)
        self.titleLabel.text = item.title
        self.style = style
        self.item = item
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.iconView.image = item.icon.ud.withTintColor(Cons.buttonTintColor)
    }

    public func placeIconInTheMiddle() {
        self.iconView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
            make.top.equalToSuperview()
        }
    }

    public func hideTextLabel() {
        self.titleLabel.isHidden = true
    }

    private func layoutView() {
        self.iconView.image = item.icon.ud.withTintColor(Cons.buttonTintColor)
        self.titleLabel.text = item.title

        switch style {
        case .horizontal:
            self.titleLabel.font = UIFont.systemFont(ofSize: 17)
            self.snp.remakeConstraints { make in
                make.height.equalTo(48)
            }
            self.wrapperView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
            }
            self.iconView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.width.height.equalTo(22)
                make.top.bottom.equalToSuperview()
                make.leading.equalToSuperview()
            }
            self.titleLabel.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(iconView.snp.trailing).offset(5)
                make.trailing.equalToSuperview()
            }
        case .vertical:
            self.titleLabel.font = UIFont.systemFont(ofSize: 12)

            self.snp.remakeConstraints { make in
                make.height.equalTo(48)
            }
            self.wrapperView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
            }
            self.iconView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.height.equalTo(22)
                make.top.equalToSuperview()
            }
            self.titleLabel.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(iconView.snp.bottom).offset(1)
                make.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview()
                make.width.lessThanOrEqualTo(self)
            }
        }
    }

    @objc
    private func didTap() {
        if self.item.enable {
            self.item.tapCallback?()
        } else if !item.denyDescribe.isEmpty, let window = self.window {
            UDToast.showTips(with: item.denyDescribe, on: window)
        }
    }

    @objc
    private func longPressHandle(ges: UILongPressGestureRecognizer) {
        if ges.state == .began {
            self.item.longPressCallback?()
        }
    }
}

extension ProfileCTAControl {

    enum Cons {
        static var buttonBgColor: UIColor {
            Display.pad ? UIColor.ud.bgFloatOverlay : UIColor.ud.bgBodyOverlay
        }
        static var buttonHighlightBgColor: UIColor {
            UIColor.ud.bgFiller
        }
        static var buttonTintColor: UIColor {
            UIColor.ud.textTitle & UIColor.ud.N650
        }
    }
}
