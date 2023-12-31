//
//  PopupMenuView.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/17.
//

import UIKit
import Foundation

final class PopupMenuItemView: UIView {

    private let iconImage: UIImageView = UIImageView()
    private let label: UILabel = UILabel()
    private let button: UIButton = UIButton()
    var isEnabled: Bool = true {
        didSet {
            button.isEnabled = isEnabled
            if isEnabled {
                iconImage.tintColor = UIColor.ud.N900
                label.textColor = UIColor.ud.N900
                button.tintColor = UIColor.ud.N900
            } else {
                iconImage.tintColor = UIColor.ud.N400
                label.textColor = UIColor.ud.N400
                button.tintColor = UIColor.ud.N400
            }
        }
    }

    var selectedBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(button)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        button.setBackgroundImage(UIImage.image(with: UIColor.ud.N00), for: .normal)
        button.setBackgroundImage(UIImage.image(with: UIColor.ud.N200), for: .highlighted)
        button.tintColor = UIColor.ud.N900
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        iconImage.tintColor = UIColor.ud.N900
        iconImage.contentMode = .scaleAspectFit
        self.addSubview(iconImage)
        iconImage.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.centerY.equalToSuperview()
        }

        self.addSubview(label)
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        label.textColor = UIColor.ud.N900
        label.snp.makeConstraints { (make) in
            make.left.equalTo(iconImage.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-15)
        }
    }

    func addItemBorder() {
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor.ud.N300
        addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.height.equalTo(2.0 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(icon: UIImage, title: String, accessibilityIdentifier: String? = nil) {
        self.iconImage.image = icon.withRenderingMode(.alwaysTemplate)
        iconImage.tintColor = UIColor.ud.N900
        self.label.text = title
        if let key = accessibilityIdentifier {
            button.accessibilityIdentifier = key
        }
    }

    @objc
    func clickButton() {
        self.selectedBlock?()
    }
}

extension UIImage {
    class func image(with color: UIColor?) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color?.cgColor ?? UIColor.clear.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
