//
//  PopupMenuView.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/17.
//

import Foundation
import LarkInteraction
import FigmaKit

class PopupMenuItemView: UIView {

    private let iconImage: UIImageView = UIImageView()
    let label: UILabel = UILabel()
    private let button: UIButton = UIButton()
    private var hideIconImage: Bool = false
    private var titleColor: UIColor? = nil
    var iconColor = UIColor.ud.iconN2
    var isEnabled: Bool = true {
        didSet {
            button.isEnabled = isEnabled
            if isEnabled {
                iconImage.tintColor = iconColor
                label.textColor = self.titleColor ?? UIColor.ud.textTitle
                button.tintColor = UIColor.ud.textTitle
            } else {
                iconImage.tintColor = UIColor.ud.iconDisabled
                label.textColor = UIColor.ud.textDisabled
                button.tintColor = UIColor.ud.textDisabled
            }
        }
    }
    var placeHolderTitle: Bool = false {
        didSet {
            if placeHolderTitle {
                button.isEnabled = false
                label.textColor = UIColor.ud.textPlaceholder
                button.tintColor = UIColor.ud.textPlaceholder
            }
        }
    }

    var selectedBlock: (() -> Void)?

     init(frame: CGRect, hideIconImage: Bool) {
        super.init(frame: frame)
        self.addSubview(button)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
//        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgBody), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.fillHover), for: .highlighted)
        button.layer.cornerRadius = 6.0
        button.clipsToBounds = true
        button.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(4)
            make.bottom.right.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
        }
        self.hideIconImage = hideIconImage
        if !hideIconImage {
            iconImage.tintColor = UIColor.ud.iconN1
            iconImage.contentMode = .scaleAspectFit
            self.addSubview(iconImage)
            iconImage.snp.makeConstraints { (make) in
                make.left.equalTo(16)
                make.size.equalTo(CGSize(width: 20, height: 20))
                make.centerY.equalToSuperview()
            }
        }

        self.addSubview(label)
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        label.textColor = UIColor.ud.textTitle
        if !Display.pad {
            label.numberOfLines = 0
        }
        if hideIconImage {
            label.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualToSuperview().offset(-15)
            }
        } else {
            label.snp.makeConstraints { (make) in
                make.left.equalTo(iconImage.snp.right).offset(10)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualToSuperview().offset(-15)
            }
        }
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                effect: .hover()
                )
            )
            self.addLKInteraction(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(icon: UIImage, title: String, accessibilityIdentifier: String? = nil, titleColor: UIColor? = nil) {
        self.iconImage.image = icon.withRenderingMode(.alwaysTemplate)
        iconImage.tintColor = UIColor.ud.iconN1
        self.label.text = title
        if let key = accessibilityIdentifier {
            button.accessibilityIdentifier = key
        }
        if let titleColor = titleColor {
            self.label.textColor = titleColor
            self.titleColor = titleColor
        }
    }

    @objc
    func clickButton() {
        self.selectedBlock?()
    }
}
