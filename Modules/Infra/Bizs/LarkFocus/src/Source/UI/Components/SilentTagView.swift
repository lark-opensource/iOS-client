//
//  SilentTagView.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/8.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class SilentTagView: UIView {

    var isSelected: Bool = false {
        didSet {
            iconWrapper.backgroundColor = isSelected
                ? UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.9)
                : UIColor.ud.red.withAlphaComponent(0.2)
            textLabel.textColor = isSelected
                ? UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
                : UIColor.ud.textPlaceholder
        }
    }

    private lazy var iconWrapper: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.backgroundColor = UIColor.ud.red.withAlphaComponent(0.2)
        return view
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.alertsOffFilled.ud.withTintColor(UIColor.ud.R600)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkFocus.Lark_Profile_NotificationMuted
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconWrapper)
        addSubview(textLabel)
        iconWrapper.addSubview(iconView)
        iconWrapper.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.height.equalTo(14)
            make.top.bottom.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(10)
        }
        textLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconWrapper.snp.trailing).offset(4)
            make.trailing.equalToSuperview()
        }
        textLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        iconWrapper.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
